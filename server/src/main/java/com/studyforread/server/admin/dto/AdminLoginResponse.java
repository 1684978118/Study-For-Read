package com.studyforread.server.admin.dto;

public record AdminLoginResponse(
        AdminProfileResponse admin,
        String accessToken) {
}
