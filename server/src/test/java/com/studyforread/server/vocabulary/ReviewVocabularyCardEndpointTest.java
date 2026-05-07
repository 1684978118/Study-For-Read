package com.studyforread.server.vocabulary;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.OffsetDateTime;
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
class ReviewVocabularyCardEndpointTest {

    private static final String SOURCE_BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void reviewingNewCardAsKnownSchedulesThreeDaysLater() throws Exception {
        var accessToken = registerAndGetAccessToken("known-first-reviewer@example.com");
        var cardId = createLexemeCard(accessToken, insertLexeme("kokoro", "kokoro", "heart; mind"));
        var reviewedAt = OffsetDateTime.parse("2026-05-05T12:30:00Z");

        var response = reviewCard(accessToken, cardId, true, reviewedAt);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertReviewState(responseJson.at("/data"), cardId, 1, reviewedAt, reviewedAt.plusDays(3));
        assertStoredReviewState(cardId, 1, reviewedAt, reviewedAt.plusDays(3));
    }

    @Test
    void repeatedKnownReviewsAdvanceToSevenFifteenAndThirtyDays() throws Exception {
        var accessToken = registerAndGetAccessToken("known-repeated-reviewer@example.com");
        var cardId = createLexemeCard(accessToken, insertLexeme("hashiru", "hashiru", "to run"));
        var firstReview = OffsetDateTime.parse("2026-05-05T12:30:00Z");
        var secondReview = OffsetDateTime.parse("2026-05-08T12:30:00Z");
        var thirdReview = OffsetDateTime.parse("2026-05-15T12:30:00Z");
        var fourthReview = OffsetDateTime.parse("2026-05-30T12:30:00Z");

        reviewCard(accessToken, cardId, true, firstReview);
        var secondResponse = reviewCard(accessToken, cardId, true, secondReview);
        var thirdResponse = reviewCard(accessToken, cardId, true, thirdReview);
        var fourthResponse = reviewCard(accessToken, cardId, true, fourthReview);

        assertReviewState(objectMapper.readTree(secondResponse.body()).at("/data"), cardId, 2, secondReview, secondReview.plusDays(7));
        assertReviewState(objectMapper.readTree(thirdResponse.body()).at("/data"), cardId, 3, thirdReview, thirdReview.plusDays(15));
        assertReviewState(objectMapper.readTree(fourthResponse.body()).at("/data"), cardId, 4, fourthReview, fourthReview.plusDays(30));
        assertStoredReviewState(cardId, 4, fourthReview, fourthReview.plusDays(30));
    }

    @Test
    void reviewingAnyCardAsUnknownSchedulesOneDayLater() throws Exception {
        var accessToken = registerAndGetAccessToken("unknown-reviewer@example.com");
        var cardId = createPrivateSentenceCard(accessToken, "private surface", "private definition");
        var reviewedAt = OffsetDateTime.parse("2026-06-01T08:15:00Z");
        jdbcTemplate.update(
                "update user_word_cards set review_status = 'known', review_count = 5 where id = ?",
                cardId);

        var response = reviewCard(accessToken, cardId, false, reviewedAt);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertReviewState(responseJson.at("/data"), cardId, 6, reviewedAt, reviewedAt.plusDays(1));
        assertStoredReviewState(cardId, 6, reviewedAt, reviewedAt.plusDays(1));
    }

    @Test
    void missingCardReturnsWordCardNotFound() throws Exception {
        var accessToken = registerAndGetAccessToken("missing-card-reviewer@example.com");

        var response = reviewCard(accessToken, UUID.randomUUID(), true, OffsetDateTime.parse("2026-05-05T12:30:00Z"));

        assertWordCardNotFound(response);
    }

