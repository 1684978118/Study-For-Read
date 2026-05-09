package com.studyforread.server.admin;

import com.studyforread.server.admin.dto.AdminLoginRequest;
import com.studyforread.server.admin.dto.AdminLoginResponse;
import com.studyforread.server.admin.dto.AdminProfileResponse;
import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/auth")
public class AdminAuthController {

    private final AdminAuthService adminAuthService;

    public AdminAuthController(AdminAuthService adminAuthService) {
        this.adminAuthService = adminAuthService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AdminLoginResponse>> login(@Valid @RequestBody AdminLoginRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(adminAuthService.login(request)));
        } catch (AdminAuthService.DisabledAdminException exception) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.fail(ErrorCode.ADMIN_DISABLED, "Admin is disabled"));
        } catch (AdminAuthService.InvalidCredentialsException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.ADMIN_INVALID_CREDENTIALS, "Invalid admin credentials"));
        }
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AdminProfileResponse>> me(Authentication authentication) {
        if (authentication == null || !(authentication.getPrincipal() instanceof AdminPrincipal principal)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.ADMIN_REQUIRED, "Admin authentication required"));
        }

        try {
            return ResponseEntity.ok(ApiResponse.ok(adminAuthService.currentAdmin(principal)));
        } catch (AdminAuthService.AdminRequiredException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.ADMIN_REQUIRED, "Admin authentication required"));
        }
    }
}
