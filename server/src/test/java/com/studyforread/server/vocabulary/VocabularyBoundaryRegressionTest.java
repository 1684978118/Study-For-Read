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
class VocabularyBoundaryRegressionTest {

    private static final String SOURCE_BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void lexemesTableDoesNotStoreUserReviewStateColumns() {
        var columnNames = jdbcTemplate.queryForList(
                """
                        select lower(column_name)
                        from information_schema.columns
                        where lower(table_name) = 'lexemes'
                        """,
                String.class);

        assertThat(columnNames)
                .doesNotContain("review_status", "review_count", "next_review_at", "last_reviewed_at");
    }

    @Test
    void creatingPrivateSentenceCardDoesNotInsertPublicLexeme() throws Exception {
        var accessToken = registerAndGetAccessToken("private-boundary-owner@example.com");
        var lexemeCountBefore = countLexemes();

        var response = postCard(accessToken, privateSentenceJson(
                "owner private surface",
                "owner private definition",
                "owner private context"));

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(countLexemes()).isEqualTo(lexemeCountBefore);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/cardType").asText()).isEqualTo("private_sentence");
        assertThat(responseJson.at("/data/lexeme").isNull()).isTrue();
    }

    @Test
    void lexemeCardStoresReviewStateOnUserWordCardsNotLexemes() throws Exception {
        var accessToken = registerAndGetAccessToken("lexeme-review-boundary-owner@example.com");
        var lexemeId = insertLexeme("kokoro", "kokoro", "heart; mind");

        var cardId = createLexemeCard(accessToken, lexemeId);

        var cardReviewState = jdbcTemplate.queryForMap(
                "select review_status, review_count, next_review_at, last_reviewed_at from user_word_cards where id = ?",
                cardId);
        assertThat(cardReviewState.get("REVIEW_STATUS")).isEqualTo("new");
        assertThat(cardReviewState.get("REVIEW_COUNT")).isEqualTo(0);
        assertThat(cardReviewState.get("NEXT_REVIEW_AT")).isNull();
        assertThat(cardReviewState.get("LAST_REVIEWED_AT")).isNull();

        var lexemeColumns = jdbcTemplate.queryForList(
                """
                        select lower(column_name)
                        from information_schema.columns
                        where lower(table_name) = 'lexemes'
                        """,
                String.class);
        assertThat(lexemeColumns)
                .doesNotContain("review_status", "review_count", "next_review_at", "last_reviewed_at");
    }

    @Test
    void dueEndpointDoesNotExposeAnotherUsersCards() throws Exception {
        var currentAccessToken = registerAndGetAccessToken("current-due-boundary-owner@example.com");
        var otherAccessToken = registerAndGetAccessToken("other-due-boundary-owner@example.com");
        var currentCardId = createPrivateSentenceCard(
                currentAccessToken,
                "current due surface",
                "current due definition",
                "current due context");
        var otherCardId = createPrivateSentenceCard(
                otherAccessToken,
                "other due surface",
                "other due definition",
                "other due context");

        var response = getDueCards(currentAccessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/items")).hasSize(1);
        assertThat(responseJson.at("/data/items/0/id").asText()).isEqualTo(currentCardId.toString());
        assertThat(response.body())
                .contains("current due surface", "current due definition")
                .doesNotContain(otherCardId.toString(), "other due surface", "other due definition", "other due context");
    }

    @Test
    void userCannotReviewAnotherUsersCard() throws Exception {
        var ownerAccessToken = registerAndGetAccessToken("review-boundary-owner@example.com");
        var otherAccessToken = registerAndGetAccessToken("review-boundary-other@example.com");
        var cardId = createPrivateSentenceCard(
                ownerAccessToken,
                "review owner surface",
                "review owner definition",
                "review owner context");

        var response = reviewCard(
                otherAccessToken,
                cardId,
                true,
                OffsetDateTime.parse("2026-05-05T12:30:00Z"));

        assertThat(response.statusCode()).isEqualTo(404);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("WORD_CARD_NOT_FOUND");
        assertStoredReviewCount(cardId, 0);
    }

    @Test
    void privateSentenceFieldsAreOnlyVisibleToOwningUser() throws Exception {
        var ownerAccessToken = registerAndGetAccessToken("private-field-owner@example.com");
        var otherAccessToken = registerAndGetAccessToken("private-field-other@example.com");
        var ownerCardId = createPrivateSentenceCard(
                ownerAccessToken,
                "owner visible surface",
                "owner visible definition",
                "owner private context should not leak");
        createPrivateSentenceCard(
                otherAccessToken,
                "other hidden surface",
                "other hidden definition",
                "other hidden context");

        var ownerResponse = getDueCards(ownerAccessToken);
        var otherResponse = getDueCards(otherAccessToken);

        assertThat(ownerResponse.statusCode()).isEqualTo(200);
        assertThat(otherResponse.statusCode()).isEqualTo(200);
        assertThat(ownerResponse.body())
                .contains(ownerCardId.toString(), "owner visible surface", "owner visible definition")
                .doesNotContain("other hidden surface", "other hidden definition", "other hidden context");
        assertThat(otherResponse.body())
                .contains("other hidden surface", "other hidden definition")
                .doesNotContain(ownerCardId.toString(), "owner visible surface", "owner visible definition",
                        "owner private context should not leak");
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

    private UUID createPrivateSentenceCard(
            String accessToken,
            String privateSurface,
            String privateDefinition,
            String privateContext) throws Exception {
        var response = postCard(accessToken, privateSentenceJson(privateSurface, privateDefinition, privateContext));

        assertThat(response.statusCode()).isEqualTo(200);
        return UUID.fromString(objectMapper.readTree(response.body()).at("/data/id").asText());
    }

    private String privateSentenceJson(String privateSurface, String privateDefinition, String privateContext) {
        return """
                {
                  "cardType": "private_sentence",
                  "privateSurface": "%s",
                  "privateDefinition": "%s",
                  "privateContext": "%s",
                  "sourceBookFingerprint": "%s",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(privateSurface, privateDefinition, privateContext, SOURCE_BOOK_FINGERPRINT);
    }

    private void assertStoredReviewCount(UUID cardId, int reviewCount) {
        assertThat(jdbcTemplate.queryForObject(
                "select review_count from user_word_cards where id = ?",
                Integer.class,
                cardId)).isEqualTo(reviewCount);
    }

    private int countLexemes() {
        return jdbcTemplate.queryForObject("select count(*) from lexemes", Integer.class);
    }

    private HttpResponse<String> getDueCards(String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards/due".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> reviewCard(
            String accessToken,
            UUID cardId,
            boolean known,
            OffsetDateTime reviewedAt) throws Exception {
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
