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
class AddDailyStatsEndpointTest {

    private static final LocalDate STAT_DATE = LocalDate.of(2026, 5, 5);

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = postDailyStatsWithoutToken(validStatsJson(STAT_DATE, 12, 8, 3, 2, 5));

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void firstAuthenticatedRequestCreatesDailyStatsAndReturnsTotals() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-create@example.com");

        var response = postDailyStats(accessToken, validStatsJson(STAT_DATE, 12, 8, 3, 2, 5));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseBody = response.body();
        var responseJson = objectMapper.readTree(responseBody);
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/statDate").asText()).isEqualTo("2026-05-05");
        assertThat(responseJson.at("/data/readingMinutes").asInt()).isEqualTo(12);
        assertThat(responseJson.at("/data/lookupCount").asInt()).isEqualTo(8);
        assertThat(responseJson.at("/data/paragraphTranslationCount").asInt()).isEqualTo(3);
        assertThat(responseJson.at("/data/cardsCreated").asInt()).isEqualTo(2);
        assertThat(responseJson.at("/data/cardsReviewed").asInt()).isEqualTo(5);
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertNoRawContentFields(responseBody);

        var row = findStatsRow("stats-create@example.com", STAT_DATE);
        assertThat(row.readingMinutes()).isEqualTo(12);
        assertThat(row.lookupCount()).isEqualTo(8);
        assertThat(row.paragraphTranslationCount()).isEqualTo(3);
        assertThat(row.cardsCreated()).isEqualTo(2);
        assertThat(row.cardsReviewed()).isEqualTo(5);
    }

    @Test
    void secondRequestForSameDateIncrementsExistingTotals() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-increment@example.com");
        postDailyStats(accessToken, validStatsJson(STAT_DATE, 12, 8, 3, 2, 5));

        var response = postDailyStats(accessToken, validStatsJson(STAT_DATE, 7, 4, 2, 1, 6));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/readingMinutes").asInt()).isEqualTo(19);
        assertThat(responseJson.at("/data/lookupCount").asInt()).isEqualTo(12);
        assertThat(responseJson.at("/data/paragraphTranslationCount").asInt()).isEqualTo(5);
        assertThat(responseJson.at("/data/cardsCreated").asInt()).isEqualTo(3);
        assertThat(responseJson.at("/data/cardsReviewed").asInt()).isEqualTo(11);

        var rowCount = jdbcTemplate.queryForObject(
                """
                        select count(*)
                        from study_daily_stats stat
                        join users user_account on user_account.id = stat.user_id
                        where user_account.email = ? and stat.stat_date = ?
                        """,
                Integer.class,
                "stats-increment@example.com",
                STAT_DATE);
        assertThat(rowCount).isEqualTo(1);
    }

    @Test
    void sameDateStatsAreIsolatedBetweenUsers() throws Exception {
        var firstToken = registerAndGetAccessToken("stats-first@example.com");
        var secondToken = registerAndGetAccessToken("stats-second@example.com");

        postDailyStats(firstToken, validStatsJson(STAT_DATE, 12, 8, 3, 2, 5));
        var response = postDailyStats(secondToken, validStatsJson(STAT_DATE, 1, 1, 1, 1, 1));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/readingMinutes").asInt()).isEqualTo(1);
        assertThat(responseJson.at("/data/lookupCount").asInt()).isEqualTo(1);
        assertThat(findStatsRow("stats-first@example.com", STAT_DATE).readingMinutes()).isEqualTo(12);
        assertThat(findStatsRow("stats-second@example.com", STAT_DATE).readingMinutes()).isEqualTo(1);
    }

    @Test
    void missingStatDateReturnsValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-missing-date@example.com");

        var response = postDailyStats(accessToken, """
                {
                  "readingMinutes": 12,
                  "lookupCount": 8,
                  "paragraphTranslationCount": 3,
                  "cardsCreated": 2,
                  "cardsReviewed": 5
                }
                """);

        assertValidationError(response);
    }

    @Test
    void negativeCounterReturnsValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-negative@example.com");

        for (var fieldName : new String[] {
                "readingMinutes",
                "lookupCount",
                "paragraphTranslationCount",
                "cardsCreated",
                "cardsReviewed"
        }) {
            var response = postDailyStats(accessToken, """
                    {
                      "statDate": "2026-05-05",
                      "readingMinutes": 0,
                      "lookupCount": 0,
                      "paragraphTranslationCount": 0,
                      "cardsCreated": 0,
                      "cardsReviewed": 0,
                      "%s": -1
                    }
                    """.formatted(fieldName));

            assertValidationError(response);
        }
    }

    @Test
    void integerOverflowReturnsValidationError() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-overflow@example.com");
        var userId = findUserId("stats-overflow@example.com");
        insertStatsRow(userId, STAT_DATE, Integer.MAX_VALUE, 0, 0, 0, 0);

        var response = postDailyStats(accessToken, validStatsJson(STAT_DATE, 1, 0, 0, 0, 0));

        assertValidationError(response);
        assertThat(findStatsRow("stats-overflow@example.com", STAT_DATE).readingMinutes())
                .isEqualTo(Integer.MAX_VALUE);
    }

    @Test
    void responseBodyDoesNotContainRawContentFields() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-no-raw-fields@example.com");

        var response = postDailyStats(accessToken, validStatsJson(STAT_DATE, 0, 0, 0, 0, 0));

        assertThat(response.statusCode()).isEqualTo(200);
        assertNoRawContentFields(response.body());
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

    private String validStatsJson(
            LocalDate statDate,
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
        return """
                {
                  "statDate": "%s",
                  "readingMinutes": %d,
                  "lookupCount": %d,
                  "paragraphTranslationCount": %d,
                  "cardsCreated": %d,
                  "cardsReviewed": %d
                }
                """.formatted(
                statDate,
                readingMinutes,
                lookupCount,
                paragraphTranslationCount,
                cardsCreated,
                cardsReviewed);
    }

    private void assertValidationError(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    private void assertNoRawContentFields(String responseBody) {
        assertThat(responseBody).doesNotContain("content");
        assertThat(responseBody).doesNotContain("chapterContent");
        assertThat(responseBody).doesNotContain("originalFile");
        assertThat(responseBody).doesNotContain("filePath");
        assertThat(responseBody).doesNotContain("sourceText");
        assertThat(responseBody).doesNotContain("rawText");
        assertThat(responseBody).doesNotContain("translatedText");
        assertThat(responseBody).doesNotContain("paragraphText");
    }

    private StatsRow findStatsRow(String email, LocalDate statDate) {
        return jdbcTemplate.queryForObject(
                """
                        select
                            stat.reading_minutes,
                            stat.lookup_count,
                            stat.paragraph_translation_count,
                            stat.cards_created,
                            stat.cards_reviewed
                        from study_daily_stats stat
                        join users user_account on user_account.id = stat.user_id
                        where user_account.email = ? and stat.stat_date = ?
                        """,
                (rs, rowNum) -> new StatsRow(
                        rs.getInt("reading_minutes"),
                        rs.getInt("lookup_count"),
                        rs.getInt("paragraph_translation_count"),
                        rs.getInt("cards_created"),
                        rs.getInt("cards_reviewed")),
                email,
                statDate);
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

    private HttpResponse<String> postDailyStats(String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/stats/daily".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postDailyStatsWithoutToken(String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/stats/daily".formatted(port)))
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

    private record StatsRow(
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
    }
}
