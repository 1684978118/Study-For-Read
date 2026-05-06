package com.studyforread.server.auth.dto;

public record TokenRefreshResponse(String accessToken, String refreshToken) {
}
