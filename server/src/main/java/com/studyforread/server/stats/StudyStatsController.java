package com.studyforread.server.stats;

import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.stats.dto.AddDailyStatsRequest;
import com.studyforread.server.stats.dto.DailyStatsResponse;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
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
@RequestMapping("/api/v1/stats")
public class StudyStatsController {

    private static final Set<String> FORBIDDEN_FIELDS = Set.of(
            "content",
            "chapterContent",
            "originalFile",
            "filePath",
            "sourceText",
            "rawText",
            "translatedText",
            "paragraphText");

    private final StudyStatsService studyStatsService;

    public StudyStatsController(StudyStatsService studyStatsService) {
        this.studyStatsService = studyStatsService;
    }

    @PostMapping("/daily")
    public ResponseEntity<ApiResponse<DailyStatsResponse>> addDailyStats(
            @RequestBody Map<String, Object> requestBody,
            Authentication authentication) {
        try {
            var userId = UUID.fromString(authentication.getName());
            var request = parseAndValidate(requestBody);
            return ResponseEntity.ok(ApiResponse.ok(studyStatsService.addDailyStats(userId, request)));
        } catch (InvalidDailyStatsRequestException
                 | StudyStatsService.InvalidDailyStatsException
                 | DateTimeParseException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.fail(ErrorCode.VALIDATION_ERROR, "Invalid daily stats"));
        } catch (StudyStatsService.CurrentUserNotFoundException | NullPointerException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
        }
    }

    private AddDailyStatsRequest parseAndValidate(Map<String, Object> requestBody) {
        if (requestBody == null || hasForbiddenFields(requestBody)) {
            throw new InvalidDailyStatsRequestException();
        }

        var statDate = requiredDate(requestBody, "statDate");
        var readingMinutes = requiredCounter(requestBody, "readingMinutes");
        var lookupCount = requiredCounter(requestBody, "lookupCount");
        var paragraphTranslationCount = requiredCounter(requestBody, "paragraphTranslationCount");
        var cardsCreated = requiredCounter(requestBody, "cardsCreated");
        var cardsReviewed = requiredCounter(requestBody, "cardsReviewed");

        return new AddDailyStatsRequest(
                statDate,
                readingMinutes,
                lookupCount,
                paragraphTranslationCount,
                cardsCreated,
                cardsReviewed);
    }

    private boolean hasForbiddenFields(Map<String, Object> requestBody) {
        for (var fieldName : FORBIDDEN_FIELDS) {
            if (requestBody.containsKey(fieldName)) {
                return true;
            }
        }
        return false;
    }

    private LocalDate requiredDate(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (!(field instanceof String value) || value.isBlank()) {
            throw new InvalidDailyStatsRequestException();
        }
        return LocalDate.parse(value);
    }

    private int requiredCounter(Map<String, Object> requestBody, String fieldName) {
        var field = requestBody.get(fieldName);
        if (field instanceof Integer value && value >= 0) {
            return value;
        }
        if (field instanceof Long value && value >= 0 && value <= Integer.MAX_VALUE) {
            return value.intValue();
        }
        throw new InvalidDailyStatsRequestException();
    }

    private static class InvalidDailyStatsRequestException extends RuntimeException {
    }
}
