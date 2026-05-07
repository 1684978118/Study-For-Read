package com.studyforread.server.stats.dto;

import java.time.LocalDate;

public record AddDailyStatsRequest(
        LocalDate statDate,
        int readingMinutes,
        int lookupCount,
        int paragraphTranslationCount,
        int cardsCreated,
        int cardsReviewed) {
}
