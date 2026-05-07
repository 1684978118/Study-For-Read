package com.studyforread.server.reading;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class UpsertBookMetadataEndpointTest {

    private static final String BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void authenticatedUserCanCreateBookMetadataWithoutOriginalText() throws Exception {
        var accessToken = registerAndGetAccessToken("metadata-create@example.com");

        var response = putBook(BOOK_FINGERPRINT, accessToken, """
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
        var responseBody = response.body();
        var responseJson = objectMapper.readTree(responseBody);
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/id").asText()).isNotBlank();
        assertThat(responseJson.at("/data/bookFingerprint").asText()).isEqualTo(BOOK_FINGERPRINT);
        assertThat(responseJson.at("/data/title").asText()).isEqualTo("Kokoro");
        assertThat(responseJson.at("/data/author").asText()).isEqualTo("Natsume Soseki");
        assertThat(responseJson.at("/data/fileType").asText()).isEqualTo("txt");
        assertThat(responseJson.at("/data/sourceLang").asText()).isEqualTo("ja");
        assertThat(responseJson.at("/data/targetLang").asText()).isEqualTo("zh-CN");
        assertThat(responseJson.at("/data/chapterCount").asInt()).isEqualTo(42);
        assertThat(responseJson.at("/data/currentChapterIndex").asInt()).isZero();
        assertThat(responseJson.at("/data/currentParagraphIndex").asInt()).isZero();
        assertThat(responseJson.at("/data/currentCharOffset").asInt()).isZero();
        assertThat(responseJson.at("/data/lastReadAt").isNull()).isTrue();
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertNoOriginalTextFields(responseBody);
    }

    @Test
    void repeatedPutUpdatesExistingBookInsteadOfCreatingDuplicate() throws Exception {
        var accessToken = registerAndGetAccessToken("metadata-update@example.com");
        putBook(BOOK_FINGERPRINT, accessToken, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42
                }
                """);

        var response = putBook(BOOK_FINGERPRINT, accessToken, """
                {
                  "title": "Kokoro Revised",
                  "author": "Soseki",
                  "fileType": "epub",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 43
                }
                """);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/title").asText()).isEqualTo("Kokoro Revised");
        assertThat(responseJson.at("/data/author").asText()).isEqualTo("Soseki");
        assertThat(responseJson.at("/data/fileType").asText()).isEqualTo("epub");
        assertThat(responseJson.at("/data/chapterCount").asInt()).isEqualTo(43);

        var rowCount = jdbcTemplate.queryForObject(
                """
                        select count(*)
                        from user_books book
                        join users user_account on user_account.id = book.user_id
                        where user_account.email = ? and book.book_fingerprint = ?
                        """,
                Integer.class,
                "metadata-update@example.com",
                BOOK_FINGERPRINT);
        assertThat(rowCount).isEqualTo(1);
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = putBookWithoutToken(BOOK_FINGERPRINT, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42
                }
                """);

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void invalidBookFingerprintReturnsBookMetadataInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("invalid-fingerprint@example.com");

        var shortResponse = putBook("abc123", accessToken, validBookJson());
        var nonHexResponse = putBook(
                "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
                accessToken,
                validBookJson());

        assertBookMetadataInvalid(shortResponse);
        assertBookMetadataInvalid(nonHexResponse);
    }

    @Test
    void chapterCountBelowOneReturnsBookMetadataInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("invalid-chapter-count@example.com");

        var response = putBook(BOOK_FINGERPRINT, accessToken, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 0
                }
                """);

        assertBookMetadataInvalid(response);
    }

    @Test
    void unsupportedFileTypeReturnsBookMetadataInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("invalid-file-type@example.com");

        var response = putBook(BOOK_FINGERPRINT, accessToken, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "pdf",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42
                }
                """);

        assertBookMetadataInvalid(response);
    }

    @Test
    void forbiddenOriginalTextFieldsReturnBookMetadataInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("forbidden-fields@example.com");

        for (var fieldName : new String[] {"content", "chapterContent", "originalFile", "filePath"}) {
            var response = putBook(BOOK_FINGERPRINT, accessToken, """
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

            assertBookMetadataInvalid(response);
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

    private String validBookJson() {
        return """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42
                }
                """;
    }

    private void assertBookMetadataInvalid(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("BOOK_METADATA_INVALID");
    }

    private void assertNoOriginalTextFields(String responseBody) {
        assertThat(responseBody).doesNotContain("content");
        assertThat(responseBody).doesNotContain("chapterContent");
        assertThat(responseBody).doesNotContain("originalFile");
        assertThat(responseBody).doesNotContain("filePath");
    }

    private HttpResponse<String> putBook(String bookFingerprint, String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books/%s".formatted(port, bookFingerprint)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> putBookWithoutToken(String bookFingerprint, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books/%s".formatted(port, bookFingerprint)))
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json))
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
}
