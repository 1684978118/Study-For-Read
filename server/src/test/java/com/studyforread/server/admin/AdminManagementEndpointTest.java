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
class AdminManagementEndpointTest {

    private static final String FIRST_BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private static final String SECOND_BOOK_FINGERPRINT =
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";

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
    void adminCanListUsersWithPaginationStatusFilterAndQueryWithoutSecretsOrContent() throws Exception {
        saveUser("alpha.reader@example.com", "Alpha Reader", UserStatus.ACTIVE);
        saveUser("beta.reader@example.com", "Beta Reader", UserStatus.ACTIVE);
        saveUser("disabled.reader@example.com", "Disabled Reader", UserStatus.DISABLED);
        var adminToken = adminToken();

        var firstPage = getWithBearer("/api/v1/admin/users?page=0&size=2", adminToken);
        var activeSearch = getWithBearer("/api/v1/admin/users?page=0&size=10&status=active&q=alpha", adminToken);

        assertThat(firstPage.statusCode()).isEqualTo(200);
        var firstPageJson = objectMapper.readTree(firstPage.body());
        assertThat(firstPageJson.at("/success").asBoolean()).isTrue();
        assertThat(firstPageJson.at("/data/items")).hasSize(2);
        assertThat(firstPageJson.at("/data/page").asInt()).isZero();
        assertThat(firstPageJson.at("/data/size").asInt()).isEqualTo(2);
        assertThat(firstPageJson.at("/data/total").asInt()).isEqualTo(3);

        assertThat(activeSearch.statusCode()).isEqualTo(200);
        var searchJson = objectMapper.readTree(activeSearch.body());
        assertThat(searchJson.at("/data/items")).hasSize(1);
        assertThat(searchJson.at("/data/items/0/email").asText()).isEqualTo("alpha.reader@example.com");
        assertThat(searchJson.at("/data/items/0/displayName").asText()).isEqualTo("Alpha Reader");
        assertThat(searchJson.at("/data/items/0/status").asText()).isEqualTo("active");

        assertResponseExcludesForbiddenContent(firstPage.body());
        assertResponseExcludesForbiddenContent(activeSearch.body());
    }

    @Test
    void userTokenCannotAccessAdminManagementEndpoints() throws Exception {
        var userToken = registerUserAndReturnAccessToken();

        assertAdminRequired(getWithBearer("/api/v1/admin/users", userToken));
        assertAdminRequired(getWithBearer("/api/v1/admin/stats/summary", userToken));
        assertAdminRequired(getWithBearer("/api/v1/admin/audit-logs", userToken));
    }

