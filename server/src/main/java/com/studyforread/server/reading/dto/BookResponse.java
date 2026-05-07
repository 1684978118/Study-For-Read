package com.studyforread.server.reading.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record BookResponse(
        UUID id,
        String bookFingerprint,
        String title,
        String author,
        String fileType,
        String sourceLang,
        String targetLang,
        int chapterCount,
        int currentChapterIndex,
        int currentParagraphIndex,
        int currentCharOffset,
        OffsetDateTime lastReadAt) {
}
