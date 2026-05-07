package com.studyforread.server.reading;

import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.reading.dto.BookMetadataRequest;
import com.studyforread.server.reading.dto.BookResponse;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/reading/books")
public class ReadingController {

    private static final Pattern BOOK_FINGERPRINT_PATTERN = Pattern.compile("[0-9a-f]{64}");
    private static final Set<String> FORBIDDEN_FIELDS = Set.of(
            "content",
            "chapterContent",
            "originalFile",
            "filePath");

    private final ReadingService readingService;

    public ReadingController(ReadingService readingService) {
        this.readingService = readingService;
    }

    @PutMapping("/{bookFingerprint}")
    public ResponseEntity<ApiResponse<BookResponse>> upsertBookMetadata(
            @PathVariable String bookFingerprint,
            @RequestBody Map<String, Object> requestBody,
            Authentication authentication) {
        try {
            var userId = UUID.fromString(authentication.getName());
            var request = parseAndValidate(bookFingerprint, requestBody);
            return ResponseEntity.ok(ApiResponse.ok(readingService.upsertBookMetadata(userId, bookFingerprint, request)));
        } catch (InvalidBookMetadataException | IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(ErrorCode.BOOK_METADATA_INVALID, "Invalid book metadata"));
        } catch (ReadingService.CurrentUserNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
        }
    }

    private BookMetadataRequest parseAndValidate(String bookFingerprint, Map<String, Object> requestBody) {
        if (!BOOK_FINGERPRINT_PATTERN.matcher(bookFingerprint).matches()
                || requestBody == null
                || hasForbiddenFields(requestBody)) {
            throw new InvalidBookMetadataException();
        }

        var title = requiredText(requestBody, "title");
        var author = optionalText(requestBody, "author");
        var fileType = requiredText(requestBody, "fileType");
        var sourceLang = requiredText(requestBody, "sourceLang");
        var targetLang = requiredText(requestBody, "targetLang");
        var chapterCountValue = requestBody.get("chapterCount");
        if (!(chapterCountValue instanceof Number chapterCountNumber)) {
            throw new InvalidBookMetadataException();
        }

        var chapterCount = chapterCountNumber.intValue();
        if (title.isBlank()
                || sourceLang.isBlank()
                || targetLang.isBlank()
                || chapterCount < 1
                || (!"txt".equals(fileType) && !"epub".equals(fileType))) {
            throw new InvalidBookMetadataException();
        }

        return new BookMetadataRequest(
                title.trim(),
                author,
                fileType,
                sourceLang.trim(),
                targetLang.trim(),
                chapterCount);
    }

    private boolean hasForbiddenFields(Map<String, Object> requestBody) {
        for (var fieldName : FORBIDDEN_FIELDS) {
            if (requestBody.containsKey(fieldName)) {
                return true;
            }
        }
        return false;
    }

    private String requiredText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value)) {
            throw new InvalidBookMetadataException();
        }
        return value;
    }

    private String optionalText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (field == null) {
            return null;
        }
        if (!(field instanceof String value)) {
            throw new InvalidBookMetadataException();
        }
        var trimmed = value.trim();
        return trimmed.isBlank() ? null : trimmed;
    }

    private static class InvalidBookMetadataException extends RuntimeException {
    }
}
