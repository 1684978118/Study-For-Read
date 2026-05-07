package com.studyforread.server.study;

import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.study.dto.LookupRequest;
import com.studyforread.server.study.dto.LookupResponse;
import com.studyforread.server.study.dto.TranslateParagraphRequest;
import com.studyforread.server.study.dto.TranslateParagraphResponse;
import java.util.Map;
import java.util.Set;
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

    private static final Set<String> PARAGRAPH_TRANSLATION_FORBIDDEN_FIELDS = Set.of(
            "paragraphs",
            "chapters",
            "content",
            "chapterContent",
            "bookContent",
            "fullText",
            "originalFile",
            "filePath");

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

    @PostMapping("/translate-paragraph")
    public ResponseEntity<ApiResponse<TranslateParagraphResponse>> translateParagraph(
            @RequestBody Map<String, Object> requestBody,
            Authentication authentication) {
        try {
            var userId = UUID.fromString(authentication.getName());
            var request = parseAndValidateTranslateParagraph(requestBody);
            return ResponseEntity.ok(ApiResponse.ok(studyService.translateParagraph(userId, request)));
        } catch (InvalidTranslateParagraphRequestException | IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(ErrorCode.VALIDATION_ERROR, "Invalid paragraph translation request"));
        } catch (StudyService.TextTooLongException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(ErrorCode.TRANSLATION_TEXT_TOO_LONG, "Translation text is too long"));
        } catch (StudyService.UnsupportedLanguagePairException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(
                            ErrorCode.TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR,
                            "Unsupported language pair"));
        } catch (StudyService.ProviderUnavailableException exception) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.fail(
                            ErrorCode.TRANSLATION_PROVIDER_UNAVAILABLE,
                            "Translation provider unavailable"));
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

    private TranslateParagraphRequest parseAndValidateTranslateParagraph(Map<String, Object> requestBody) {
        if (requestBody == null || hasForbiddenParagraphTranslationFields(requestBody)) {
            throw new InvalidTranslateParagraphRequestException();
        }

        var text = requiredParagraphTranslationText(requestBody, "text");
        var sourceLang = requiredParagraphTranslationText(requestBody, "sourceLang");
        var targetLang = requiredParagraphTranslationText(requestBody, "targetLang");

        if (text.trim().isBlank() || sourceLang.trim().isBlank() || targetLang.trim().isBlank()) {
            throw new InvalidTranslateParagraphRequestException();
        }

        return new TranslateParagraphRequest(text, sourceLang, targetLang);
    }

    private boolean hasForbiddenParagraphTranslationFields(Map<String, Object> requestBody) {
        for (var fieldName : PARAGRAPH_TRANSLATION_FORBIDDEN_FIELDS) {
            if (requestBody.containsKey(fieldName)) {
                return true;
            }
        }
        return false;
    }

    private String requiredText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value)) {
            throw new InvalidLookupRequestException();
        }
        return value;
    }

    private String requiredParagraphTranslationText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value)) {
            throw new InvalidTranslateParagraphRequestException();
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

    private static class InvalidTranslateParagraphRequestException extends RuntimeException {
    }
}