    @Test
    void userCannotReviewAnotherUsersCard() throws Exception {
        var ownerAccessToken = registerAndGetAccessToken("review-card-owner@example.com");
        var otherAccessToken = registerAndGetAccessToken("review-card-other-user@example.com");
        var cardId = createLexemeCard(ownerAccessToken, insertLexeme("yume", "yume", "dream"));

        var response = reviewCard(otherAccessToken, cardId, true, OffsetDateTime.parse("2026-05-05T12:30:00Z"));

        assertWordCardNotFound(response);
        assertStoredReviewCount(cardId, 0);
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards/%s/review"
                        .formatted(port, UUID.randomUUID())))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString("""
                        {
                          "known": true,
                          "reviewedAt": "2026-05-05T12:30:00Z"
                        }
                        """))
                .build();

        var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
    }

    private void assertReviewState(
            JsonNode data,
            UUID cardId,
            int reviewCount,
            OffsetDateTime lastReviewedAt,
            OffsetDateTime nextReviewAt) {
        assertThat(data.at("/id").asText()).isEqualTo(cardId.toString());
        assertThat(data.at("/reviewStatus").asText()).isEqualTo("learning");
        assertThat(data.at("/reviewCount").asInt()).isEqualTo(reviewCount);
        assertThat(OffsetDateTime.parse(data.at("/lastReviewedAt").asText())).isEqualTo(lastReviewedAt);
        assertThat(OffsetDateTime.parse(data.at("/nextReviewAt").asText())).isEqualTo(nextReviewAt);
    }

    private void assertStoredReviewState(
            UUID cardId,
            int reviewCount,
            OffsetDateTime lastReviewedAt,
            OffsetDateTime nextReviewAt) {
        var state = jdbcTemplate.queryForMap(
                "select review_status, review_count, last_reviewed_at, next_review_at from user_word_cards where id = ?",
                cardId);
        assertThat(state.get("REVIEW_STATUS")).isEqualTo("learning");
        assertThat(state.get("REVIEW_COUNT")).isEqualTo(reviewCount);
        assertThat(((OffsetDateTime) state.get("LAST_REVIEWED_AT")).toInstant()).isEqualTo(lastReviewedAt.toInstant());
        assertThat(((OffsetDateTime) state.get("NEXT_REVIEW_AT")).toInstant()).isEqualTo(nextReviewAt.toInstant());
    }

    private void assertStoredReviewCount(UUID cardId, int reviewCount) {
        assertThat(jdbcTemplate.queryForObject(
                "select review_count from user_word_cards where id = ?",
                Integer.class,
                cardId)).isEqualTo(reviewCount);
    }

    private void assertWordCardNotFound(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(404);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("WORD_CARD_NOT_FOUND");
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

    private UUID insertLexeme(String surface, String normalizedSurface, String definition) {
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
                        ) values (?, ?, ?, ?, 'ja', 'zh-CN', 'word', 'noun', ?, null, null, 'active', current_timestamp, current_timestamp)
                        """,
                id,
                surface,
                normalizedSurface,
                normalizedSurface,
                definition);
        return id;
    }

    private UUID createLexemeCard(String accessToken, UUID lexemeId) throws Exception {
        var response = postCard(accessToken, """
                {
                  "cardType": "lexeme",
                  "lexemeId": "%s",
                  "sourceBookFingerprint": "%s",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(lexemeId, SOURCE_BOOK_FINGERPRINT));

        assertThat(response.statusCode()).isEqualTo(200);
        return UUID.fromString(objectMapper.readTree(response.body()).at("/data/id").asText());
    }

    private UUID createPrivateSentenceCard(String accessToken, String privateSurface, String privateDefinition)
            throws Exception {
        var response = postCard(accessToken, """
                {
                  "cardType": "private_sentence",
                  "privateSurface": "%s",
                  "privateDefinition": "%s",
                  "privateContext": "User private sentence context",
                  "sourceBookFingerprint": "%s",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(privateSurface, privateDefinition, SOURCE_BOOK_FINGERPRINT));

        assertThat(response.statusCode()).isEqualTo(200);
        return UUID.fromString(objectMapper.readTree(response.body()).at("/data/id").asText());
    }

    private HttpResponse<String> reviewCard(String accessToken, UUID cardId, boolean known, OffsetDateTime reviewedAt)
            throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards/%s/review"
                        .formatted(port, cardId)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString("""
                        {
                          "known": %s,
                          "reviewedAt": "%s"
                        }
                        """.formatted(known, reviewedAt)))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> postCard(String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards".formatted(port)))
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
}
