package com.studyforread.server.admin;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
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
class AdminAuthEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private AdminUserRepository adminUserRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${local.server.port}")
    private int port;

    @Test
    void activeAdminCanLoginAndRetrieveCurrentProfileWithoutSecrets() throws Exception {
        var admin = saveAdmin("admin", "change-this-password", AdminRole.ADMIN, AdminStatus.ACTIVE);

        var login = postJson("/api/v1/admin/auth/login", """
                {
                  "username": "admin",
                  "password": "change-this-password"
                }
                """);

        assertThat(login.statusCode()).isEqualTo(200);
        var loginBody = login.body();
        assertThat(loginBody).isNotNull();
        var loginJson = objectMapper.readTree(loginBody);
        assertThat(loginJson.at("/success").asBoolean()).isTrue();
        assertThat(loginJson.at("/data/admin/id").asText()).isEqualTo(admin.getId().toString());
        assertThat(loginJson.at("/data/admin/username").asText()).isEqualTo("admin");
        assertThat(loginJson.at("/data/admin/role").asText()).isEqualTo("admin");
        assertThat(loginJson.at("/data/admin/status").asText()).isEqualTo("active");
        assertThat(loginJson.at("/data/accessToken").asText()).startsWith("admin_access.");
        assertThat(loginJson.at("/error").isNull()).isTrue();
        assertThat(loginBody).doesNotContain("credentialHash");
        assertThat(loginBody).doesNotContain("credential_hash");
        assertThat(loginBody).doesNotContain("password");

        var me = getWithBearer("/api/v1/admin/auth/me", loginJson.at("/data/accessToken").asText());

        assertThat(me.statusCode()).isEqualTo(200);
        var meBody = me.body();
        assertThat(meBody).isNotNull();
        var meJson = objectMapper.readTree(meBody);
        assertThat(meJson.at("/success").asBoolean()).isTrue();
        assertThat(meJson.at("/data/id").asText()).isEqualTo(admin.getId().toString());
        assertThat(meJson.at("/data/username").asText()).isEqualTo("admin");
        assertThat(meJson.at("/data/role").asText()).isEqualTo("admin");
        assertThat(meJson.at("/data/status").asText()).isEqualTo("active");
        assertThat(meJson.at("/error").isNull()).isTrue();
        assertThat(meBody).doesNotContain("credentialHash");
        assertThat(meBody).doesNotContain("credential_hash");
        assertThat(meBody).doesNotContain("password");
    }

    @Test
    void invalidAdminCredentialsReturnAdminInvalidCredentials() throws Exception {
        saveAdmin("operator", "change-this-password", AdminRole.OPERATOR, AdminStatus.ACTIVE);

        var wrongPassword = postJson("/api/v1/admin/auth/login", """
                {
                  "username": "operator",
                  "password": "not-the-password"
                }
                """);
        var missingUser = postJson("/api/v1/admin/auth/login", """
                {
                  "username": "missing",
                  "password": "change-this-password"
                }
                """);

        assertAdminError(wrongPassword, 401, "ADMIN_INVALID_CREDENTIALS");
        assertAdminError(missingUser, 401, "ADMIN_INVALID_CREDENTIALS");
    }

    @Test
    void disabledAdminCannotLogin() throws Exception {
        saveAdmin("disabled-admin", "change-this-password", AdminRole.ADMIN, AdminStatus.DISABLED);

        var response = postJson("/api/v1/admin/auth/login", """
                {
                  "username": "disabled-admin",
                  "password": "change-this-password"
                }
                """);

        assertAdminError(response, 403, "ADMIN_DISABLED");
    }

    @Test
    void currentAdminRequiresAdminTokenAndRejectsUserToken() throws Exception {
        var userAccessToken = registerUserAndReturnAccessToken();

        assertAdminError(get("/api/v1/admin/auth/me"), 401, "ADMIN_REQUIRED");
        assertAdminError(getWithBearer("/api/v1/admin/auth/me", userAccessToken), 401, "ADMIN_REQUIRED");
    }

    @Test
    void adminTokenCannotAuthenticateAsNormalUserToken() throws Exception {
        saveAdmin("admin-token-only", "change-this-password", AdminRole.ADMIN, AdminStatus.ACTIVE);
        var login = postJson("/api/v1/admin/auth/login", """
                {
                  "username": "admin-token-only",
                  "password": "change-this-password"
                }
                """);
        var adminToken = objectMapper.readTree(login.body()).at("/data/accessToken").asText();

        var response = getWithBearer("/api/v1/auth/me", adminToken);

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    private AdminUser saveAdmin(String username, String password, AdminRole role, AdminStatus status) {
        return adminUserRepository.saveAndFlush(new AdminUser(
                username,
                passwordEncoder.encode(password),
                role,
                status));
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

    private void assertAdminError(HttpResponse<String> response, int statusCode, String errorCode) throws Exception {
        assertThat(response.statusCode()).isEqualTo(statusCode);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo(errorCode);
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

    private HttpResponse<String> get(String path) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

}
