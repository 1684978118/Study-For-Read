package com.studyforread.server.admin.dto;

public record AdminPlatformStatsResponse(
        long userCount,
        long activeUserCount,
        long disabledUserCount,
        long bookMetadataCount,
        long lexemeCount,
        long wordCardCount,
        long readingMinutes,
        long lookupCount,
        long paragraphTranslationCount,
        long cardsCreated,
        long cardsReviewed) {
}
