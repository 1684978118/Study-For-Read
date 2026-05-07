package com.studyforread.server.stats;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.DatabaseMetaData;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class StudyStatsBoundaryRegressionTest {

    private static final LocalDate STAT_DATE = LocalDate.of(2026, 5, 5);
    private static final Set<String> FORBIDDEN_RESPONSE_FIELDS = Set.of(
            "content",
            "chapterContent",
            "originalFile",
            "filePath",
            "sourceText",
            "rawText",
            "translatedText",
            "paragraphText");
    private static final Set<String> FORBIDDEN_DATABASE_COLUMNS = Set.of(
            "content",
            "chapter_content",
            "original_file",
            "file_path",
            "source_text",
            "raw_text",
            "translated_text",
            "paragraph_text");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private DataSource dataSource;

    @Value("${local.server.port}")
    private int port;

    @Test
    void studyDailyStatsTableDoesNotContainRawContentColumns() throws Exception {
        try (var connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            var columns = metaData.getColumns(null, null, "study_daily_stats", null);
            while (columns.next()) {
                assertThat(columns.getString("COLUMN_NAME").toLowerCase()).isNotIn(FORBIDDEN_DATABASE_COLUMNS);
            }
        }
    }

    @Test
    void dailyStatsEndpointIgnoresRequestUserIdAndOnlyIncrementsCurrentUser() throws Exception {
        var firstToken = registerAndGetAccessToken("stats-boundary-first@example.com");
        var firstUserId = findUserId("stats-boundary-first@example.com");
        var secondUserId = registerAndGetUserId("stats-boundary-second@example.com");
        insertStatsRow(secondUserId, STAT_DATE, 100, 100, 100, 100, 100);

        var response = postDailyStats(firstToken, """
                {
                  "userId": "%s",
                  "statDate": "2026-05-05",
                  "readingMinutes": 1,
                  "lookupCount": 2,
                  "paragraphTranslationCount": 3,
                  "cardsCreated": 4,
                  "cardsReviewed": 5
                }
                """.formatted(secondUserId));

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(findStatsRow(firstUserId, STAT_DATE))
                .isEqualTo(new StatsRow(1, 2, 3, 4, 5));
        assertThat(findStatsRow(secondUserId, STAT_DATE))
                .isEqualTo(new StatsRow(100, 100, 100, 100, 100));
        assertNoForbiddenResponseFields(response.body());
    }

    @Test
    void summaryEndpointOnlyAggregatesCurrentUserRows() throws Exception {
        var firstToken = registerAndGetAccessToken("stats-summary-boundary-first@example.com");
        var firstUserId = findUserId("stats-summary-boundary-first@example.com");
        var secondUserId = registerAndGetUserId("stats-summary-boundary-second@example.com");
        insertStatsRow(firstUserId, LocalDate.of(2026, 5, 4), 10, 20, 30, 40, 50);
        insertStatsRow(firstUserId, LocalDate.of(2026, 5, 5), 1, 2, 3, 4, 5);
        insertStatsRow(secondUserId, LocalDate.of(2026, 5, 5), 100, 100, 100, 100, 100);

        var response = getSummary(firstToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/readingMinutes").asLong()).isEqualTo(11);
        assertThat(responseJson.at("/data/lookupCount").asLong()).isEqualTo(22);
        assertThat(responseJson.at("/data/paragraphTranslationCount").asLong()).isEqualTo(33);
        assertThat(responseJson.at("/data/cardsCreated").asLong()).isEqualTo(44);
        assertThat(responseJson.at("/data/cardsReviewed").asLong()).isEqualTo(55);
        assertNoForbiddenResponseFields(response.body());
    }

    @Test
    void allCounterFieldsRejectNegativeValuesThroughApi() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-negative-boundary@example.com");

        for (var fieldName : new String[] {
                "readingMinutes",
                "lookupCount",
                "paragraphTranslationCount",
                "cardsCreated",
                "cardsReviewed"
        }) {
            var response = postDailyStats(accessToken, dailyStatsJsonWith(fieldName, -1));

            assertThat(response.statusCode()).isEqualTo(400);
            var responseJson = objectMapper.readTree(response.body());
            assertThat(responseJson.at("/success").asBoolean()).isFalse();
            assertThat(responseJson.at("/data").isNull()).isTrue();
            assertThat(responseJson.at("/error/code").asText()).isEqualTo("VALIDATION_ERROR");
        }
    }

    @Test
    void allCounterFieldsRejectNegativeValuesThroughDatabaseConstraints() throws Exception {
        var userId = registerAndGetUserId("stats-db-negative-boundary@example.com");

        for (var fieldName : new String[] {
                "reading_minutes",
                "lookup_count",
                "paragraph_translation_count",
                "cards_created",
                "cards_reviewed"
        }) {
            assertThatThrownBy(() -> insertStatsRowWithNegativeField(userId, fieldName))
                    .isInstanceOf(DataIntegrityViolationException.class);
        }
    }

    @Test
    void dailyAndSummaryResponsesDoNotContainRawContentFields() throws Exception {
        var accessToken = registerAndGetAccessToken("stats-response-boundary@example.com");

        var dailyResponse = postDailyStats(accessToken, validDailyStatsJson(3, 4, 5, 6, 7));
        var summaryResponse = getSummary(accessToken);

        assertThat(dailyResponse.statusCode()).isEqualTo(200);
        assertThat(summaryResponse.statusCode()).isEqualTo(200);
        assertNoForbiddenResponseFields(dailyResponse.body());
        assertNoForbiddenResponseFields(summaryResponse.body());
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

    private UUID registerAndGetUserId(String email) throws Exception {
        registerAndGetAccessToken(email);
        return findUserId(email);
    }

    private UUID findUserId(String email) {
        return jdbcTemplate.queryForObject(
                "select id from users where email = ?",
                UUID.class,
                email);
    }

    private StatsRow findStatsRow(UUID userId, LocalDate statDate) {
        return jdbcTemplate.queryForObject(
                """
                        select
                            reading_minutes,
                            lookup_count,
                            paragraph_translation_count,
                            cards_created,
                            cards_reviewed
                        from study_daily_stats
                        where user_id = ? and stat_date = ?
                        """,
                (rs, rowNum) -> new StatsRow(
                        rs.getInt("reading_minutes"),
                        rs.getInt("lookup_count"),
                        rs.getInt("paragraph_translation_count"),
                        rs.getInt("cards_created"),
                        rs.getInt("cards_reviewed")),
                userId,
                statDate);
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

    private void insertStatsRowWithNegativeField(UUID userId, String negativeFieldName) {
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
                STAT_DATE.plusDays(negativeFieldName.hashCode() & 1023),
                valueForField("reading_minutes", negativeFieldName),
                valueForField("lookup_count", negativeFieldName),
                valueForField("paragraph_translation_count", negativeFieldName),
                valueForField("cards_created", negativeFieldName),
                valueForField("cards_reviewed", negativeFieldName));
    }

    private int valueForField(String fieldName, String negativeFieldName) {
        return fieldName.equals(negativeFieldName) ? -1 : 0;
    }

    private String dailyStatsJsonWith(String negativeFieldName, int value) {
        return """
                {
                  "statDate": "2026-05-05",
                  "readingMinutes": %d,
                  "lookupCount": %d,
                  "paragraphTranslationCount": %d,
                  "cardsCreated": %d,
                  "cardsReviewed": %d
                }
                """.formatted(
                "readingMinutes".equals(negativeFieldName) ? value : 0,
                "lookupCount".equals(negativeFieldName) ? value : 0,
                "paragraphTranslationCount".equals(negativeFieldName) ? value : 0,
                "cardsCreated".equals(negativeFieldName) ? value : 0,
                "cardsReviewed".equals(negativeFieldName) ? value : 0);
    }

    private String validDailyStatsJson(
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
        return """
                {
                  "statDate": "2026-05-05",
                  "readingMinutes": %d,
                  "lookupCount": %d,
                  "paragraphTranslationCount": %d,
                  "cardsCreated": %d,
                  "cardsReviewed": %d
                }
                """.formatted(
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

    private HttpResponse<String> getSummary(String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/stats/summary".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
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

    private void assertNoForbiddenResponseFields(String responseBody) {
        for (var fieldName : FORBIDDEN_RESPONSE_FIELDS) {
            assertThat(responseBody).doesNotContain(fieldName);
        }
    }

    private record StatsRow(
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
    }
}
