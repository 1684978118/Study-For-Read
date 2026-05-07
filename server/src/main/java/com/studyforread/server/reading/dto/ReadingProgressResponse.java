package com.studyforread.server.reading.dto;

import java.time.OffsetDateTime;

public record ReadingProgressResponse(
        String bookFingerprint,
        int currentChapterIndex,
        int currentParagraphIndex,
        int currentCharOffset,
        OffsetDateTime lastReadAt) {
}
