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
class UpdateReadingProgressEndpointTest {

    private static final String BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private static final String OTHER_BOOK_FINGERPRINT =
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Value("${local.server.port}")
    private int port;

    @Test
    void authenticatedUserCanUpdateProgressForOwnBook() throws Exception {
        var accessToken = registerAndGetAccessToken("progress-update@example.com");
        upsertBook(BOOK_FINGERPRINT, accessToken);

        var response = patchProgress(BOOK_FINGERPRINT, accessToken, """
                {
                  "currentChapterIndex": 3,
                  "currentParagraphIndex": 12,
                  "currentCharOffset": 48,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """);

        assertThat(response.statusCode()).isEqualTo(200);
        var responseBody = response.body();
        var responseJson = objectMapper.readTree(responseBody);
        assertThat(responseJson.at("/success").asBoolean()).isTrue();
        assertThat(responseJson.at("/data/bookFingerprint").asText()).isEqualTo(BOOK_FINGERPRINT);
        assertThat(responseJson.at("/data/currentChapterIndex").asInt()).isEqualTo(3);
        assertThat(responseJson.at("/data/currentParagraphIndex").asInt()).isEqualTo(12);
        assertThat(responseJson.at("/data/currentCharOffset").asInt()).isEqualTo(48);
        assertThat(responseJson.at("/data/lastReadAt").asText()).isEqualTo("2026-05-05T12:30:00Z");
        assertThat(responseJson.at("/error").isNull()).isTrue();
        assertNoOriginalTextFields(responseBody);
    }

    @Test
    void invalidBookFingerprintReturnsBookProgressInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("progress-invalid-fingerprint@example.com");

        var shortResponse = patchProgress("abc123", accessToken, validProgressJson());
        var nonHexResponse = patchProgress(
                "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
                accessToken,
                validProgressJson());
        var uppercaseResponse = patchProgress(
                "ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
                accessToken,
                validProgressJson());

        assertBookProgressInvalid(shortResponse);
        assertBookProgressInvalid(nonHexResponse);
        assertBookProgressInvalid(uppercaseResponse);
    }

    @Test
    void negativeProgressReturnsBookProgressInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("progress-negative@example.com");
        upsertBook(BOOK_FINGERPRINT, accessToken);

        assertBookProgressInvalid(patchProgress(BOOK_FINGERPRINT, accessToken, """
                {
                  "currentChapterIndex": -1,
                  "currentParagraphIndex": 12,
                  "currentCharOffset": 48,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """));
        assertBookProgressInvalid(patchProgress(BOOK_FINGERPRINT, accessToken, """
                {
                  "currentChapterIndex": 3,
                  "currentParagraphIndex": -1,
                  "currentCharOffset": 48,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """));
        assertBookProgressInvalid(patchProgress(BOOK_FINGERPRINT, accessToken, """
                {
                  "currentChapterIndex": 3,
                  "currentParagraphIndex": 12,
                  "currentCharOffset": -1,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """));
    }

    @Test
    void missingCurrentUserBookReturnsNotFound() throws Exception {
        var accessToken = registerAndGetAccessToken("progress-missing-book@example.com");

        var response = patchProgress(OTHER_BOOK_FINGERPRINT, accessToken, validProgressJson());

        assertThat(response.statusCode()).isEqualTo(404);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("NOT_FOUND");
    }

    @Test
    void userCannotUpdateAnotherUsersBookWithSameFingerprint() throws Exception {
        var ownerToken = registerAndGetAccessToken("progress-owner@example.com");
        var otherToken = registerAndGetAccessToken("progress-other@example.com");
        upsertBook(BOOK_FINGERPRINT, ownerToken);

        var response = patchProgress(BOOK_FINGERPRINT, otherToken, validProgressJson());

        assertThat(response.statusCode()).isEqualTo(404);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("NOT_FOUND");
    }

    @Test
    void forbiddenOriginalTextFieldsReturnBookProgressInvalid() throws Exception {
        var accessToken = registerAndGetAccessToken("progress-forbidden-fields@example.com");
        upsertBook(BOOK_FINGERPRINT, accessToken);

        for (var fieldName : new String[] {"content", "chapterContent", "originalFile", "filePath"}) {
            var response = patchProgress(BOOK_FINGERPRINT, accessToken, """
                    {
                      "currentChapterIndex": 3,
                      "currentParagraphIndex": 12,
                      "currentCharOffset": 48,
                      "lastReadAt": "2026-05-05T12:30:00Z",
                      "%s": "must-not-be-accepted"
                    }
                    """.formatted(fieldName));

            assertBookProgressInvalid(response);
        }
    }

    @Test
    void unauthenticatedRequestReturnsUnauthorized() throws Exception {
        var response = patchProgressWithoutToken(BOOK_FINGERPRINT, validProgressJson());

        assertThat(response.statusCode()).isEqualTo(401);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
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

    private void upsertBook(String bookFingerprint, String accessToken) throws Exception {
        var response = putBook(bookFingerprint, accessToken, """
                {
                  "title": "Kokoro",
                  "author": "Natsume Soseki",
                  "fileType": "txt",
                  "sourceLang": "ja",
                  "targetLang": "zh-CN",
                  "chapterCount": 42
                }
                """);

        assertThat(response.statusCode()).isEqualTo(200);
    }

    private String validProgressJson() {
        return """
                {
                  "currentChapterIndex": 3,
                  "currentParagraphIndex": 12,
                  "currentCharOffset": 48,
                  "lastReadAt": "2026-05-05T12:30:00Z"
                }
                """;
    }

    private void assertBookProgressInvalid(HttpResponse<String> response) throws Exception {
        assertThat(response.statusCode()).isEqualTo(400);
        var responseJson = objectMapper.readTree(response.body());
        assertThat(responseJson.at("/success").asBoolean()).isFalse();
        assertThat(responseJson.at("/data").isNull()).isTrue();
        assertThat(responseJson.at("/error/code").asText()).isEqualTo("BOOK_PROGRESS_INVALID");
    }

    private void assertNoOriginalTextFields(String responseBody) {
        assertThat(responseBody).doesNotContain("content");
        assertThat(responseBody).doesNotContain("chapterContent");
        assertThat(responseBody).doesNotContain("originalFile");
        assertThat(responseBody).doesNotContain("filePath");
    }

    private HttpResponse<String> putBook(String bookFingerprint, String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books/%s".formatted(port, bookFingerprint)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> patchProgress(String bookFingerprint, String accessToken, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books/%s/progress".formatted(port, bookFingerprint)))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .method("PATCH", HttpRequest.BodyPublishers.ofString(json))
                .build();

        return httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> patchProgressWithoutToken(String bookFingerprint, String json) throws Exception {
        var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:%d/api/v1/reading/books/%s/progress".formatted(port, bookFingerprint)))
                .header("Content-Type", "application/json")
                .method("PATCH", HttpRequest.BodyPublishers.ofString(json))
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
