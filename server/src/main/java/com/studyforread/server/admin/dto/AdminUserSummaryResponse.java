package com.studyforread.server.admin.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AdminUserSummaryResponse(
        UUID id,
        String email,
        String displayName,
        String sourceLang,
        String targetLang,
        String status,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt) {
}
