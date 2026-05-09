package com.studyforread.server.admin.dto;

import java.util.UUID;

public record AdminProfileResponse(
        UUID id,
        String username,
        String role,
        String status) {
}
