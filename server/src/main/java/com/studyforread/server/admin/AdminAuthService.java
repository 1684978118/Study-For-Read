package com.studyforread.server.admin;

import com.studyforread.server.admin.dto.AdminLoginRequest;
import com.studyforread.server.admin.dto.AdminLoginResponse;
import com.studyforread.server.admin.dto.AdminProfileResponse;
import com.studyforread.server.security.AdminJwtService;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminAuthService {

    private final ObjectProvider<AdminUserRepository> adminUserRepositoryProvider;
    private final PasswordEncoder passwordEncoder;
    private final AdminJwtService adminJwtService;

    public AdminAuthService(
            ObjectProvider<AdminUserRepository> adminUserRepositoryProvider,
            PasswordEncoder passwordEncoder,
            AdminJwtService adminJwtService) {
        this.adminUserRepositoryProvider = adminUserRepositoryProvider;
        this.passwordEncoder = passwordEncoder;
        this.adminJwtService = adminJwtService;
    }

    @Transactional(readOnly = true)
    public AdminLoginResponse login(AdminLoginRequest request) {
        var adminUser = adminUserRepository().findByUsername(request.username().trim())
                .filter(candidate -> passwordEncoder.matches(request.password(), candidate.getCredentialHash()))
                .orElseThrow(InvalidCredentialsException::new);

        if (adminUser.getStatus() == AdminStatus.DISABLED) {
            throw new DisabledAdminException();
        }

        return new AdminLoginResponse(toProfile(adminUser), adminJwtService.createAccessToken(adminUser));
    }

    @Transactional(readOnly = true)
    public AdminProfileResponse currentAdmin(AdminPrincipal principal) {
        var adminUser = adminUserRepository().findById(principal.id())
                .filter(candidate -> candidate.getStatus() == AdminStatus.ACTIVE)
                .orElseThrow(AdminRequiredException::new);

        return toProfile(adminUser);
    }

    @Transactional(readOnly = true)
    public AdminPrincipal activePrincipal(UUID adminId) {
        var adminUser = adminUserRepository().findById(adminId)
                .filter(candidate -> candidate.getStatus() == AdminStatus.ACTIVE)
                .orElseThrow(AdminRequiredException::new);

        return new AdminPrincipal(
                adminUser.getId(),
                adminUser.getUsername(),
                adminUser.getRole(),
                adminUser.getStatus());
    }

    private AdminProfileResponse toProfile(AdminUser adminUser) {
        return new AdminProfileResponse(
                adminUser.getId(),
                adminUser.getUsername(),
                adminUser.getRole().databaseValue(),
                adminUser.getStatus().databaseValue());
    }

    private AdminUserRepository adminUserRepository() {
        return adminUserRepositoryProvider.getIfAvailable(() -> {
            throw new AdminRequiredException();
        });
    }

    public static class InvalidCredentialsException extends RuntimeException {
    }

    public static class DisabledAdminException extends RuntimeException {
    }

    public static class AdminRequiredException extends RuntimeException {
    }
}
