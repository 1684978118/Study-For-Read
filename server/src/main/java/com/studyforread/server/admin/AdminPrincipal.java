package com.studyforread.server.admin;

import java.util.UUID;

public record AdminPrincipal(
        UUID id,
        String username,
        AdminRole role,
        AdminStatus status) {
}
