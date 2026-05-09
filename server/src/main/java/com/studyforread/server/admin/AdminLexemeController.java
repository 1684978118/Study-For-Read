package com.studyforread.server.admin;

import com.studyforread.server.admin.dto.AdminLexemeListResponse;
import com.studyforread.server.admin.dto.AdminLexemeRejectRequest;
import com.studyforread.server.admin.dto.AdminLexemeRejectResponse;
import com.studyforread.server.admin.dto.AdminLexemeResponse;
import com.studyforread.server.admin.dto.AdminLexemeUpsertRequest;
import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/lexemes")
public class AdminLexemeController {

    private final AdminLexemeService adminLexemeService;

    public AdminLexemeController(AdminLexemeService adminLexemeService) {
        this.adminLexemeService = adminLexemeService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<AdminLexemeListResponse>> list(
            Authentication authentication,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(name = "q", required = false) String query,
            @RequestParam(required = false) String sourceLang,
            @RequestParam(required = false) String targetLang,
            @RequestParam(required = false) String entryType,
            @RequestParam(required = false) String status) {
        var principal = adminPrincipal(authentication);
        if (principal == null) {
            return adminRequired();
        }

        try {
            return ResponseEntity.ok(ApiResponse.ok(adminLexemeService.list(
                    page,
                    size,
                    query,
                    sourceLang,
                    targetLang,
                    entryType,
                    status)));
        } catch (AdminLexemeService.InvalidLexemeException exception) {
            return invalid();
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AdminLexemeResponse>> create(
            Authentication authentication,
            @RequestBody AdminLexemeUpsertRequest request) {
        var principal = adminPrincipal(authentication);
        if (principal == null) {
            return adminRequired();
        }

        try {
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.ok(adminLexemeService.create(principal, request)));
        } catch (AdminLexemeService.InvalidLexemeException exception) {
            return invalid();
        } catch (AdminLexemeService.DuplicateLexemeException exception) {
            return duplicate();
        }
    }

    @PatchMapping("/{lexemeId}")
    public ResponseEntity<ApiResponse<AdminLexemeResponse>> update(
            Authentication authentication,
            @PathVariable UUID lexemeId,
            @RequestBody AdminLexemeUpsertRequest request) {
        var principal = adminPrincipal(authentication);
        if (principal == null) {
            return adminRequired();
        }

        try {
            return ResponseEntity.ok(ApiResponse.ok(adminLexemeService.update(lexemeId, principal, request)));
        } catch (AdminLexemeService.InvalidLexemeException exception) {
            return invalid();
        } catch (AdminLexemeService.DuplicateLexemeException exception) {
            return duplicate();
        } catch (AdminLexemeService.NotFoundException exception) {
            return notFound();
        }
    }

    @PostMapping("/{lexemeId}/reject")
    public ResponseEntity<ApiResponse<AdminLexemeRejectResponse>> reject(
            Authentication authentication,
            @PathVariable UUID lexemeId,
            @RequestBody(required = false) AdminLexemeRejectRequest request) {
        var principal = adminPrincipal(authentication);
        if (principal == null) {
            return adminRequired();
        }

        try {
            return ResponseEntity.ok(ApiResponse.ok(adminLexemeService.reject(lexemeId, principal)));
        } catch (AdminLexemeService.NotFoundException exception) {
            return notFound();
        }
    }

    private AdminPrincipal adminPrincipal(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof AdminPrincipal principal) {
            return principal;
        }
        return null;
    }

    private <T> ResponseEntity<ApiResponse<T>> adminRequired() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.fail(ErrorCode.ADMIN_REQUIRED, "Admin authentication required"));
    }

    private <T> ResponseEntity<ApiResponse<T>> invalid() {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.fail(ErrorCode.ADMIN_LEXEME_INVALID, "Invalid lexeme"));
    }

    private <T> ResponseEntity<ApiResponse<T>> duplicate() {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.fail(ErrorCode.ADMIN_LEXEME_DUPLICATE, "Duplicate lexeme"));
    }

    private <T> ResponseEntity<ApiResponse<T>> notFound() {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.fail(ErrorCode.NOT_FOUND, "Not found"));
    }
}
