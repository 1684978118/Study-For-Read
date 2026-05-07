package com.studyforread.server.stats;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDate;
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
class StudySummaryEndpointTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = getSummaryWithoutToken();

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void authenticatedUserWithNoStatsReceivesZeroTotals() throws Exception {
        var accessToken = registerAndGetAccessToken("summary-empty@example.com");

        var response = getSummary(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/readingMinutes").asLong()).isEqualTo(0);
        assertThat(responseJson.at("/data/lookupCount").asLong()).isEqualTo(0);
        assertThat(responseJson.at("/data/paragraphTranslationCount").asLong()).isEqualTo(0);
        assertThat(responseJson.at("/data/cardsCreated").asLong()).isEqualTo(0);
        assertThat(responseJson.at("/data/cardsReviewed").asLong()).isEqualTo(0);
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertNoForbiddenFields(response.body());
    }

    @Test
    void authenticatedUserReceivesTotalsSummedAcrossAllDailyRows() throws Exception {
        var accessToken = registerAndGetAccessToken("summary-total@example.com");
        var userId = findUserId("summary-total@example.com");
        insertStatsRow(userId, LocalDate.of(2026, 5, 1), 12, 8, 3, 2, 5);
        insertStatsRow(userId, LocalDate.of(2026, 5, 2), 7, 4, 2, 1, 6);

        var response = getSummary(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/readingMinutes").asLong()).isEqualTo(19);
        assertThat(responseJson.at("/data/lookupCount").asLong()).isEqualTo(12);
        assertThat(responseJson.at("/data/paragraphTranslationCount").asLong()).isEqualTo(5);
        assertThat(responseJson.at("/data/cardsCreated").asLong()).isEqualTo(3);
        assertThat(responseJson.at("/data/cardsReviewed").asLong()).isEqualTo(11);
        assertNoForbiddenFields(response.body());
    }

    @Test
    void summaryExcludesOtherUsersStats() throws Exception {
        var firstToken = registerAndGetAccessToken("summary-first@example.com");
        var secondToken = registerAndGetAccessToken("summary-second@example.com");
        insertStatsRow(findUserId("summary-first@example.com"), LocalDate.of(2026, 5, 1), 12, 8, 3, 2, 5);
        insertStatsRow(findUserId("summary-second@example.com"), LocalDate.of(2026, 5, 1), 100, 100, 100, 100, 100);

        var firstResponse = getSummary(firstToken);
        var secondResponse = getSummary(secondToken);

        assertThat(firstResponse.statusCode()).isEqualTo(200);
        assertThat(secondResponse.statusCode()).isEqualTo(200);
        var firstJson = objectMapper.readTree(firstResponse.body());
        var secondJson = objectMapper.readTree(secondResponse.body());
        assertThat(firstJson.at("/data/readingMinutes").asLong()).isEqualTo(12);
        assertThat(firstJson.at("/data/lookupCount").asLong()).isEqualTo(8);
        assertThat(secondJson.at("/data/readingMinutes").asLong()).isEqualTo(100);
        assertThat(secondJson.at("/data/lookupCount").asLong()).isEqualTo(100);
    }

    @Test
    void responseBodyDoesNotContainDateUserOrRawContentFields() throws Exception {
        var accessToken = registerAndGetAccessToken("summary-fields@example.com");
        insertStatsRow(findUserId("summary-fields@example.com"), LocalDate.of(2026, 5, 1), 1, 1, 1, 1, 1);

        var response = getSummary(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        assertNoForbiddenFields(response.body());
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

    private UUID findUserId(String email) {
        return jdbcTemplate.queryForObject(
                "select id from users where email = ?",
                UUID.class,
                email);
    }

    private void insertStatsRow(
            UUID userId,
            LocalDate statDate,
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
        jdbcTemplate.update(
                """
                        insert into study_daily_stats (
                            id,
                            user_id,
                            stat_date,
                            reading_minutes,
                            lookup_count,
                            paragraph_translation_count,
                            cards_created,
                            cards_reviewed
                        ) values (
                            random_uuid(),
                            ?,
                            ?,
                            ?,
                            ?,
                            ?,
                            ?,
                            ?
                        )
                        """,
                userId,
                statDate,
                readingMinutes,
                lookupCount,
                paragraphTranslationCount,
                cardsCreated,
                cardsReviewed);
    }

    private HttpResponse<String> getSummary(String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/stats/summary".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> getSummaryWithoutToken() throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/stats/summary".formatted(port)))
                .GET()
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

    private void assertNoForbiddenFields(String responseBody) {
        assertThat(responseBody).doesNotContain("statDate");
        assertThat(responseBody).doesNotContain("userId");
        assertThat(responseBody).doesNotContain("content");
        assertThat(responseBody).doesNotContain("chapterContent");
        assertThat(responseBody).doesNotContain("originalFile");
        assertThat(responseBody).doesNotContain("filePath");
        assertThat(responseBody).doesNotContain("sourceText");
        assertThat(responseBody).doesNotContain("rawText");
        assertThat(responseBody).doesNotContain("translatedText");
        assertThat(responseBody).doesNotContain("paragraphText");
    }
}
