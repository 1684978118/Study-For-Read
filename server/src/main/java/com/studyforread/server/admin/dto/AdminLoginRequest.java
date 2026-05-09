package com.studyforread.server.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminLoginRequest(
        @NotBlank @Size(max = 80) String username,
        @NotBlank @Size(min = 8, max = 128) String password) {
}
