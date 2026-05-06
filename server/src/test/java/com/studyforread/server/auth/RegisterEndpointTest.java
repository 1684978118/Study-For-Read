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
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class RegisterEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void registersUserAndReturnsTokensWithoutSecrets() throws Exception {
        var email = "Reader@Example.COM";
        var rawPassword = "change-this-password";

        var response = postRegister("""
                {
                  "email": "%s",
                  "password": "%s",
                  "displayName": "Reader",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """.formatted(email, rawPassword));

        assertThat(response.statusCode()).isEqualTo(201);
        var responseBody = response.body();
        assertThat(responseBody).isNotNull();
        var responseJson = objectMapper.readTree(responseBody);
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/user/email").asText()).isEqualTo("reader@example.com");
        assertThat(responseJson.at("/data/user/displayName").asText()).isEqualTo("Reader");
        assertThat(responseJson.at("/data/user/sourceLang").asText()).isEqualTo("ja");
        assertThat(responseJson.at("/data/user/targetLang").asText()).isEqualTo("zh-CN");
        assertThat(responseJson.at("/data/user/status").asText()).isEqualTo("active");
        assertThat(responseJson.at("/data/accessToken").asText()).isNotBlank();
        assertThat(responseJson.at("/data/refreshToken").asText()).isNotBlank();
        assertThat(responseJson.at("/error").isNull()).isTrue();

        assertThat(responseBody).doesNotContain("password");
        assertThat(responseBody).doesNotContain("passwordHash");

        var rawRefreshToken = responseJson.at("/data/refreshToken").asText();

        var persisted = jdbcTemplate.queryForObject(
                """
                        select u.password_hash, rt.token_hash
                        from users u
                        join refresh_tokens rt on rt.user_id = u.id
                        where u.email = ?
                        """,
                (rs, rowNum) -> new PersistedSecrets(
                        rs.getString("password_hash"),
                        rs.getString("token_hash")),
                "reader@example.com");

        assertThat(persisted).isNotNull();
        assertThat(persisted.passwordHash()).isNotEqualTo(rawPassword);
        assertThat(persisted.passwordHash()).isNotBlank();
        assertThat(persisted.tokenHash()).hasSize(64);
        assertThat(persisted.tokenHash()).matches("[0-9a-f]{64}");
        assertThat(persisted.tokenHash()).isNotEqualTo(rawRefreshToken);
    }

    @Test
    void duplicateEmailReturnsAuthEmailAlreadyExists() throws Exception {
        register("duplicate@example.com");

        var response = postRegister("""
                {
                  "email": "DUPLICATE@example.com",
                  "password": "change-this-password",
                  "displayName": "Reader",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """);

        assertThat(response.statusCode()).isEqualTo(409);
        var responseBody = response.body();
        assertThat(responseBody).isNotNull();
        var responseJson = objectMapper.readTree(responseBody);
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("AUTH_EMAIL_ALREADY_EXISTS");
    }

    private JsonNode register(String email) throws Exception {
        var response = postRegister("""
                {
                  "email": "%s",
                  "password": "change-this-password",
                  "displayName": "Reader",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """.formatted(email));

        assertThat(response.statusCode()).isEqualTo(201);
        var responseBody = response.body();
        assertThat(responseBody).isNotNull();

        return objectMapper.readTree(responseBody);
    }

    private HttpResponse<String> postRegister(String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/auth/register".formatted(port)))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
    }

    private record PersistedSecrets(String passwordHash, String tokenHash) {
    }
}
