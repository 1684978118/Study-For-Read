package com.studyforread.server.admin.dto;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

public record AdminAuditLogResponse(
        UUID id,
        UUID adminUserId,
        String adminUsername,
        String action,
        String targetType,
        UUID targetId,
        Map<String, Object> details,
        OffsetDateTime createdAt) {
}
