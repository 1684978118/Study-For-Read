package com.studyforread.server.study;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;
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
class AnnotateEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void authenticatedUserCanAnnotateShortJapaneseTextAndReceivesTokens() throws Exception {
        var accessToken = registerAndGetAccessToken("annotate-success@example.com");
        var text = "先生 心";

        var response = postAnnotate(accessToken, annotateJson(text, "ja"));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertThat(responseJson.at("/data/tokens")).hasSize(2);
        assertThat(responseJson.at("/data/tokens/0/text").asText()).isEqualTo("先生");
        assertThat(responseJson.at("/data/tokens/0/dictionaryForm").asText()).isEqualTo("先生");
        assertThat(responseJson.at("/data/tokens/1/text").asText()).isEqualTo("心");
        assertThat(responseJson.at("/data/tokens/1/dictionaryForm").asText()).isEqualTo("心");
        assertTranslationEvent("local_fallback", true, null, text, text.length(), "ja");
    }

    @Test
    void emptyTextReturnsValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("annotate-empty-text@example.com");

        var response = postAnnotate(accessToken, annotateJson("   ", "ja"));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    @Test
    void unsupportedSourceLanguageReturnsTranslationUnsupportedLanguagePair() throws Exception {
        var accessToken = registerAndGetAccessToken("annotate-unsupported-language@example.com");
        var text = "hello world";

        var response = postAnnotate(accessToken, annotateJson(text, "en"));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR");
        assertTranslationEvent(null, false, "TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR", text, text.length(), "en");
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = postAnnotateWithoutToken(annotateJson("先生 心", "ja"));

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void annotationEventStoresHashAndLengthOnly() throws Exception {
        var accessToken = registerAndGetAccessToken("annotate-no-raw-event@example.com");
        var text = "private annotation text should not be stored";

        var response = postAnnotate(accessToken, annotateJson(text, "ja"));

        assertThat(response.statusCode()).isEqualTo(200);
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
        assertThat(event.get("request_type")).isEqualTo("annotation");
        assertThat(event.get("source_text_hash")).isEqualTo(sha256Hex(text));
        assertThat(event.get("source_text_length")).isEqualTo(text.length());
        assertThat(event.toString()).doesNotContain(text);
    }

    @Test
    void responseTokenFieldsMatchApiContract() throws Exception {
        var accessToken = registerAndGetAccessToken("annotate-token-shape@example.com");

        var response = postAnnotate(accessToken, annotateJson("先生", "ja"));

        assertThat(response.statusCode()).isEqualTo(200);
        var token = objectMapper.readTree(response.body()).at("/data/tokens/0");
        var fieldNames = new ArrayList<String>();
        token.fieldNames().forEachRemaining(fieldNames::add);
        assertThat(fieldNames).containsExactly("text", "reading", "dictionaryForm", "partOfSpeech");
    }

    @Test
    void noThirdPartyMorphologicalAnalyzerDependencyIsIntroduced() throws Exception {
        var pom = Files.readString(Path.of("pom.xml"));

        assertThat(pom)
                .doesNotContainIgnoringCase("kuromoji")
                .doesNotContainIgnoringCase("lucene-analyzers")
                .doesNotContainIgnoringCase("mecab");
    }

    private void assertTranslationEvent(
            String provider,
            boolean success,
            String errorCode,
            String text,
            int sourceTextLength,
            String sourceLang) {
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.get("request_type")).isEqualTo("annotation");
        assertThat(event.get("source_lang")).isEqualTo(sourceLang);
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

    private String annotateJson(String text, String sourceLang) {
        return """
                {
                  "text": "%s",
                  "sourceLang": "%s"
                }
                """.formatted(text, sourceLang);
    }

    private HttpResponse<String> postAnnotate(String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/study/annotate".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postAnnotateWithoutToken(String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/study/annotate".formatted(port)))
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
}
