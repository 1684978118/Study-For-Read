package com.studyforread.server.study;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class TranslationComplianceRegressionTest {

    private static final List<String> FORBIDDEN_EVENT_COLUMNS = List.of(
            "source_text",
            "raw_text",
            "translated_text",
            "paragraph_text",
            "chapter_content",
            "book_content");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private RequestMappingHandlerMapping requestMappingHandlerMapping;

    @Value("${local.server.port}")
    private int port;

    @Test
    void translationEventsTableHasNoRawTextColumns() {
        assertThat(translationEventsColumns()).doesNotContainAnyElementsOf(FORBIDDEN_EVENT_COLUMNS);
    }

    @Test
    void lookupLogsHashAndLengthWithoutRawTextOrContext() throws Exception {
        var accessToken = registerAndGetAccessToken("compliance-lookup@example.com");
        var text = "private-lookup-token";
        var context = "private lookup context must not be stored";

        var response = postWithToken("/api/v1/study/lookup", accessToken, """
                {
                  "text": "%s",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "context": "%s"
                }
                """.formatted(text, context));

        assertThat(response.statusCode()).isEqualTo(200);
        assertSafeTranslationEvent("word_lookup", "local_fallback", true, null, text, text.length());
        assertOnlyHasSafeEventColumns();
        assertLatestEventTextDoesNotContain(text, context);
    }

    @Test
    void paragraphTranslationLogsHashAndLengthWithoutRawOrTranslatedText() throws Exception {
        var accessToken = registerAndGetAccessToken("compliance-paragraph@example.com");
        var paragraph = "private paragraph should not become stored text";
        var fallbackTranslation = "[local fallback translation unavailable]";

        var response = postWithToken("/api/v1/study/translate-paragraph", accessToken, """
                {
                  "text": "%s",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN"
                }
                """.formatted(paragraph));

        assertThat(response.statusCode()).isEqualTo(200);
        assertSafeTranslationEvent("paragraph_translation", "local_fallback", true, null, paragraph, paragraph.length());
        assertOnlyHasSafeEventColumns();
        assertLatestEventTextDoesNotContain(paragraph, fallbackTranslation);
    }

    @Test
    void annotationLogsHashAndLengthWithoutRawText() throws Exception {
        var accessToken = registerAndGetAccessToken("compliance-annotation@example.com");
        var text = "private annotation tokens";

        var response = postWithToken("/api/v1/study/annotate", accessToken, """
                {
                  "text": "%s",
                  "sourceLang": "ja"
                }
                """.formatted(text));

        assertThat(response.statusCode()).isEqualTo(200);
        assertSafeTranslationEvent("annotation", "local_fallback", true, null, text, text.length());
        assertOnlyHasSafeEventColumns();
        assertLatestEventTextDoesNotContain(text);
    }

    @Test
    void fullBookTranslationRouteDoesNotExist() {
        assertNoRoute("/api/v1/study/translate-book");
    }

    @Test
    void fullChapterTranslationRouteDoesNotExist() {
        assertNoRoute("/api/v1/study/translate-chapter");
    }

    private void assertSafeTranslationEvent(
            String requestType,
            String provider,
            boolean success,
            String errorCode,
            String text,
            int sourceTextLength) {
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.get("request_type")).isEqualTo(requestType);
        assertThat(event.get("provider")).isEqualTo(provider);
        assertThat(event.get("source_text_hash")).isEqualTo(sha256Hex(text.trim()));
        assertThat(event.get("source_text_length")).isEqualTo(sourceTextLength);
        assertThat(event.get("success")).isEqualTo(success);
        assertThat(event.get("error_code")).isEqualTo(errorCode);
    }

    private void assertOnlyHasSafeEventColumns() {
        assertThat(translationEventsColumns()).containsExactlyInAnyOrder(
                "id",
                "user_id",
                "request_type",
                "source_lang",
                "target_lang",
                "provider",
                "source_text_hash",
                "source_text_length",
                "success",
                "error_code",
                "created_at");
    }

    private void assertLatestEventTextDoesNotContain(String... forbiddenText) {
        var event = jdbcTemplate.queryForMap("select * from translation_events");
        assertThat(event.toString()).doesNotContain(forbiddenText);
    }

    private void assertNoRoute(String path) {
        var mappedPaths = requestMappingHandlerMapping.getHandlerMethods().keySet().stream()
                .flatMap(mappingInfo -> mappingInfo.getDirectPaths().stream())
                .toList();

        assertThat(mappedPaths).doesNotContain(path);
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

    private HttpResponse<String> postWithToken(String path, String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
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
