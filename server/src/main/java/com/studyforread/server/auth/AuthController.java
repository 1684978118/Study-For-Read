package com.studyforread.server.auth;

import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.auth.dto.AuthResponse;
import com.studyforread.server.auth.dto.LoginRequest;
import com.studyforread.server.auth.dto.RegisterRequest;
import com.studyforread.server.auth.dto.RefreshRequest;
import com.studyforread.server.auth.dto.TokenRefreshResponse;
import com.studyforread.server.auth.dto.UserProfileResponse;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(authService.register(request)));
        } catch (AuthService.EmailAlreadyExistsException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.fail(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS, "Email already exists"));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(authService.login(request)));
        } catch (AuthService.InvalidCredentialsException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.AUTH_INVALID_CREDENTIALS, "Invalid email or password"));
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<TokenRefreshResponse>> refresh(@Valid @RequestBody RefreshRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(authService.refresh(request)));
        } catch (AuthService.InvalidRefreshTokenException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.AUTH_REFRESH_TOKEN_INVALID, "Invalid refresh token"));
        }
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> me(Authentication authentication) {
        try {
            return ResponseEntity.ok(ApiResponse.ok(authService.currentUser(authentication.getName())));
        } catch (AuthService.CurrentUserNotFoundException | IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
        }
    }
}
