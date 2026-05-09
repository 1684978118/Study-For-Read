package com.studyforread.server.admin.dto;

import java.util.List;

public record AdminUserListResponse(
        List<AdminUserSummaryResponse> items,
        int page,
        int size,
        long total) {
}
