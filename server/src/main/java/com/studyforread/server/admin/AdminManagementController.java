package com.studyforread.server.admin;

import com.studyforread.server.admin.dto.AdminAuditLogListResponse;
import com.studyforread.server.admin.dto.AdminPlatformStatsResponse;
import com.studyforread.server.admin.dto.AdminUserListResponse;
import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
public class AdminManagementController {

    private final AdminManagementService adminManagementService;

    public AdminManagementController(AdminManagementService adminManagementService) {
        this.adminManagementService = adminManagementService;
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<AdminUserListResponse>> users(
            Authentication authentication,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String status,
            @RequestParam(name = "q", required = false) String query) {
        if (!isAdmin(authentication)) {
            return adminRequired();
        }

        return ResponseEntity.ok(ApiResponse.ok(adminManagementService.listUsers(page, size, status, query)));
    }

    @GetMapping("/stats/summary")
    public ResponseEntity<ApiResponse<AdminPlatformStatsResponse>> statsSummary(Authentication authentication) {
        if (!isAdmin(authentication)) {
            return adminRequired();
        }

        return ResponseEntity.ok(ApiResponse.ok(adminManagementService.getPlatformStats()));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<ApiResponse<AdminAuditLogListResponse>> auditLogs(
            Authentication authentication,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) UUID adminUserId,
            @RequestParam(required = false) String targetType,
            @RequestParam(required = false) String action) {
        if (!isAdmin(authentication)) {
            return adminRequired();
        }

        return ResponseEntity.ok(ApiResponse.ok(adminManagementService.listAuditLogs(
                page,
                size,
                adminUserId,
                targetType,
                action)));
    }

    private boolean isAdmin(Authentication authentication) {
        return authentication != null && authentication.getPrincipal() instanceof AdminPrincipal;
    }

    private <T> ResponseEntity<ApiResponse<T>> adminRequired() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.fail(ErrorCode.ADMIN_REQUIRED, "Admin authentication required"));
    }
}
