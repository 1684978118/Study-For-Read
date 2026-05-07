package com.studyforread.server.vocabulary;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.OffsetDateTime;
import java.util.ArrayList;
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
class ListDueVocabularyCardsEndpointTest {

    private static final String SOURCE_BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void returnsNewCardsAndPastReviewCardsButExcludesFutureReviewCards() throws Exception {
        var accessToken = registerAndGetAccessToken("due-card-owner@example.com");
        var newLexemeId = insertLexeme("kokoro", "kokoro", "heart; mind");
        var pastLexemeId = insertLexeme("hashiru", "hashiru", "to run");
        var futureLexemeId = insertLexeme("miru", "miru", "to see");
        var newCardId = createLexemeCard(accessToken, newLexemeId);
        var pastCardId = createLexemeCard(accessToken, pastLexemeId);
        var futureCardId = createLexemeCard(accessToken, futureLexemeId);
        updateNextReviewAt(pastCardId, OffsetDateTime.now().minusDays(1));
        updateNextReviewAt(futureCardId, OffsetDateTime.now().plusDays(1));

        var response = getDueCards(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertThat(responseJson.at("/data/items")).hasSize(2);
        assertThat(itemIds(responseJson.at("/data/items")))
                .containsExactlyInAnyOrder(newCardId.toString(), pastCardId.toString())
                .doesNotContain(futureCardId.toString());
    }

    @Test
    void returnsOnlyCurrentUsersDueCards() throws Exception {
        var currentAccessToken = registerAndGetAccessToken("current-due-owner@example.com");
        var otherAccessToken = registerAndGetAccessToken("other-due-owner@example.com");
        var lexemeId = insertLexeme("yume", "yume", "dream");
        var currentCardId = createLexemeCard(currentAccessToken, lexemeId);
        var otherCardId = createLexemeCard(otherAccessToken, lexemeId);
        jdbcTemplate.update(
                "update user_word_cards set review_status = 'known', review_count = 9 where id = ?",
                otherCardId);

        var response = getDueCards(currentAccessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/items")).hasSize(1);
        assertThat(responseJson.at("/data/items/0/id").asText()).isEqualTo(currentCardId.toString());
        assertThat(responseJson.at("/data/items/0/reviewStatus").asText()).isEqualTo("new");
        assertThat(responseJson.at("/data/items/0/reviewCount").asInt()).isZero();
    }

    @Test
    void lexemeCardsIncludePublicLexemeFields() throws Exception {
        var accessToken = registerAndGetAccessToken("due-lexeme-owner@example.com");
        var lexemeId = insertLexeme("asa", "asa", "morning");
        createLexemeCard(accessToken, lexemeId);

        var response = getDueCards(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        var item = responseJson.at("/data/items/0");
        assertThat(item.at("/cardType").asText()).isEqualTo("lexeme");
        assertThat(item.at("/surface").asText()).isEqualTo("asa");
        assertThat(item.at("/reading").asText()).isEqualTo("asa");
        assertThat(item.at("/definition").asText()).isEqualTo("morning");
        assertThat(item.at("/lexeme/id").asText()).isEqualTo(lexemeId.toString());
        assertThat(item.at("/lexeme/surface").asText()).isEqualTo("asa");
        assertThat(item.at("/lexeme/reading").asText()).isEqualTo("asa");
        assertThat(item.at("/lexeme/definition").asText()).isEqualTo("morning");
        assertThat(item.at("/reviewStatus").asText()).isEqualTo("new");
        assertThat(item.at("/reviewCount").asInt()).isZero();
        assertThat(item.at("/nextReviewAt").isNull()).isTrue();
    }

    @Test
    void privateSentenceCardsIncludeOnlyOwningUsersPrivateFields() throws Exception {
        var currentAccessToken = registerAndGetAccessToken("current-private-due-owner@example.com");
        var otherAccessToken = registerAndGetAccessToken("other-private-due-owner@example.com");
        var currentCardId = createPrivateSentenceCard(currentAccessToken, "current private surface", "current definition");
        createPrivateSentenceCard(otherAccessToken, "other private surface", "other definition");

        var response = getDueCards(currentAccessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/data/items")).hasSize(1);
        var item = responseJson.at("/data/items/0");
        assertThat(item.at("/id").asText()).isEqualTo(currentCardId.toString());
        assertThat(item.at("/cardType").asText()).isEqualTo("private_sentence");
        assertThat(item.at("/lexeme").isNull()).isTrue();
        assertThat(item.at("/surface").asText()).isEqualTo("current private surface");
        assertThat(item.at("/definition").asText()).isEqualTo("current definition");
        assertThat(item.at("/privateSurface").asText()).isEqualTo("current private surface");
        assertThat(item.at("/privateDefinition").asText()).isEqualTo("current definition");
        assertThat(response.body()).doesNotContain("other private surface", "other definition");
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards/due".formatted(port)))
                .GET()
                .build();

        var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("UNAUTHORIZED");
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

    private void updateNextReviewAt(UUID cardId, OffsetDateTime nextReviewAt) {
        jdbcTemplate.update("update user_word_cards set next_review_at = ? where id = ?", nextReviewAt, cardId);
    }

    private ArrayList<String> itemIds(com.fasterxml.jackson.databind.JsonNode items) {
        var ids = new ArrayList<String>();
        items.forEach(item -> ids.add(item.at("/id").asText()));
        return ids;
    }

    private HttpResponse<String> getDueCards(String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards/due".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
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
