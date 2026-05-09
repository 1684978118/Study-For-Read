package com.studyforread.server.admin.dto;

import java.util.List;

public record AdminLexemeListResponse(
        List<AdminLexemeResponse> items,
        int page,
        int size,
        long total) {
}
