package com.studyforread.server.stats.dto;

public record StudySummaryResponse(
        long readingMinutes,
        long lookupCount,
        long paragraphTranslationCount,
        long cardsCreated,
        long cardsReviewed) {
}
