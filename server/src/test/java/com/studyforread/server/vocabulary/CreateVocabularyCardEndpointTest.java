package com.studyforread.server.vocabulary;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
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
class CreateVocabularyCardEndpointTest {

    private static final String SOURCE_BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${local.server.port}")
    private int port;

    @Test
    void authenticatedUserCanCreateLexemeCardWithExistingLexemeId() throws Exception {
        var accessToken = registerAndGetAccessToken("lexeme-card-owner@example.com");
        var lexemeId = insertLexeme("kokoro", "kokoro", "heart; mind");

        var response = postCard(accessToken, lexemeCardJson(lexemeId));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/id").asText()).isNotBlank();
        assertThat(responseJson.at("/data/cardType").asText()).isEqualTo("lexeme");
        assertThat(responseJson.at("/data/lexeme/id").asText()).isEqualTo(lexemeId.toString());
        assertThat(responseJson.at("/data/lexeme/surface").asText()).isEqualTo("kokoro");
        assertThat(responseJson.at("/data/lexeme/reading").asText()).isEqualTo("kokoro");
        assertThat(responseJson.at("/data/lexeme/definition").asText()).isEqualTo("heart; mind");
        assertThat(responseJson.at("/data/reviewStatus").asText()).isEqualTo("new");
        assertThat(responseJson.at("/data/reviewCount").asInt()).isZero();
        assertThat(responseJson.at("/data/nextReviewAt").isNull()).isTrue();
        assertThat(responseJson.at("/error").isNull()).isTrue();
    }

    @Test
    void duplicateLexemeCardForSameUserReturnsExistingCardWithoutCreatingDuplicate() throws Exception {
        var accessToken = registerAndGetAccessToken("duplicate-lexeme-card-owner@example.com");
        var lexemeId = insertLexeme("hashiru", "hashiru", "to run");

        var firstResponse = postCard(accessToken, lexemeCardJson(lexemeId));
        var duplicateResponse = postCard(accessToken, lexemeCardJson(lexemeId));

        assertThat(firstResponse.statusCode()).isEqualTo(200);
        assertThat(duplicateResponse.statusCode()).isEqualTo(200);
        var firstJson = objectMapper.readTree(firstResponse.body());
        var duplicateJson = objectMapper.readTree(duplicateResponse.body());
        assertThat(duplicateJson.at("/data/id").asText()).isEqualTo(firstJson.at("/data/id").asText());
        assertThat(countCardsForEmailAndLexeme("duplicate-lexeme-card-owner@example.com", lexemeId)).isEqualTo(1);
    }

    @Test
    void differentUsersCanCreateTheirOwnCardsForSameLexeme() throws Exception {
        var firstAccessToken = registerAndGetAccessToken("first-lexeme-card-owner@example.com");
        var secondAccessToken = registerAndGetAccessToken("second-lexeme-card-owner@example.com");
        var lexemeId = insertLexeme("taberu", "taberu", "to eat");

        var firstResponse = postCard(firstAccessToken, lexemeCardJson(lexemeId));
        var secondResponse = postCard(secondAccessToken, lexemeCardJson(lexemeId));

        assertThat(firstResponse.statusCode()).isEqualTo(200);
        assertThat(secondResponse.statusCode()).isEqualTo(200);
        var firstJson = objectMapper.readTree(firstResponse.body());
        var secondJson = objectMapper.readTree(secondResponse.body());
        assertThat(secondJson.at("/data/id").asText()).isNotEqualTo(firstJson.at("/data/id").asText());
        assertThat(countCardsForLexeme(lexemeId)).isEqualTo(2);
    }

    @Test
    void lexemeCardMissingLexemeIdReturnsPrivateCardInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("missing-lexeme-id-owner@example.com");

