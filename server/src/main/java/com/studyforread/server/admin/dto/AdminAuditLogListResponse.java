package com.studyforread.server.admin.dto;

import java.util.List;

public record AdminAuditLogListResponse(
        List<AdminAuditLogResponse> items,
        int page,
        int size,
        long total) {
}
