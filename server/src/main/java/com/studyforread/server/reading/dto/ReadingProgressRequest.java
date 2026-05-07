package com.studyforread.server.reading.dto;

import java.time.OffsetDateTime;

public record ReadingProgressRequest(
        int currentChapterIndex,
        int currentParagraphIndex,
        int currentCharOffset,
        OffsetDateTime lastReadAt) {
}
