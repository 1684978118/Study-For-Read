package com.studyforread.server.auth.dto;

public record AuthResponse(
        UserProfileResponse user,
        String accessToken,
        String refreshToken) {
}
