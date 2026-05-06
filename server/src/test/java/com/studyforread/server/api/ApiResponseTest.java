package com.studyforread.server.api;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.junit.jupiter.api.Test;

class ApiResponseTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void okCreatesSuccessEnvelope() throws Exception {
        Map<String, String> data = Map.of("id", "user-1");

        ApiResponse<Map<String, String>> response = ApiResponse.ok(data);

        assertThat(response.success()).isTrue();
        assertThat(response.data()).isEqualTo(data);
        assertThat(response.error()).isNull();

        JsonNode json = objectMapper.valueToTree(response);
        assertThat(json.has("success")).isTrue();
        assertThat(json.get("success").asBoolean()).isTrue();
        assertThat(json.has("data")).isTrue();
        assertThat(json.get("data").get("id").asText()).isEqualTo("user-1");
        assertThat(json.has("error")).isTrue();
        assertThat(json.get("error").isNull()).isTrue();
    }

    @Test
    void failCreatesErrorEnvelope() {
        ApiResponse<Object> response = ApiResponse.fail(
                ErrorCode.UNAUTHORIZED,
                "Authentication required");

        assertThat(response.success()).isFalse();
        assertThat(response.data()).isNull();
        assertThat(response.error()).isNotNull();
        assertThat(response.error().code()).isEqualTo(ErrorCode.UNAUTHORIZED);
        assertThat(response.error().message()).isEqualTo("Authentication required");

        JsonNode json = objectMapper.valueToTree(response);
        assertThat(json.has("success")).isTrue();
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.has("data")).isTrue();
        assertThat(json.get("data").isNull()).isTrue();
        assertThat(json.has("error")).isTrue();
        assertThat(json.get("error").has("code")).isTrue();
        assertThat(json.get("error").get("code").asText()).isEqualTo("UNAUTHORIZED");
        assertThat(json.get("error").has("message")).isTrue();
        assertThat(json.get("error").get("message").asText())
                .isEqualTo("Authentication required");
    }

    @Test
    void errorCodeIncludesInitialContractCodes() {
        assertThat(ErrorCode.values()).contains(
                ErrorCode.VALIDATION_ERROR,
                ErrorCode.UNAUTHORIZED,
                ErrorCode.FORBIDDEN,
                ErrorCode.NOT_FOUND,
                ErrorCode.CONFLICT,
                ErrorCode.INTERNAL_ERROR,
                ErrorCode.AUTH_EMAIL_ALREADY_EXISTS,
                ErrorCode.AUTH_INVALID_CREDENTIALS);
    }
}
