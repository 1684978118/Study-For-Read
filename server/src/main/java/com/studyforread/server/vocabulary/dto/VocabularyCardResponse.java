package com.studyforread.server.vocabulary.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record VocabularyCardResponse(
        UUID id,
        String cardType,
        LexemeSummaryResponse lexeme,
        String privateSurface,
        String privateDefinition,
        String reviewStatus,
        int reviewCount,
        OffsetDateTime nextReviewAt) {
}
