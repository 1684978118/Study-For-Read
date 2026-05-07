package com.studyforread.server.vocabulary.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record VocabularyCardResponse(
        UUID id,
        String cardType,
        String surface,
        String reading,
        String definition,
        LexemeSummaryResponse lexeme,
        String privateSurface,
        String privateDefinition,
        String reviewStatus,
        int reviewCount,
        OffsetDateTime nextReviewAt,
        OffsetDateTime lastReviewedAt) {

    public VocabularyCardResponse(
            UUID id,
            String cardType,
            LexemeSummaryResponse lexeme,
            String privateSurface,
            String privateDefinition,
            String reviewStatus,
            int reviewCount,
            OffsetDateTime nextReviewAt) {
        this(
                id,
                cardType,
                lexeme,
                privateSurface,
                privateDefinition,
                reviewStatus,
                reviewCount,
                nextReviewAt,
                null);
    }

    public VocabularyCardResponse(
            UUID id,
            String cardType,
            LexemeSummaryResponse lexeme,
            String privateSurface,
            String privateDefinition,
            String reviewStatus,
            int reviewCount,
            OffsetDateTime nextReviewAt,
            OffsetDateTime lastReviewedAt) {
        this(
                id,
                cardType,
                lexeme == null ? privateSurface : lexeme.surface(),
                lexeme == null ? null : lexeme.reading(),
                lexeme == null ? privateDefinition : lexeme.definition(),
                lexeme,
                privateSurface,
                privateDefinition,
                reviewStatus,
                reviewCount,
                nextReviewAt,
                lastReviewedAt);
    }
}
