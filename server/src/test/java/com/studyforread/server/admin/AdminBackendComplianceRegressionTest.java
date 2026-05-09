package com.studyforread.server.admin;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyforread.server.reading.BookFileType;
import com.studyforread.server.reading.UserBook;
import com.studyforread.server.reading.UserBookRepository;
import com.studyforread.server.stats.StudyDailyStat;
import com.studyforread.server.stats.StudyDailyStatRepository;
import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import com.studyforread.server.vocabulary.Lexeme;
import com.studyforread.server.vocabulary.LexemeEntryType;
import com.studyforread.server.vocabulary.LexemeRepository;
import com.studyforread.server.vocabulary.LexemeStatus;
import com.studyforread.server.vocabulary.ReviewStatus;
import com.studyforread.server.vocabulary.UserWordCard;
import com.studyforread.server.vocabulary.UserWordCardRepository;
import com.studyforread.server.vocabulary.WordCardType;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class AdminBackendComplianceRegressionTest {

    private static final String BOOK_CONTENT_SENTINEL = "BOOK_CONTENT_DO_NOT_EXPOSE";
    private static final String CHAPTER_CONTENT_SENTINEL = "CHAPTER_CONTENT_DO_NOT_EXPOSE";
    private static final String PRIVATE_CONTEXT_SENTINEL = "PRIVATE_SENTENCE_CONTEXT_DO_NOT_EXPOSE";
    private static final String RAW_LOOKUP_SENTINEL = "RAW_LOOKUP_TEXT_DO_NOT_EXPOSE";
    private static final String RAW_PARAGRAPH_SENTINEL = "RAW_PARAGRAPH_TEXT_DO_NOT_EXPOSE";
    private static final String TRANSLATED_TEXT_SENTINEL = "TRANSLATED_TEXT_DO_NOT_EXPOSE";
    private static final String PASSWORD_HASH_SENTINEL = "PASSWORD_HASH_DO_NOT_EXPOSE";
    private static final String TOKEN_HASH_SENTINEL = "TOKEN_HASH_DO_NOT_EXPOSE";
    private static final String FINGERPRINT = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private static final Set<String> FORBIDDEN_ADMIN_FIELD_NAMES = Set.of(
            "content",
            "chapterContent",
            "chapter_content",
            "originalFile",
            "original_file",
            "filePath",
            "file_path",
            "sourceText",
            "source_text",
            "rawText",
            "raw_text",
            "translatedText",
            "translated_text",
            "paragraphText",
            "paragraph_text",
            "passwordHash",
            "password_hash",
            "tokenHash",
            "token_hash");

    private static final Set<String> PUBLIC_LEXEME_FIELDS = Set.of(
            "id",
            "surface",
            "normalizedSurface",
            "reading",
            "sourceLang",
            "targetLang",
            "entryType",
            "partOfSpeech",
            "definition",
            "shortDefinition",
            "example",
            "status",
            "createdAt",
            "updatedAt");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private AdminUserRepository adminUserRepository;

    @Autowired
    private AdminAuditLogRepository adminAuditLogRepository;

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private UserBookRepository userBookRepository;

    @Autowired
    private StudyDailyStatRepository studyDailyStatRepository;

    @Autowired
    private LexemeRepository lexemeRepository;

    @Autowired
    private UserWordCardRepository userWordCardRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${local.server.port}")
    private int port;

    @Test
    void userAccessTokenCannotCallProtectedAdminEndpoints() throws Exception {
        var lexeme = saveLexeme("Compliance", "compliance", "Safe admin example");
        var userToken = registerUserAndReturnAccessToken();

        assertAdminRequired(getWithBearer("/api/v1/admin/auth/me", userToken));
        assertAdminRequired(getWithBearer("/api/v1/admin/users", userToken));
        assertAdminRequired(getWithBearer("/api/v1/admin/stats/summary", userToken));
        assertAdminRequired(getWithBearer("/api/v1/admin/audit-logs", userToken));
        assertAdminRequired(getWithBearer("/api/v1/admin/lexemes", userToken));
        assertAdminRequired(postJsonWithBearer("/api/v1/admin/lexemes", validLexemeJson("Blocked"), userToken));
        assertAdminRequired(patchJsonWithBearer(
                "/api/v1/admin/lexemes/%s".formatted(lexeme.getId()),
                validLexemeJson("Blocked Update"),
                userToken));
        assertAdminRequired(postJsonWithBearer(
                "/api/v1/admin/lexemes/%s/reject".formatted(lexeme.getId()),
                "{\"reason\":\"blocked\"}",
                userToken));
    }

    @Test
    void adminUserListStatsAndAuditResponsesDoNotExposeContentOrSecrets() throws Exception {
        var user = saveUser(
                "compliance-reader@example.com",
                "Compliance Reader",
                PASSWORD_HASH_SENTINEL,
                UserStatus.ACTIVE);
        userBookRepository.saveAndFlush(new UserBook(
                user,
                FINGERPRINT,
                "Metadata Only Title",
                "Metadata Only Author",
                BookFileType.TXT,
                "ja",
                "zh-CN",
                3,
                0,
                0,
                0,
                OffsetDateTime.now()));
        studyDailyStatRepository.saveAndFlush(new StudyDailyStat(
                user,
                LocalDate.of(2026, 5, 9),
                15,
                2,
                1,
                1,
                1));
        savePrivateSentenceCard(user);
        var admin = saveAdmin("compliance-admin", "change-this-password", AdminRole.ADMIN, AdminStatus.ACTIVE);
        adminAuditLogRepository.saveAndFlush(new AdminAuditLog(
                admin,
                "compliance.probe",
                "user",
                user.getId(),
                """
                        {
                          "passwordHash": "%s",
                          "tokenHash": "%s",
                          "content": "%s",
                          "chapterContent": "%s",
                          "rawText": "%s",
                          "paragraphText": "%s",
                          "translatedText": "%s",
                          "privateContext": "%s"
                        }
                        """.formatted(
                        PASSWORD_HASH_SENTINEL,
                        TOKEN_HASH_SENTINEL,
                        BOOK_CONTENT_SENTINEL,
                        CHAPTER_CONTENT_SENTINEL,
                        RAW_LOOKUP_SENTINEL,
                        RAW_PARAGRAPH_SENTINEL,
                        TRANSLATED_TEXT_SENTINEL,
                        PRIVATE_CONTEXT_SENTINEL),
                "127.0.0.1"));
        var adminToken = loginAdmin("compliance-admin", "change-this-password");

        var users = getWithBearer("/api/v1/admin/users?page=0&size=10", adminToken);
        var stats = getWithBearer("/api/v1/admin/stats/summary", adminToken);
        var auditLogs = getWithBearer("/api/v1/admin/audit-logs?page=0&size=10", adminToken);

        assertThat(users.statusCode()).isEqualTo(200);
        assertThat(stats.statusCode()).isEqualTo(200);
        assertThat(auditLogs.statusCode()).isEqualTo(200);

        assertAdminResponseIsSafe(users.body());
        assertAdminResponseIsSafe(stats.body());
        assertAdminResponseIsSafe(auditLogs.body());
        assertThat(objectMapper.readTree(auditLogs.body()).at("/data/items/0/details/redacted").asBoolean()).isTrue();

        var statsData = objectMapper.readTree(stats.body()).at("/data");
        assertThat(fieldNames(statsData)).containsExactlyInAnyOrder(
                "userCount",
                "activeUserCount",
                "disabledUserCount",
                "bookMetadataCount",
                "lexemeCount",
                "wordCardCount",
                "readingMinutes",
                "lookupCount",
                "paragraphTranslationCount",
                "cardsCreated",
                "cardsReviewed");
    }

    @Test
    void adminLexemeResponsesContainOnlyPublicLexemeFields() throws Exception {
        saveLexeme("Kokoro", "kokoro", "Admin provided public example.");
        var adminToken = adminToken();

        var list = getWithBearer("/api/v1/admin/lexemes?page=0&size=10", adminToken);
        var create = postJsonWithBearer("/api/v1/admin/lexemes", """
                {
                  "surface": "  New Public Term  ",
                  "reading": "new public term",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "partOfSpeech": "noun",
                  "definition": "public definition",
                  "shortDefinition": "public",
                  "example": "License-safe admin example.",
                  "status": "active"
                }
                """, adminToken);

        assertThat(list.statusCode()).isEqualTo(200);
        assertThat(create.statusCode()).isEqualTo(201);
        assertAdminResponseIsSafe(list.body());
        assertAdminResponseIsSafe(create.body());

        var listItem = objectMapper.readTree(list.body()).at("/data/items/0");
        var created = objectMapper.readTree(create.body()).at("/data");
        assertThat(fieldNames(listItem)).containsOnlyElementsOf(PUBLIC_LEXEME_FIELDS);
        assertThat(fieldNames(created)).containsOnlyElementsOf(PUBLIC_LEXEME_FIELDS);
    }

    @Test
    void adminLexemeExampleCannotBeCreatedFromFlaggedUserPrivateSource() throws Exception {
        var adminToken = adminToken();

        var response = postJsonWithBearer("/api/v1/admin/lexemes", """
                {
                  "surface": "Private Example Leak",
                  "reading": "private example leak",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "partOfSpeech": "noun",
                  "definition": "public definition",
                  "shortDefinition": "public",
                  "example": "%s",
                  "exampleSource": "user_private",
                  "status": "active"
                }
                """.formatted(PRIVATE_CONTEXT_SENTINEL), adminToken);

        assertThat(response.statusCode()).isEqualTo(400);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/success").asBoolean()).isFalse();
        assertThat(json.at("/error/code").asText()).isEqualTo("ADMIN_LEXEME_INVALID");
        assertAdminResponseIsSafe(response.body());
        assertThat(lexemeRepository.findBySourceLangAndTargetLangAndNormalizedSurfaceAndEntryType(
                "ja",
                "zh-CN",
                "private example leak",
                LexemeEntryType.WORD.databaseValue())).isEmpty();
    }

    private AdminUser saveAdmin(String username, String password, AdminRole role, AdminStatus status) {
        return adminUserRepository.saveAndFlush(new AdminUser(
                username,
                passwordEncoder.encode(password),
                role,
                status));
    }

    private String adminToken() throws Exception {
        saveAdmin("admin", "change-this-password", AdminRole.ADMIN, AdminStatus.ACTIVE);
        return loginAdmin("admin", "change-this-password");
    }

    private String loginAdmin(String username, String password) throws Exception {
        var login = postJson("/api/v1/admin/auth/login", """
                {
                  "username": "%s",
                  "password": "%s"
                }
                """.formatted(username, password));
        assertThat(login.statusCode()).isEqualTo(200);
        return objectMapper.readTree(login.body()).at("/data/accessToken").asText();
    }

    private String registerUserAndReturnAccessToken() throws Exception {
        var response = postJson("/api/v1/auth/register", """
                {
                  "email": "reader-token@example.com",
                  "password": "change-this-password",
                  "displayName": "Reader",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """);
        assertThat(response.statusCode()).isEqualTo(201);
        return objectMapper.readTree(response.body()).at("/data/accessToken").asText();
    }

    private UserAccount saveUser(String email, String displayName, String passwordHash, UserStatus status) {
        return userAccountRepository.saveAndFlush(new UserAccount(
                email,
                passwordHash,
                displayName,
                "ja",
                "zh-CN",
                status));
    }

    private void savePrivateSentenceCard(UserAccount user) {
        userWordCardRepository.saveAndFlush(new UserWordCard(
                user,
                null,
                WordCardType.PRIVATE_SENTENCE,
                RAW_PARAGRAPH_SENTINEL,
                TRANSLATED_TEXT_SENTINEL,
                PRIVATE_CONTEXT_SENTINEL,
                FINGERPRINT,
                "Metadata Only Title",
                ReviewStatus.NEW,
                0,
                null,
                null));
    }

    private Lexeme saveLexeme(String surface, String normalizedSurface, String example) {
        return lexemeRepository.saveAndFlush(new Lexeme(
                surface,
                normalizedSurface,
                "reading",
                "ja",
                "zh-CN",
                LexemeEntryType.WORD,
                "noun",
                "public definition",
                "public",
                example,
                LexemeStatus.ACTIVE));
    }

    private String validLexemeJson(String surface) {
        return """
                {
                  "surface": "%s",
                  "reading": "reading",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "definition": "definition",
                  "status": "active"
                }
                """.formatted(surface);
    }

    private void assertAdminRequired(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("ADMIN_REQUIRED");
    }

    private void assertAdminResponseIsSafe(String responseBody) throws Exception {
        assertThat(responseBody)
                .doesNotContain(BOOK_CONTENT_SENTINEL)
                .doesNotContain(CHAPTER_CONTENT_SENTINEL)
                .doesNotContain(PRIVATE_CONTEXT_SENTINEL)
                .doesNotContain(RAW_LOOKUP_SENTINEL)
                .doesNotContain(RAW_PARAGRAPH_SENTINEL)
                .doesNotContain(TRANSLATED_TEXT_SENTINEL)
                .doesNotContain(PASSWORD_HASH_SENTINEL)
                .doesNotContain(TOKEN_HASH_SENTINEL);
        assertNodeExcludesForbiddenKeys(objectMapper.readTree(responseBody));
    }

    private void assertNodeExcludesForbiddenKeys(JsonNode node) {
        if (node.isObject()) {
            node.fieldNames().forEachRemaining(fieldName -> {
                assertThat(fieldName).isNotIn(FORBIDDEN_ADMIN_FIELD_NAMES);
                assertNodeExcludesForbiddenKeys(node.get(fieldName));
            });
        } else if (node.isArray()) {
            node.forEach(this::assertNodeExcludesForbiddenKeys);
        }
    }

    private Set<String> fieldNames(JsonNode node) {
        var names = new java.util.LinkedHashSet<String>();
        node.fieldNames().forEachRemaining(names::add);
        return names;
    }

    private HttpResponse<String> postJson(String path, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postJsonWithBearer(String path, String json, String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> patchJsonWithBearer(String path, String json, String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .method("PATCH", HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> getWithBearer(String path, String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }
}
