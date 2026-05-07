package com.studyforread.server.study;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.UUID;
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
class LookupEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void existingActivePublicLexemeReturnsPublicLexemeProvider() throws Exception {
        var accessToken = registerAndGetAccessToken("lookup-public-lexeme@example.com");
        var lexemeId = insertLexeme("Kokoro", "kokoro", "heart; mind", "heart");

        var response = postLookup(accessToken, lookupJson("  Kokoro  ", "ja", "zh-CN", "private context"));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/kind").asText()).isEqualTo("lexeme");
        assertThat(responseJson.at("/data/provider").asText()).isEqualTo("public_lexeme");
        assertThat(responseJson.at("/data/providerMessage").isNull()).isTrue();
        assertThat(responseJson.at("/data/lexeme/id").asText()).isEqualTo(lexemeId.toString());
        assertThat(responseJson.at("/data/lexeme/surface").asText()).isEqualTo("Kokoro");
        assertThat(responseJson.at("/data/lexeme/reading").asText()).isEqualTo("kokoro");
        assertThat(responseJson.at("/data/lexeme/entryType").asText()).isEqualTo("word");
        assertThat(responseJson.at("/data/lexeme/partOfSpeech").asText()).isEqualTo("noun");
        assertThat(responseJson.at("/data/lexeme/definition").asText()).isEqualTo("heart; mind");
        assertThat(responseJson.at("/data/lexeme/shortDefinition").asText()).isEqualTo("heart");
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertTranslationEvent("public_lexeme", true, null, "Kokoro", 6);
    }

    @Test
    void missingLexemeUsesProviderRouterFallback() throws Exception {
        var accessToken = registerAndGetAccessToken("lookup-fallback@example.com");

        var response = postLookup(accessToken, lookupJson("michi", "ja", "zh-CN", null));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/kind").asText()).isEqualTo("lexeme");
        assertThat(responseJson.at("/data/provider").asText()).isEqualTo("local_fallback");
        assertThat(responseJson.at("/data/lexeme/surface").asText()).isEqualTo("michi");
        assertThat(responseJson.at("/data/lexeme/entryType").asText()).isEqualTo("word");
        assertThat(responseJson.at("/data/lexeme/definition").asText()).contains("local fallback");
        assertTranslationEvent("local_fallback", true, null, "michi", 5);
    }

    @Test
    void unsupportedLanguagePairReturnsTranslationUnsupportedLanguagePair() throws Exception {
        var accessToken = registerAndGetAccessToken("lookup-unsupported-language@example.com");

        var response = postLookup(accessToken, lookupJson("heart", "en", "zh-CN", null));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR");
        assertTranslationEvent(null, false, "TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR", "heart", 5);
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = postLookupWithoutToken(lookupJson("kokoro", "ja", "zh-CN", null));

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void contextIsNotStoredInTranslationEvents() throws Exception {
        var accessToken = registerAndGetAccessToken("lookup-context-not-stored@example.com");
        var privateContext = "do not store this private sentence context";

        var response = postLookup(accessToken, lookupJson("sora", "ja", "zh-CN", privateContext));

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).doesNotContain(privateContext);
        assertThat(translationEventsColumns()).doesNotContain(
                "text",
                "context",
                "source_text",
                "raw_text",
                "translated_text",
                "paragraph_text",
                "chapter_content");
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.get("source_text_hash")).isEqualTo(sha256Hex("sora"));
        assertThat(event.get("source_text_length")).isEqualTo(4);
        assertThat(event.toString()).doesNotContain(privateContext, "sora");
    }

    @Test
    void emptyTextReturnsValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("lookup-empty-text@example.com");

        var response = postLookup(accessToken, lookupJson("   ", "ja", "zh-CN", null));

        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("VALIDATION_ERROR");
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

    private UUID insertLexeme(String surface, String normalizedSurface, String definition, String shortDefinition) {
        var id = UUID.randomUUID();
        jdbcTemplate.update(
                """
                        insert into lexemes (
                            id,
                            surface,
                            normalized_surface,
                            reading,
                            source_lang,
                            target_lang,
                            entry_type,
                            part_of_speech,
                            definition,
                            short_definition,
                            example,
                            status,
                            created_at,
                            updated_at
                        ) values (?, ?, ?, ?, 'ja', 'zh-CN', 'word', 'noun', ?, ?, null, 'active', current_timestamp, current_timestamp)
                        """,
                id,
                surface,
                normalizedSurface,
                normalizedSurface,
                definition,
                shortDefinition);
        return id;
    }

    private void assertTranslationEvent(
            String provider,
            boolean success,
            String errorCode,
            String text,
            int sourceTextLength) {
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.get("request_type")).isEqualTo("word_lookup");
        assertThat(event.get("source_lang")).isNotNull();
        assertThat(event.get("target_lang")).isNotNull();
        assertThat(event.get("provider")).isEqualTo(provider);
        assertThat(event.get("source_text_hash")).isEqualTo(sha256Hex(text.trim()));
        assertThat(event.get("source_text_length")).isEqualTo(sourceTextLength);
        assertThat(event.get("success")).isEqualTo(success);
        assertThat(event.get("error_code")).isEqualTo(errorCode);
    }

    private java.util.List<String> translationEventsColumns() {
        return jdbcTemplate.queryForList(
                """
                        select lower(column_name)
                        from information_schema.columns
                        where lower(table_name) = 'translation_events'
                        """,
                String.class);
    }

    private String lookupJson(String text, String sourceLang, String targetLang, String context) {
        if (context == null) {
            return """
                    {
                      "text": "%s",
                      "sourceLang": "%s",
                      "targetLang": "%s"
                    }
                    """.formatted(text, sourceLang, targetLang);
        }
        return """
                {
                  "text": "%s",
                  "sourceLang": "%s",
                  "targetLang": "%s",
                  "context": "%s"
                }
                """.formatted(text, sourceLang, targetLang, context);
    }

    private HttpResponse<String> postLookup(String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/study/lookup".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postLookupWithoutToken(String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/study/lookup".formatted(port)))
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
