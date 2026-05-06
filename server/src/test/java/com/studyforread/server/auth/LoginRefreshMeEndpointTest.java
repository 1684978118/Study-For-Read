package com.studyforread.server.auth;

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
class LoginRefreshMeEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void existingRegisteredUserCanLoginAndReceivesTokensWithoutSecrets() throws Exception {
        register("login@example.com", "change-this-password");

        var response = postJson("/api/v1/auth/login", """
                {
                  "email": "LOGIN@example.com",
                  "password": "change-this-password"
                }
                """);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseBody = response.body();
        assertThat(responseBody).isNotNull();
        var responseJson = objectMapper.readTree(responseBody);
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/user/email").asText()).isEqualTo("login@example.com");
        assertThat(responseJson.at("/data/user/displayName").asText()).isEqualTo("Reader");
        assertThat(responseJson.at("/data/user/sourceLang").asText()).isEqualTo("ja");
        assertThat(responseJson.at("/data/user/targetLang").asText()).isEqualTo("zh-CN");
        assertThat(responseJson.at("/data/user/status").asText()).isEqualTo("active");
        assertThat(responseJson.at("/data/accessToken").asText()).isNotBlank();
        assertThat(responseJson.at("/data/refreshToken").asText()).isNotBlank();
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertThat(responseBody).doesNotContain("password");
        assertThat(responseBody).doesNotContain("passwordHash");
    }

    @Test
    void wrongPasswordReturnsInvalidCredentialsWithoutRevealingAccountState() throws Exception {
        register("wrong-password@example.com", "change-this-password");

        var response = postJson("/api/v1/auth/login", """
                {
                  "email": "wrong-password@example.com",
                  "password": "not-the-password"
                }
                """);

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("AUTH_INVALID_CREDENTIALS");
        assertThat(responseJson.at("/error/message").asText()).isEqualTo("Invalid email or password");
    }

    @Test
    void validRefreshTokenReturnsNewTokensAndStoresOnlyHash() throws Exception {
        var registered = register("refresh@example.com", "change-this-password");
        var originalRefreshToken = registered.at("/data/refreshToken").asText();

        var response = postJson("/api/v1/auth/refresh", """
                {
                  "refreshToken": "%s"
                }
                """.formatted(originalRefreshToken));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/accessToken").asText()).isNotBlank();
        assertThat(responseJson.at("/data/refreshToken").asText()).isNotBlank();
        assertThat(responseJson.at("/data/refreshToken").asText()).isNotEqualTo(originalRefreshToken);
        assertThat(responseJson.at("/error").isNull()).isTrue();

        var newRefreshToken = responseJson.at("/data/refreshToken").asText();
        var hashes = jdbcTemplate.queryForList(
                "select token_hash from refresh_tokens order by created_at",
                String.class);
        assertThat(hashes).hasSize(2);
        assertThat(hashes).allMatch(hash -> hash.matches("[0-9a-f]{64}"));
        assertThat(hashes).doesNotContain(originalRefreshToken, newRefreshToken);
    }

    @Test
    void invalidRefreshTokenReturnsAuthRefreshTokenInvalid() throws Exception {
        var response = postJson("/api/v1/auth/refresh", """
                {
                  "refreshToken": "refresh.not-valid"
                }
                """);

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("AUTH_REFRESH_TOKEN_INVALID");
    }

    @Test
    void meWithValidAccessTokenReturnsCurrentUser() throws Exception {
        var registered = register("me@example.com", "change-this-password");
        var accessToken = registered.at("/data/accessToken").asText();

        var response = getWithBearer("/api/v1/auth/me", accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/email").asText()).isEqualTo("me@example.com");
        assertThat(responseJson.at("/data/displayName").asText()).isEqualTo("Reader");
        assertThat(responseJson.at("/data/sourceLang").asText()).isEqualTo("ja");
        assertThat(responseJson.at("/data/targetLang").asText()).isEqualTo("zh-CN");
        assertThat(responseJson.at("/data/status").asText()).isEqualTo("active");
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertThat(response.body()).doesNotContain("password");
        assertThat(response.body()).doesNotContain("passwordHash");
    }

    @Test
    void meWithoutTokenReturnsUnauthorized() throws Exception {
        var response = get("/api/v1/auth/me");

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    private JsonNode register(String email, String password) throws Exception {
        var response = postJson("/api/v1/auth/register", """
                {
                  "email": "%s",
                  "password": "%s",
                  "displayName": "Reader",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """.formatted(email, password));

        assertThat(response.statusCode()).isEqualTo(201);
        return objectMapper.readTree(response.body());
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