    @Test
    void platformStatsSummaryReturnsAggregateCountsOnly() throws Exception {
        var activeUser = saveUser("stats-active@example.com", "Stats Active", UserStatus.ACTIVE);
        saveUser("stats-disabled@example.com", "Stats Disabled", UserStatus.DISABLED);
        var lexeme = saveLexeme("心", "kokoro");
        userBookRepository.saveAndFlush(newBook(activeUser, FIRST_BOOK_FINGERPRINT, "Kokoro"));
        userBookRepository.saveAndFlush(newBook(activeUser, SECOND_BOOK_FINGERPRINT, "Botchan"));
        userWordCardRepository.saveAndFlush(new UserWordCard(
                activeUser,
                lexeme,
                WordCardType.LEXEME,
                null,
                null,
                null,
                FIRST_BOOK_FINGERPRINT,
                "Kokoro",
                ReviewStatus.LEARNING,
                1,
                OffsetDateTime.now().plusDays(3),
                OffsetDateTime.now()));
        studyDailyStatRepository.saveAndFlush(new StudyDailyStat(
                activeUser,
                LocalDate.of(2026, 5, 9),
                12,
                3,
                2,
                1,
                4));
        var adminToken = adminToken();

        var response = getWithBearer("/api/v1/admin/stats/summary", adminToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/success").asBoolean()).isTrue();
        assertThat(json.at("/data/userCount").asInt()).isEqualTo(2);
        assertThat(json.at("/data/activeUserCount").asInt()).isEqualTo(1);
        assertThat(json.at("/data/disabledUserCount").asInt()).isEqualTo(1);
        assertThat(json.at("/data/bookMetadataCount").asInt()).isEqualTo(2);
        assertThat(json.at("/data/lexemeCount").asInt()).isEqualTo(1);
        assertThat(json.at("/data/wordCardCount").asInt()).isEqualTo(1);
        assertThat(json.at("/data/readingMinutes").asInt()).isEqualTo(12);
        assertThat(json.at("/data/lookupCount").asInt()).isEqualTo(3);
        assertThat(json.at("/data/paragraphTranslationCount").asInt()).isEqualTo(2);
        assertThat(json.at("/data/cardsCreated").asInt()).isEqualTo(1);
        assertThat(json.at("/data/cardsReviewed").asInt()).isEqualTo(4);
        assertResponseExcludesForbiddenContent(response.body());
    }

    @Test
    void auditLogsReturnRedactedDetailsWithPaginationMetadata() throws Exception {
        var admin = saveAdmin("audit-admin", "change-this-password", AdminRole.ADMIN, AdminStatus.ACTIVE);
        adminAuditLogRepository.saveAndFlush(new AdminAuditLog(
                admin,
                "lexeme.create",
                "lexeme",
                UUID.randomUUID(),
                """
                        {
                          "surface": "kokoro",
                          "password": "secret-password",
                          "token": "raw-token",
                          "chapterContent": "full chapter content",
                          "paragraphText": "raw paragraph text",
                          "translatedText": "translated paragraph text",
                          "privateContext": "full private sentence context"
                        }
                        """,
                "127.0.0.1"));
        var adminToken = loginAdmin("audit-admin", "change-this-password");

        var response = getWithBearer("/api/v1/admin/audit-logs?page=0&size=10", adminToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/success").asBoolean()).isTrue();
        assertThat(json.at("/data/items")).hasSize(1);
        assertThat(json.at("/data/items/0/adminUserId").asText()).isEqualTo(admin.getId().toString());
        assertThat(json.at("/data/items/0/adminUsername").asText()).isEqualTo("audit-admin");
        assertThat(json.at("/data/items/0/action").asText()).isEqualTo("lexeme.create");
        assertThat(json.at("/data/items/0/targetType").asText()).isEqualTo("lexeme");
        assertThat(json.at("/data/items/0/details/redacted").asBoolean()).isTrue();
        assertThat(json.at("/data/page").asInt()).isZero();
        assertThat(json.at("/data/size").asInt()).isEqualTo(10);
        assertThat(json.at("/data/total").asInt()).isEqualTo(1);
        assertResponseExcludesForbiddenContent(response.body());
    }

    @Test
    void auditLogsSupportFilters() throws Exception {
        var firstAdmin = saveAdmin("first-audit-admin", "change-this-password", AdminRole.ADMIN, AdminStatus.ACTIVE);
        var secondAdmin = saveAdmin("second-audit-admin", "change-this-password", AdminRole.OPERATOR, AdminStatus.ACTIVE);
        var targetId = UUID.randomUUID();
        adminAuditLogRepository.saveAndFlush(new AdminAuditLog(
                firstAdmin,
                "lexeme.create",
                "lexeme",
                targetId,
                "{\"surface\":\"kokoro\",\"redacted\":true}",
                null));
        adminAuditLogRepository.saveAndFlush(new AdminAuditLog(
                secondAdmin,
                "user.inspect",
                "user",
                UUID.randomUUID(),
                "{\"redacted\":true}",
                null));
        var adminToken = loginAdmin("first-audit-admin", "change-this-password");

        var response = getWithBearer(
                "/api/v1/admin/audit-logs?page=0&size=20&adminUserId=%s&targetType=lexeme&action=lexeme.create"
                        .formatted(firstAdmin.getId()),
                adminToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var json = objectMapper.readTree(response.body());
        assertThat(json.at("/data/items")).hasSize(1);
        assertThat(json.at("/data/items/0/adminUserId").asText()).isEqualTo(firstAdmin.getId().toString());
        assertThat(json.at("/data/items/0/targetId").asText()).isEqualTo(targetId.toString());
        assertThat(json.at("/data/total").asInt()).isEqualTo(1);
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

    private UserAccount saveUser(String email, String displayName, UserStatus status) {
        return userAccountRepository.saveAndFlush(new UserAccount(
                email,
                "hash-1",
                displayName,
                "ja",
                "zh-CN",
                status));
    }

    private Lexeme saveLexeme(String surface, String normalizedSurface) {
        return lexemeRepository.saveAndFlush(new Lexeme(
                surface,
                normalizedSurface,
                "こころ",
                "ja",
                "zh-CN",
                LexemeEntryType.WORD,
                "noun",
                "heart",
                "heart",
                null,
                LexemeStatus.ACTIVE));
    }

    private UserBook newBook(UserAccount user, String fingerprint, String title) {
        return new UserBook(
                user,
                fingerprint,
                title,
                "Natsume Soseki",
                BookFileType.TXT,
                "ja",
                "zh-CN",
                12,
                0,
                0,
                0,
                OffsetDateTime.now());
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

    private void assertAdminRequired(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("ADMIN_REQUIRED");
    }

    private void assertResponseExcludesForbiddenContent(String responseBody) throws Exception {
        assertThat(responseBody)
                .doesNotContain("passwordHash")
                .doesNotContain("password_hash")
                .doesNotContain("credentialHash")
                .doesNotContain("refreshToken")
                .doesNotContain("accessToken")
                .doesNotContain("tokenHash")
                .doesNotContain("secret-password")
                .doesNotContain("raw-token")
                .doesNotContain("book content")
                .doesNotContain("chapter content")
                .doesNotContain("private sentence context")
                .doesNotContain("raw lookup text")
                .doesNotContain("raw paragraph text")
                .doesNotContain("translated text")
                .doesNotContain("translated paragraph text");

        var json = objectMapper.readTree(responseBody);
        assertNodeExcludesForbiddenKeys(json);
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

    private HttpResponse<String> getWithBearer(String path, String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }
}
