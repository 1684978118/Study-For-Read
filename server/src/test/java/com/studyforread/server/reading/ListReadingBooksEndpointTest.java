package com.studyforread.server.reading;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class ListReadingBooksEndpointTest {

    private static final String BOOK_FINGERPRINT_1 =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private static final String BOOK_FINGERPRINT_2 =
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";
    private static final String BOOK_FINGERPRINT_3 =
            "1111111111111111111111111111111111111111111111111111111111111111";
    private static final String BOOK_FINGERPRINT_4 =
            "2222222222222222222222222222222222222222222222222222222222222222";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Value("${local.server.port}")
    private int port;

    @Test
    void authenticatedUserWithNoSyncedBooksReceivesEmptyItems() throws Exception {
        var accessToken = registerAndGetAccessToken("list-empty@example.com");

        var response = getBooks(accessToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/items").isArray()).isTrue();
        assertThat(responseJson.at("/data/items")).isEmpty();
        assertThat(responseJson.at("/error").isNull()).isTrue();
    }

    @Test
    void authenticatedUserSeesOnlyOwnBooksOrderedByLastReadAtDescWithNullsLast() throws Exception {
        var ownerToken = registerAndGetAccessToken("list-owner@example.com");
        var otherToken = registerAndGetAccessToken("list-other@example.com");

        upsertBook(BOOK_FINGERPRINT_1, ownerToken, "Old Book", 10);
        patchProgress(BOOK_FINGERPRINT_1, ownerToken, """
                {
                  "currentChapterIndex": 1,
                  "currentParagraphIndex": 2,
                  "currentCharOffset": 3,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """);

        upsertBook(BOOK_FINGERPRINT_2, ownerToken, "Unread Book", 20);

        upsertBook(BOOK_FINGERPRINT_3, ownerToken, "Recent Book", 30);
        patchProgress(BOOK_FINGERPRINT_3, ownerToken, """
                {
                  "currentChapterIndex": 4,
                  "currentParagraphIndex": 5,
                  "currentCharOffset": 6,
                  "lastReadAt": "2026-05-06T12:30:00Z"
                }
                """);

        upsertBook(BOOK_FINGERPRINT_4, otherToken, "Other User Book", 40);
        patchProgress(BOOK_FINGERPRINT_4, otherToken, """
                {
                  "currentChapterIndex": 7,
                  "currentParagraphIndex": 8,
                  "currentCharOffset": 9,
                  "lastReadAt": "2026-05-07T12:30:00Z"
                }
                """);

        var response = getBooks(ownerToken);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseBody = response.body();
        var responseJson = objectMapper.readTree(responseBody);
        var items = responseJson.at("/data/items");
        assertThat(items).hasSize(3);

        assertThat(items.get(0).at("/bookFingerprint").asText()).isEqualTo(BOOK_FINGERPRINT_3);
        assertThat(items.get(0).at("/title").asText()).isEqualTo("Recent Book");
        assertThat(items.get(0).at("/currentChapterIndex").asInt()).isEqualTo(4);
        assertThat(items.get(0).at("/currentParagraphIndex").asInt()).isEqualTo(5);
        assertThat(items.get(0).at("/currentCharOffset").asInt()).isEqualTo(6);
        assertThat(items.get(0).at("/lastReadAt").asText()).isEqualTo("2026-05-06T12:30:00Z");

        assertThat(items.get(1).at("/bookFingerprint").asText()).isEqualTo(BOOK_FINGERPRINT_1);
        assertThat(items.get(1).at("/title").asText()).isEqualTo("Old Book");
        assertThat(items.get(1).at("/lastReadAt").asText()).isEqualTo("2026-05-05T12:30:00Z");

        assertThat(items.get(2).at("/bookFingerprint").asText()).isEqualTo(BOOK_FINGERPRINT_2);
        assertThat(items.get(2).at("/title").asText()).isEqualTo("Unread Book");
        assertThat(items.get(2).at("/lastReadAt").isNull()).isTrue();

        assertThat(responseBody).doesNotContain(BOOK_FINGERPRINT_4);
        assertNoOriginalTextFields(responseBody);
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = getBooksWithoutToken();

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

    private void upsertBook(String bookFingerprint, String accessToken, String title, int chapterCount) throws Exception {
        var response = putBook(bookFingerprint, accessToken, """
                {
                  "title": "%s",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": %d
                }
                """.formatted(title, chapterCount));

        assertThat(response.statusCode()).isEqualTo(200);
    }

    private void patchProgress(String bookFingerprint, String accessToken, String json) throws Exception {
        var response = sendJson(
                "PATCH",
                "/api/v1/reading/books/%s/progress".formatted(bookFingerprint),
                accessToken,
                json);

        assertThat(response.statusCode()).isEqualTo(200);
    }

    private void assertNoOriginalTextFields(String responseBody) {
        assertThat(responseBody).doesNotContain("content");
        assertThat(responseBody).doesNotContain("chapterContent");
        assertThat(responseBody).doesNotContain("originalFile");
        assertThat(responseBody).doesNotContain("filePath");
    }

    private HttpResponse<String> putBook(String bookFingerprint, String accessToken, String json) throws Exception {
        return sendJson(
                "PUT",
                "/api/v1/reading/books/%s".formatted(bookFingerprint),
                accessToken,
                json);
    }

    private HttpResponse<String> getBooks(String accessToken) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books".formatted(port)))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> getBooksWithoutToken() throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books".formatted(port)))
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

    private HttpResponse<String> sendJson(String method, String path, String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d%s".formatted(port, path)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .method(method, HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }
}
