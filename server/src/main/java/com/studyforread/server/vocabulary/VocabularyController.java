package com.studyforread.server.vocabulary;

import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.vocabulary.dto.CreateVocabularyCardRequest;
import com.studyforread.server.vocabulary.dto.DueVocabularyCardsResponse;
import com.studyforread.server.vocabulary.dto.VocabularyCardResponse;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/vocabulary")
public class VocabularyController {

    private static final Pattern SOURCE_BOOK_FINGERPRINT_PATTERN = Pattern.compile("[0-9a-f]{64}");

    private final VocabularyService vocabularyService;

    public VocabularyController(VocabularyService vocabularyService) {
        this.vocabularyService = vocabularyService;
    }

    @GetMapping("/cards/due")
    public ResponseEntity<ApiResponse<DueVocabularyCardsResponse>> listDueCards(Authentication authentication) {
        try {
            var userId = UUID.fromString(authentication.getName());
            return ResponseEntity.ok(ApiResponse.ok(vocabularyService.listDueCards(userId)));
        } catch (VocabularyService.CurrentUserNotFoundException | IllegalArgumentException | NullPointerException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
        }
    }

    @PostMapping("/cards")
    public ResponseEntity<ApiResponse<VocabularyCardResponse>> createCard(
            @RequestBody Map<String, Object> requestBody,
            Authentication authentication) {
        try {
            var userId = UUID.fromString(authentication.getName());
            var request = parseAndValidate(requestBody);
            return ResponseEntity.ok(ApiResponse.ok(vocabularyService.createCard(userId, request)));
        } catch (InvalidVocabularyCardException | IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(ErrorCode.PRIVATE_CARD_INVALID, "Invalid vocabulary card"));
        } catch (VocabularyService.LexemeNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.fail(ErrorCode.LEXEME_NOT_FOUND, "Lexeme not found"));
        } catch (VocabularyService.CurrentUserNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
        }
    }

    private CreateVocabularyCardRequest parseAndValidate(Map<String, Object> requestBody) {
        if (requestBody == null) {
            throw new InvalidVocabularyCardException();
        }

        var cardType = requiredText(requestBody, "cardType").trim();
        var sourceBookFingerprint = optionalText(requestBody, "sourceBookFingerprint");
        if (sourceBookFingerprint != null
                && !SOURCE_BOOK_FINGERPRINT_PATTERN.matcher(sourceBookFingerprint).matches()) {
            throw new InvalidVocabularyCardException();
        }

        var sourceBookTitle = optionalText(requestBody, "sourceBookTitle");
        if (WordCardType.LEXEME.databaseValue().equals(cardType)) {
            var lexemeId = requiredUuid(requestBody, "lexemeId");
            return new CreateVocabularyCardRequest(
                    cardType,
                    lexemeId,
                    null,
                    null,
                    null,
                    sourceBookFingerprint,
                    sourceBookTitle);
        }

        if (WordCardType.PRIVATE_SENTENCE.databaseValue().equals(cardType)) {
            var privateSurface = requiredText(requestBody, "privateSurface").trim();
            var privateDefinition = requiredText(requestBody, "privateDefinition").trim();
            var privateContext = optionalText(requestBody, "privateContext");
            if (privateSurface.isBlank() || privateDefinition.isBlank()) {
                throw new InvalidVocabularyCardException();
            }

            return new CreateVocabularyCardRequest(
                    cardType,
                    null,
                    privateSurface,
                    privateDefinition,
                    privateContext,
                    sourceBookFingerprint,
                    sourceBookTitle);
        }

        throw new InvalidVocabularyCardException();
    }

    private String requiredText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value)) {
            throw new InvalidVocabularyCardException();
        }
        return value;
    }

    private String optionalText(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (field == null) {
            return null;
        }
        if (!(field instanceof String value)) {
            throw new InvalidVocabularyCardException();
        }
        var trimmed = value.trim();
        return trimmed.isBlank() ? null : trimmed;
    }

    private UUID requiredUuid(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value) || value.isBlank()) {
            throw new InvalidVocabularyCardException();
        }
        return UUID.fromString(value);
    }

    private static class InvalidVocabularyCardException extends RuntimeException {
    }
}