        var response = postCard(accessToken, """
                {
                  "cardType": "lexeme",
                  "sourceBookFingerprint": "%s",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(SOURCE_BOOK_FINGERPRINT));

        assertPrivateCardInvalid(response);
    }

    @Test
    void lexemeCardWithUnknownLexemeIdReturnsLexemeNotFound() throws Exception {
        var accessToken = registerAndGetAccessToken("unknown-lexeme-owner@example.com");

        var response = postCard(accessToken, lexemeCardJson(UUID.randomUUID()));

        assertThat(response.statusCode()).isEqualTo(404);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("LEXEME_NOT_FOUND");
    }

    @Test
    void authenticatedUserCanCreatePrivateSentenceCardWithoutCreatingPublicLexeme() throws Exception {
        var accessToken = registerAndGetAccessToken("private-sentence-owner@example.com");
        var lexemeCountBefore = countLexemes();

        var response = postCard(accessToken, privateSentenceJson("心が静かになる。", "The heart becomes quiet."));

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/cardType").asText()).isEqualTo("private_sentence");
        assertThat(responseJson.at("/data/lexeme").isNull()).isTrue();
        assertThat(responseJson.at("/data/privateSurface").asText()).isEqualTo("心が静かになる。");
        assertThat(responseJson.at("/data/privateDefinition").asText()).isEqualTo("The heart becomes quiet.");
        assertThat(responseJson.at("/data/reviewStatus").asText()).isEqualTo("new");
        assertThat(responseJson.at("/data/reviewCount").asInt()).isZero();
        assertThat(countLexemes()).isEqualTo(lexemeCountBefore);
    }

    @Test
    void privateSentenceMissingSurfaceOrDefinitionReturnsPrivateCardInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("invalid-private-sentence-owner@example.com");

        var missingSurface = postCard(accessToken, privateSentenceJson("", "definition"));
        var missingDefinition = postCard(accessToken, privateSentenceJson("surface", "   "));

        assertPrivateCardInvalid(missingSurface);
        assertPrivateCardInvalid(missingDefinition);
    }

    @Test
    void invalidSourceBookFingerprintReturnsPrivateCardInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("invalid-card-fingerprint-owner@example.com");
        var lexemeId = insertLexeme("miru", "miru", "to see");

        var response = postCard(accessToken, """
                {
                  "cardType": "lexeme",
                  "lexemeId": "%s",
                  "sourceBookFingerprint": "not-a-sha-256-fingerprint",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(lexemeId));

        assertPrivateCardInvalid(response);
    }

    @Test
    void responseDoesNotExposeAnotherUsersReviewState() throws Exception {
        var otherAccessToken = registerAndGetAccessToken("other-review-state-owner@example.com");
        var currentAccessToken = registerAndGetAccessToken("current-review-state-owner@example.com");
        var lexemeId = insertLexeme("yume", "yume", "dream");
        var otherResponse = postCard(otherAccessToken, lexemeCardJson(lexemeId));
        var otherCardId = UUID.fromString(objectMapper.readTree(otherResponse.body()).at("/data/id").asText());
        jdbcTemplate.update(
                "update user_word_cards set review_status = 'known', review_count = 7 where id = ?",
                otherCardId);

        var currentResponse = postCard(currentAccessToken, lexemeCardJson(lexemeId));

        assertThat(currentResponse.statusCode()).isEqualTo(200);
        var currentJson = objectMapper.readTree(currentResponse.body());
        assertThat(currentJson.at("/data/id").asText()).isNotEqualTo(otherCardId.toString());
        assertThat(currentJson.at("/data/reviewStatus").asText()).isEqualTo("new");
        assertThat(currentJson.at("/data/reviewCount").asInt()).isZero();
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var lexemeId = insertLexeme("asa", "asa", "morning");

        var response = postCardWithoutToken(lexemeCardJson(lexemeId));

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

    private String lexemeCardJson(UUID lexemeId) {
        return """
                {
                  "cardType": "lexeme",
                  "lexemeId": "%s",
                  "sourceBookFingerprint": "%s",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(lexemeId, SOURCE_BOOK_FINGERPRINT);
    }

    private String privateSentenceJson(String privateSurface, String privateDefinition) {
        return """
                {
                  "cardType": "private_sentence",
                  "privateSurface": "%s",
                  "privateDefinition": "%s",
                  "privateContext": "User private sentence context",
                  "sourceBookFingerprint": "%s",
                  "sourceBookTitle": "Kokoro"
                }
                """.formatted(privateSurface, privateDefinition, SOURCE_BOOK_FINGERPRINT);
    }

    private void assertPrivateCardInvalid(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("PRIVATE_CARD_INVALID");
    }

    private int countCardsForEmailAndLexeme(String email, UUID lexemeId) {
        return jdbcTemplate.queryForObject(
                """
                        select count(*)
                        from user_word_cards card
                        join users user_account on user_account.id = card.user_id
                        where user_account.email = ? and card.lexeme_id = ?
                        """,
                Integer.class,
                email,
                lexemeId);
    }

    private int countCardsForLexeme(UUID lexemeId) {
        return jdbcTemplate.queryForObject(
                "select count(*) from user_word_cards where lexeme_id = ?",
                Integer.class,
                lexemeId);
    }

    private int countLexemes() {
        return jdbcTemplate.queryForObject("select count(*) from lexemes", Integer.class);
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

    private HttpResponse<String> postCardWithoutToken(String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/vocabulary/cards".formatted(port)))
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
