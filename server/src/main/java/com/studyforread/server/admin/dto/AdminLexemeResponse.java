package com.studyforread.server.admin.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AdminLexemeResponse(
        UUID id,
        String surface,
        String normalizedSurface,
        String reading,
        String sourceLang,
        String targetLang,
        String entryType,
        String partOfSpeech,
        String definition,
        String shortDefinition,
        String example,
        String status,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
