package com.studyforread.server.admin;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class AdminLexemeEndpointTest {

    private static final String PRIVATE_CONTEXT_SENTINEL = "PRIVATE_SENTENCE_CONTEXT_DO_NOT_EXPOSE";
    private static final String RAW_CONTENT_SENTINEL = "RAW_BOOK_CONTENT_DO_NOT_EXPOSE";
    private static final String TRANSLATED_TEXT_SENTINEL = "TRANSLATED_TEXT_DO_NOT_EXPOSE";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private AdminUserRepository adminUserRepository;

    @Autowired
    private AdminAuditLogRepository adminAuditLogRepository;

    @Autowired
    private LexemeRepository lexemeRepository;

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private UserWordCardRepository userWordCardRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${local.server.port}")
    private int port;

    @Test
    void adminCanListLexemesWithPaginationAndFiltersWithoutPrivateContent() throws Exception {
        saveLexeme("Kokoro", "kokoro", "ja", "zh-CN", LexemeEntryType.WORD, LexemeStatus.ACTIVE);
        saveLexeme("Kokoro phrase", "kokoro phrase", "ja", "zh-CN", LexemeEntryType.PHRASE, LexemeStatus.CANDIDATE);
        saveLexeme("Other", "other", "en", "zh-CN", LexemeEntryType.WORD, LexemeStatus.REJECTED);
        savePrivateSentenceCard();
        var adminToken = adminToken();

        var response = getWithBearer(
                "/api/v1/admin/lexemes?page=0&size=10&q=kokoro&sourceLang=ja&targetLang=zh-CN"
                        + "&entryType=word&status=active",
                adminToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/success").asBoolean()).isTrue();
        assertThat(json.at("/data/items")).hasSize(1);
        assertThat(json.at("/data/items/0/surface").asText()).isEqualTo("Kokoro");
        assertThat(json.at("/data/items/0/normalizedSurface").asText()).isEqualTo("kokoro");
        assertThat(json.at("/data/items/0/sourceLang").asText()).isEqualTo("ja");
        assertThat(json.at("/data/items/0/targetLang").asText()).isEqualTo("zh-CN");
        assertThat(json.at("/data/items/0/entryType").asText()).isEqualTo("word");
        assertThat(json.at("/data/items/0/status").asText()).isEqualTo("active");
        assertThat(json.at("/data/page").asInt()).isZero();
        assertThat(json.at("/data/size").asInt()).isEqualTo(10);
        assertThat(json.at("/data/total").asInt()).isEqualTo(1);
        assertResponseExcludesForbiddenContent(response.body());
    }

    @Test
    void createLexemeNormalizesSurfaceAndWritesRedactedAuditLog() throws Exception {
        var adminToken = adminToken();

        var response = postJsonWithBearer("/api/v1/admin/lexemes", """
                {
                  "surface": "  KOKORO  ",
                  "reading": "kokoro",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "partOfSpeech": "noun",
                  "definition": "heart; mind",
                  "shortDefinition": "heart",
                  "example": "Admin provided example.",
                  "status": "active"
                }
                """, adminToken);

        assertThat(response.statusCode()).isEqualTo(201);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/success").asBoolean()).isTrue();
        assertThat(json.at("/data/surface").asText()).isEqualTo("KOKORO");
        assertThat(json.at("/data/normalizedSurface").asText()).isEqualTo("kokoro");
        assertThat(json.at("/data/definition").asText()).isEqualTo("heart; mind");
        assertResponseExcludesForbiddenContent(response.body());

        var lexemeId = UUID.fromString(json.at("/data/id").asText());
        var saved = lexemeRepository.findById(lexemeId).orElseThrow();
        assertThat(saved.getNormalizedSurface()).isEqualTo("kokoro");
        assertThat(saved.getCreatedByAdminId()).isNotNull();

        var auditLogs = adminAuditLogRepository.findByAdminUserIdOrderByCreatedAtDesc(saved.getCreatedByAdminId());
        assertThat(auditLogs).hasSize(1);
        assertThat(auditLogs.getFirst().getAction()).isEqualTo("lexeme.create");
        assertThat(auditLogs.getFirst().getTargetType()).isEqualTo("lexeme");
        assertThat(auditLogs.getFirst().getTargetId()).isEqualTo(lexemeId);
        assertAuditDetailsAreSafe(auditLogs.getFirst().getDetailsJson());
    }

    @Test
    void duplicateLexemeReturnsAdminLexemeDuplicate() throws Exception {
        saveLexeme("Kokoro", "kokoro", "ja", "zh-CN", LexemeEntryType.WORD, LexemeStatus.ACTIVE);
        var adminToken = adminToken();

        var response = postJsonWithBearer("/api/v1/admin/lexemes", """
                {
                  "surface": " kokoro ",
                  "reading": "kokoro",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "definition": "duplicate",
                  "status": "candidate"
                }
                """, adminToken);

        assertAdminError(response, 409, "ADMIN_LEXEME_DUPLICATE");
    }

    @Test
    void blankSurfaceOrDefinitionReturnsAdminLexemeInvalid() throws Exception {
        var adminToken = adminToken();

        var blankSurface = postJsonWithBearer("/api/v1/admin/lexemes", """
                {
                  "surface": "   ",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "definition": "definition",
                  "status": "active"
                }
                """, adminToken);
        var blankDefinition = postJsonWithBearer("/api/v1/admin/lexemes", """
                {
                  "surface": "Kokoro",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "word",
                  "definition": "   ",
                  "status": "active"
                }
                """, adminToken);

        assertAdminError(blankSurface, 400, "ADMIN_LEXEME_INVALID");
        assertAdminError(blankDefinition, 400, "ADMIN_LEXEME_INVALID");
    }

    @Test
    void updateLexemeChangesPublicFieldsOnlyAndWritesAuditLog() throws Exception {
        var lexeme = saveLexeme("Kokoro", "kokoro", "ja", "zh-CN", LexemeEntryType.WORD, LexemeStatus.CANDIDATE);
        var adminToken = adminToken();

        var response = patchJsonWithBearer("/api/v1/admin/lexemes/%s".formatted(lexeme.getId()), """
                {
                  "surface": "Kokoro Updated",
                  "reading": "updated",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "entryType": "phrase",
                  "partOfSpeech": "noun phrase",
                  "definition": "updated definition",
                  "shortDefinition": "updated",
                  "example": "Updated admin example.",
                  "status": "active"
                }
                """, adminToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/data/id").asText()).isEqualTo(lexeme.getId().toString());
        assertThat(json.at("/data/surface").asText()).isEqualTo("Kokoro Updated");
        assertThat(json.at("/data/normalizedSurface").asText()).isEqualTo("kokoro updated");
        assertThat(json.at("/data/entryType").asText()).isEqualTo("phrase");
        assertThat(json.at("/data/status").asText()).isEqualTo("active");
        assertResponseExcludesForbiddenContent(response.body());

        var auditLogs = adminAuditLogRepository.findByAdminUserIdOrderByCreatedAtDesc(
                UUID.fromString(objectMapper.readTree(getWithBearer("/api/v1/admin/auth/me", adminToken).body())
                        .at("/data/id").asText()));
        assertThat(auditLogs).extracting(AdminAuditLog::getAction).contains("lexeme.update");
        assertAuditDetailsAreSafe(auditLogs.getFirst().getDetailsJson());
    }

    @Test
    void rejectLexemeSetsRejectedStatusAndWritesAuditLog() throws Exception {
        var lexeme = saveLexeme("Candidate", "candidate", "ja", "zh-CN", LexemeEntryType.WORD, LexemeStatus.CANDIDATE);
        var adminToken = adminToken();

        var response = postJsonWithBearer("/api/v1/admin/lexemes/%s/reject".formatted(lexeme.getId()), """
                {
                  "reason": "duplicate or low quality"
                }
                """, adminToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/data/id").asText()).isEqualTo(lexeme.getId().toString());
        assertThat(json.at("/data/status").asText()).isEqualTo("rejected");
        assertThat(lexemeRepository.findById(lexeme.getId()).orElseThrow().getStatus()).isEqualTo(LexemeStatus.REJECTED);

        var auditLogs = adminAuditLogRepository.findAll();
        assertThat(auditLogs).extracting(AdminAuditLog::getAction).contains("lexeme.reject");
        assertThat(auditLogs).allSatisfy(log -> assertAuditDetailsAreSafe(log.getDetailsJson()));
    }

    @Test
    void userTokenCannotAccessAdminLexemeEndpoints() throws Exception {
        var lexeme = saveLexeme("Kokoro", "kokoro", "ja", "zh-CN", LexemeEntryType.WORD, LexemeStatus.ACTIVE);
        var userToken = registerUserAndReturnAccessToken();

        assertAdminRequired(getWithBearer("/api/v1/admin/lexemes", userToken));
        assertAdminRequired(postJsonWithBearer("/api/v1/admin/lexemes", validCreateJson("User Token"), userToken));
        assertAdminRequired(patchJsonWithBearer(
                "/api/v1/admin/lexemes/%s".formatted(lexeme.getId()),
                validCreateJson("User Token Update"),
                userToken));
        assertAdminRequired(postJsonWithBearer(
                "/api/v1/admin/lexemes/%s/reject".formatted(lexeme.getId()),
                "{\"reason\":\"nope\"}",
                userToken));
    }

    private Lexeme saveLexeme(
            String surface,
            String normalizedSurface,
            String sourceLang,
            String targetLang,
            LexemeEntryType entryType,
            LexemeStatus status) {
        return lexemeRepository.saveAndFlush(new Lexeme(
                surface,
                normalizedSurface,
                "reading",
                sourceLang,
                targetLang,
                entryType,
                "noun",
                "definition",
                "short",
                "Admin example",
                status));
    }

    private void savePrivateSentenceCard() {
        var user = userAccountRepository.saveAndFlush(new UserAccount(
                "private-card-owner@example.com",
                "hash-1",
                "Private Owner",
                "ja",
                "zh-CN",
                UserStatus.ACTIVE));
        userWordCardRepository.saveAndFlush(new UserWordCard(
                user,
                null,
                WordCardType.PRIVATE_SENTENCE,
                RAW_CONTENT_SENTINEL,
                TRANSLATED_TEXT_SENTINEL,
                PRIVATE_CONTEXT_SENTINEL,
                null,
                null,
                ReviewStatus.NEW,
                0,
                null,
                null));
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

    private String validCreateJson(String surface) {
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
        assertAdminError(response, 401, "ADMIN_REQUIRED");
    }

    private void assertAdminError(HttpResponse<String> response, int statusCode, String errorCode) throws Exception {
        assertThat(response.statusCode()).isEqualTo(statusCode);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo(errorCode);
    }

    private void assertAuditDetailsAreSafe(String detailsJson) {
        assertThat(detailsJson)
                .contains("\"redacted\":true")
                .doesNotContain("password")
                .doesNotContain("token")
                .doesNotContain("raw")
                .doesNotContain("content")
                .doesNotContain("private")
                .doesNotContain("translated")
                .doesNotContain(PRIVATE_CONTEXT_SENTINEL)
                .doesNotContain(RAW_CONTENT_SENTINEL)
                .doesNotContain(TRANSLATED_TEXT_SENTINEL);
    }

    private void assertResponseExcludesForbiddenContent(String responseBody) throws Exception {
        assertThat(responseBody)
                .doesNotContain("passwordHash")
                .doesNotContain("password_hash")
                .doesNotContain("credentialHash")
                .doesNotContain("refreshToken")
                .doesNotContain("accessToken")
                .doesNotContain("tokenHash")
                .doesNotContain("chapterContent")
                .doesNotContain("paragraphText")
                .doesNotContain("translatedText")
                .doesNotContain("privateContext")
                .doesNotContain(PRIVATE_CONTEXT_SENTINEL)
                .doesNotContain(RAW_CONTENT_SENTINEL)
                .doesNotContain(TRANSLATED_TEXT_SENTINEL);

        assertNodeExcludesForbiddenKeys(objectMapper.readTree(responseBody));
    }

    private void assertNodeExcludesForbiddenKeys(JsonNode node) {
        if (node.isObject()) {
            node.fieldNames().forEachRemaining(fieldName -> {
                assertThat(fieldName).isNotIn(
                        "password",
                        "passwordHash",
                        "password_hash",
                        "token",
                        "accessToken",
                        "refreshToken",
                        "tokenHash",
                        "token_hash",
                        "content",
                        "chapterContent",
                        "chapter_content",
                        "privateContext",
                        "private_context",
                        "rawText",
                        "raw_text",
                        "translatedText",
                        "translated_text",
                        "paragraphText",
                        "paragraph_text");
                assertNodeExcludesForbiddenKeys(node.get(fieldName));
            });
        } else if (node.isArray()) {
            node.forEach(this::assertNodeExcludesForbiddenKeys);
        }
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
