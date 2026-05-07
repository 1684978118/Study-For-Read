package com.studyforread.server.study;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyforread.server.study.provider.AnnotationResult;
import com.studyforread.server.study.provider.LocalFallbackStudyProvider;
import com.studyforread.server.study.provider.LookupProviderResult;
import com.studyforread.server.study.provider.ParagraphTranslationResult;
import com.studyforread.server.study.provider.StudyProvider;
import com.studyforread.server.study.provider.StudyProviderRouter;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class TranslateParagraphEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void authenticatedUserCanTranslateOneParagraphAndReceivesTranslatedTextAndProvider() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-success@example.com");
        var paragraph = "kuni no nagai tonneru o nukeru to yukiguni de atta.";

        var response = postTranslateParagraph(accessToken, translateParagraphJson(paragraph, "ja", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/translatedText").asText())
                .isEqualTo("[local fallback translation unavailable]");
        assertThat(responseJson.at("/data/provider").asText()).isEqualTo("local_fallback");
        assertThat(responseJson.at("/data/cached").asBoolean()).isFalse();
        assertThat(responseJson.at("/data/message").isNull()).isTrue();
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertThat(response.body()).doesNotContain(paragraph);
        assertTranslationEvent("local_fallback", true, null, paragraph, paragraph.length());
    }

    @Test
    void emptyTextReturnsValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-empty-text@example.com");

        var response = postTranslateParagraph(accessToken, translateParagraphJson("   ", "ja", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    @Test
    void textAboveFirstReleaseLimitReturnsTranslationTextTooLong() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-too-long@example.com");
        var paragraph = "a".repeat(2001);

        var response = postTranslateParagraph(accessToken, translateParagraphJson(paragraph, "ja", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("TRANSLATION_TEXT_TOO_LONG");
        assertTranslationEvent(null, false, "TRANSLATION_TEXT_TOO_LONG", paragraph, paragraph.length());
    }

    @Test
    void unsupportedLanguagePairReturnsTranslationUnsupportedLanguagePair() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-unsupported-language@example.com");
        var paragraph = "one selected paragraph";

        var response = postTranslateParagraph(accessToken, translateParagraphJson(paragraph, "en", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR");
        assertTranslationEvent(null, false, "TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR", paragraph, paragraph.length());
    }

    @Test
    void providerFailureReturnsTranslationProviderUnavailable() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-provider-failure@example.com");
        var paragraph = "provider-failure";

        var response = postTranslateParagraph(accessToken, translateParagraphJson(paragraph, "ja", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(503);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("TRANSLATION_PROVIDER_UNAVAILABLE");
        assertTranslationEvent(null, false, "TRANSLATION_PROVIDER_UNAVAILABLE", paragraph, paragraph.length());
    }

    @Test
    void translationEventStoresHashAndLengthOnly() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-no-raw-event@example.com");
        var paragraph = "private paragraph should never become event corpus";

        var response = postTranslateParagraph(accessToken, translateParagraphJson(paragraph, "ja", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).doesNotContain(paragraph);
        assertThat(translationEventsColumns()).doesNotContain(
                "text",
                "context",
                "source_text",
                "raw_text",
                "translated_text",
                "paragraph_text",
                "chapter_content",
                "content");
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.get("source_text_hash")).isEqualTo(sha256Hex(paragraph));
        assertThat(event.get("source_text_length")).isEqualTo(paragraph.length());
        assertThat(event.toString()).doesNotContain(paragraph, "[local fallback translation unavailable]");
    }

    @Test
    void arraysOrFullBookContentReturnValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("translate-array-payload@example.com");

        var arrayResponse = postTranslateParagraph(accessToken, """
                {
                  "text": ["first paragraph", "second paragraph"],
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """);
        var contentResponse = postTranslateParagraph(accessToken, """
                {
                  "text": "one paragraph",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "content": "full book content is not accepted"
                }
                """);

        assertValidationError(arrayResponse);
        assertValidationError(contentResponse);
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = postTranslateParagraphWithoutToken(translateParagraphJson("paragraph", "ja", "zh-CN"));

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    private void assertValidationError(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    private void assertTranslationEvent(
            String provider,
            boolean success,
            String errorCode,
            String text,
            int sourceTextLength) {
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.get("request_type")).isEqualTo("paragraph_translation");
        assertThat(event.get("source_lang")).isNotNull();
        assertThat(event.get("target_lang")).isNotNull();
        assertThat(event.get("provider")).isEqualTo(provider);
        assertThat(event.get("source_text_hash")).isEqualTo(sha256Hex(text.trim()));
        assertThat(event.get("source_text_length")).isEqualTo(sourceTextLength);
        assertThat(event.get("success")).isEqualTo(success);
        assertThat(event.get("error_code")).isEqualTo(errorCode);
    }

    private List<String> translationEventsColumns() {
        return jdbcTemplate.queryForList(
                """
                        select lower(column_name)
                        from information_schema.columns
                        where lower(table_name) = 'translation_events'
                        """,
                String.class);
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

    private String translateParagraphJson(String text, String sourceLang, String targetLang) {
        return """
                {
                  "text": "%s",
                  "sourceLang": "%s",
                  "targetLang": "%s"
                }
                """.formatted(text, sourceLang, targetLang);
    }

    private HttpResponse<String> postTranslateParagraph(String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/study/translate-paragraph".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postTranslateParagraphWithoutToken(String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/study/translate-paragraph".formatted(port)))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
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

    private String sha256Hex(String value) {
        try {
            var digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            var hex = new StringBuilder();
            for (byte current : digest) {
                hex.append(String.format("%02x", current));
            }
            return hex.toString();
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    @TestConfiguration
    static class ProviderConfiguration {

        @Bean
        StudyProviderRouter studyProviderRouter() {
            return new StudyProviderRouter(List.of(new FailingParagraphStudyProvider()));
        }
    }

    private static class FailingParagraphStudyProvider implements StudyProvider {

        private final LocalFallbackStudyProvider fallback = new LocalFallbackStudyProvider();

        @Override
        public LookupProviderResult lookup(String text, String sourceLang, String targetLang, String context) {
            return fallback.lookup(text, sourceLang, targetLang, context);
        }

        @Override
        public ParagraphTranslationResult translateParagraph(String text, String sourceLang, String targetLang) {
            if ("provider-failure".equals(text.trim())) {
                throw new IllegalStateException("Provider is unavailable");
            }
            return fallback.translateParagraph(text, sourceLang, targetLang);
        }

        @Override
        public AnnotationResult annotate(String text, String sourceLang) {
            return fallback.annotate(text, sourceLang);
        }
    }
}
