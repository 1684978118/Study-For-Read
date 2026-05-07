package com.studyforread.server.study;

import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.study.dto.LookupRequest;
import com.studyforread.server.study.dto.LookupResponse;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/study")
public class StudyController {

    private final StudyService studyService;

    public StudyController(StudyService studyService) {
        this.studyService = studyService;
    }

    @PostMapping("/lookup")
    public ResponseEntity<ApiResponse<LookupResponse>> lookup(
            @RequestBody Map<String, Object> requestBody,
            Authentication authentication) {
        try {
            var userId = UUID.fromString(authentication.getName());
            var request = parseAndValidate(requestBody);
            return ResponseEntity.ok(ApiResponse.ok(studyService.lookup(userId, request)));
        } catch (InvalidLookupRequestException | IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(ErrorCode.VALIDATION_ERROR, "Invalid lookup request"));
        } catch (StudyService.UnsupportedLanguagePairException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(
                            ErrorCode.TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR,
                            "Unsupported language pair"));
        } catch (StudyService.CurrentUserNotFoundException | NullPointerException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
        }
    }

    private LookupRequest parseAndValidate(Map<String, Object> requestBody) {
        if (requestBody == null) {
            throw new InvalidLookupRequestException();
        }

        var text = requiredText(requestBody, "text");
        var sourceLang = requiredText(requestBody, "sourceLang");
        var targetLang = requiredText(requestBody, "targetLang");
        var context = optionalText(requestBody, "context");

        if (text.trim().isBlank() || sourceLang.trim().isBlank() || targetLang.trim().isBlank()) {
            throw new InvalidLookupRequestException();
        }

        return new LookupRequest(text, sourceLang, targetLang, context);
    }

    private String requiredText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value)) {
            throw new InvalidLookupRequestException();
        }
        return value;
    }

    private String optionalText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (field == null) {
            return null;
        }
        if (!(field instanceof String value)) {
            throw new InvalidLookupRequestException();
        }
        var trimmed = value.trim();
        return trimmed.isBlank() ? null : trimmed;
    }

    private static class InvalidLookupRequestException extends RuntimeException {
    }
}
