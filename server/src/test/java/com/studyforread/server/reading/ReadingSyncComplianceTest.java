package com.studyforread.server.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import jakarta.persistence.EntityManager;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.DatabaseMetaData;
import java.time.OffsetDateTime;
import java.util.Set;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class ReadingSyncComplianceTest {

    private static final String BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private static final Set<String> FORBIDDEN_RESPONSE_FIELDS = Set.of(
            "content",
            "chapterContent",
            "originalFile",
            "filePath");
    private static final Set<String> FORBIDDEN_COLUMNS = Set.of(
            "content",
            "chapter_content",
            "original_file",
            "file_path");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private DataSource dataSource;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Value("${local.server.port}")
    private int port;

    @Test
    void userBooksTableDoesNotContainOriginalContentColumns() throws Exception {
        try (var connection = dataSource.getConnection()) {
            var columns = connection.getMetaData().getColumns(null, null, "user_books", null);

            while (columns.next()) {
                assertThat(columns.getString("COLUMN_NAME")).isNotIn(FORBIDDEN_COLUMNS);
            }
        }
    }

    @Test
    void bookFingerprintColumnIsChar64() throws Exception {
        try (var connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            var columns = metaData.getColumns(null, null, "user_books", "book_fingerprint");

            assertThat(columns.next()).isTrue();
            assertThat(columns.getString("TYPE_NAME").toLowerCase()).contains("char");
            assertThat(columns.getInt("COLUMN_SIZE")).isEqualTo(64);
        }
    }

    @Test
    @Transactional
    void fileTypeCheckConstraintRejectsUnsupportedValues() {
        var user = saveUser("compliance-file-type@example.com");

        assertThatThrownBy(() -> insertUserBookNative(user, "pdf", 1, 0, 0, 0))
                .isInstanceOf(Exception.class);
    }

    @Test
    @Transactional
    void progressCheckConstraintsRejectNegativeValues() {
        var user = saveUser("compliance-progress@example.com");

        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 1, -1, 0, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 1, 0, -1, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 1, 0, 0, -1))
                .isInstanceOf(Exception.class);
    }

    @Test
    void metadataEndpointRejectsContentField() throws Exception {
        assertForbiddenMetadataFieldRejected("content");
    }

    @Test
    void metadataEndpointRejectsChapterContentField() throws Exception {
        assertForbiddenMetadataFieldRejected("chapterContent");
    }

    @Test
    void metadataEndpointRejectsOriginalFileField() throws Exception {
        assertForbiddenMetadataFieldRejected("originalFile");
    }

    @Test
    void metadataEndpointRejectsFilePathField() throws Exception {
        assertForbiddenMetadataFieldRejected("filePath");
    }

    @Test
    void listBooksResponseDoesNotContainOriginalContentFields() throws Exception {
        var accessToken = registerAndGetAccessToken("compliance-list@example.com");
        upsertBook(accessToken);

        var response = getBooks(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        assertNoForbiddenResponseFields(response.body());
    }

    @Test
    void updateProgressResponseDoesNotContainOriginalContentFields() throws Exception {
        var accessToken = registerAndGetAccessToken("compliance-progress-response@example.com");
        upsertBook(accessToken);

        var response = patchProgress(accessToken, """
                {
                  "currentChapterIndex": 3,
                  "currentParagraphIndex": 12,
                  "currentCharOffset": 48,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """);

        assertThat(response.statusCode()).isEqualTo(200);
        assertNoForbiddenResponseFields(response.body());
    }

    private void assertForbiddenMetadataFieldRejected(String fieldName) throws Exception {
        var accessToken = registerAndGetAccessToken("compliance-%s@example.com".formatted(fieldName.toLowerCase()));

        var response = putBook(accessToken, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42,
                  "%s": "must-not-be-accepted"
                }
                """.formatted(fieldName));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("BOOK_METADATA_INVALID");
    }

    private void assertNoForbiddenResponseFields(String responseBody) {
        for (var fieldName : FORBIDDEN_RESPONSE_FIELDS) {
            assertThat(responseBody).doesNotContain(fieldName);
        }
    }

    private String registerAndGetAccessToken(String email) throws Exception {
        var response = postJson("/api/v1/auth/register", """
                {
                  "email": "%s",
                  "password": "change-this-password",
                  "displayName": "Reader",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """.formatted(email));

        assertThat(response.statusCode()).isEqualTo(201);
        return objectMapper.readTree(response.body()).at("/data/accessToken").asText();
    }

    private void upsertBook(String accessToken) throws Exception {
        var response = putBook(accessToken, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42
                }
                """);

        assertThat(response.statusCode()).isEqualTo(200);
    }

    private UserAccount saveUser(String email) {
        return userAccountRepository.saveAndFlush(new UserAccount(
                email,
                "hash-1",
                "Reader",
                "ja",
                "zh-CN",
                UserStatus.ACTIVE));
    }

    private void insertUserBookNative(
            UserAccount user,
            String fileType,
            int chapterCount,
            int currentChapterIndex,
            int currentParagraphIndex,
            int currentCharOffset) {
        entityManager.createNativeQuery("""
                        insert into user_books (
                            id,
                            user_id,
                            book_fingerprint,
                            title,
                            author,
                            file_type,
                            source_lang,
                            target_lang,
                            chapter_count,
                            current_chapter_index,
                            current_paragraph_index,
                            current_char_offset,
                            last_read_at,
                            created_at,
                            updated_at
                        ) values (
                            random_uuid(),
                            :userId,
                            :bookFingerprint,
                            'Kokoro',
                            'Natsume Soseki',
                            :fileType,
                            'ja',
                            'zh-CN',
                            :chapterCount,
                            :currentChapterIndex,
                            :currentParagraphIndex,
                            :currentCharOffset,
                            current_timestamp,
                            current_timestamp,
                            current_timestamp
                        )
                        """)
                .setParameter("userId", user.getId())
                .setParameter("bookFingerprint", BOOK_FINGERPRINT)
                .setParameter("fileType", fileType)
                .setParameter("chapterCount", chapterCount)
                .setParameter("currentChapterIndex", currentChapterIndex)
                .setParameter("currentParagraphIndex", currentParagraphIndex)
                .setParameter("currentCharOffset", currentCharOffset)
                .executeUpdate();
        entityManager.flush();
    }

    private HttpResponse<String> putBook(String accessToken, String json) throws Exception {
        return sendJson("PUT", "/api/v1/reading/books/%s".formatted(BOOK_FINGERPRINT), accessToken, json);
    }

    private HttpResponse<String> patchProgress(String accessToken, String json) throws Exception {
        return sendJson("PATCH", "/api/v1/reading/books/%s/progress".formatted(BOOK_FINGERPRINT), accessToken, json);
    }

    private HttpResponse<String> getBooks(String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postJson(String path, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> sendJson(String method, String path, String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .method(method, HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }
}
