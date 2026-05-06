package com.studyforread.server.auth.dto;

import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        String email,
        String displayName,
        String sourceLang,
        String targetLang,
        String status) {
}
