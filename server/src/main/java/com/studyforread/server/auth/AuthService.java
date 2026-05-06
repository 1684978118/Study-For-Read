package com.studyforread.server.auth;

import com.studyforread.server.auth.dto.AuthResponse;
import com.studyforread.server.auth.dto.LoginRequest;
import com.studyforread.server.auth.dto.RegisterRequest;
import com.studyforread.server.auth.dto.RefreshRequest;
import com.studyforread.server.auth.dto.TokenRefreshResponse;
import com.studyforread.server.auth.dto.UserProfileResponse;
import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import java.time.OffsetDateTime;
import java.util.Locale;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final ObjectProvider<UserAccountRepository> userAccountRepositoryProvider;
    private final ObjectProvider<RefreshTokenRepository> refreshTokenRepositoryProvider;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    public AuthService(
            ObjectProvider<UserAccountRepository> userAccountRepositoryProvider,
            ObjectProvider<RefreshTokenRepository> refreshTokenRepositoryProvider,
            PasswordEncoder passwordEncoder,
            TokenService tokenService) {
        this.userAccountRepositoryProvider = userAccountRepositoryProvider;
        this.refreshTokenRepositoryProvider = refreshTokenRepositoryProvider;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        var userAccountRepository = userAccountRepository();
        var refreshTokenRepository = refreshTokenRepository();
        var normalizedEmail = request.email().trim().toLowerCase(Locale.ROOT);
        if (userAccountRepository.findByEmail(normalizedEmail).isPresent()) {
            throw new EmailAlreadyExistsException();
        }

        try {
            var user = userAccountRepository.saveAndFlush(new UserAccount(
                    normalizedEmail,
                    passwordEncoder.encode(request.password()),
                    normalizeDisplayName(request.displayName()),
                    request.sourceLang(),
                    request.targetLang(),
                    UserStatus.ACTIVE));

            return new AuthResponse(toProfile(user), tokenService.createAccessToken(user), createRefreshTokenFor(user));
        } catch (DataIntegrityViolationException exception) {
            throw new EmailAlreadyExistsException();
        }
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        var normalizedEmail = request.email().trim().toLowerCase(Locale.ROOT);
        var user = userAccountRepository().findByEmail(normalizedEmail)
                .filter(candidate -> candidate.getStatus() == UserStatus.ACTIVE)
                .filter(candidate -> passwordEncoder.matches(request.password(), candidate.getPasswordHash()))
                .orElseThrow(InvalidCredentialsException::new);

        return new AuthResponse(toProfile(user), tokenService.createAccessToken(user), createRefreshTokenFor(user));
    }

    @Transactional
    public TokenRefreshResponse refresh(RefreshRequest request) {
        var tokenHash = tokenService.sha256Hex(request.refreshToken());
        var refreshToken = refreshTokenRepository().findByTokenHash(tokenHash)
                .filter(token -> token.getRevokedAt() == null)
                .filter(token -> token.getExpiresAt().isAfter(OffsetDateTime.now()))
                .filter(token -> token.getUser().getStatus() == UserStatus.ACTIVE)
                .orElseThrow(InvalidRefreshTokenException::new);

        refreshToken.revoke(OffsetDateTime.now());
        refreshTokenRepository().saveAndFlush(refreshToken);

        var user = refreshToken.getUser();
        return new TokenRefreshResponse(tokenService.createAccessToken(user), createRefreshTokenFor(user));
    }

    @Transactional(readOnly = true)
    public UserProfileResponse currentUser(String userId) {
        var user = userAccountRepository().findById(UUID.fromString(userId))
                .filter(candidate -> candidate.getStatus() == UserStatus.ACTIVE)
                .orElseThrow(CurrentUserNotFoundException::new);

        return toProfile(user);
    }

    private String createRefreshTokenFor(UserAccount user) {
        var refreshToken = tokenService.createRefreshToken();
        refreshTokenRepository().saveAndFlush(new RefreshToken(
                user,
                tokenService.sha256Hex(refreshToken),
                tokenService.refreshTokenExpiresAt()));
        return refreshToken;
    }

    private UserProfileResponse toProfile(UserAccount user) {
        return new UserProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getDisplayName(),
                user.getSourceLang(),
                user.getTargetLang(),
                user.getStatus().databaseValue());
    }

    private String normalizeDisplayName(String displayName) {
        if (displayName == null || displayName.isBlank()) {
            return null;
        }
        return displayName.trim();
    }

    private UserAccountRepository userAccountRepository() {
        return userAccountRepositoryProvider.getIfAvailable(() -> {
            throw new IllegalStateException("UserAccountRepository is required for registration");
        });
    }

    private RefreshTokenRepository refreshTokenRepository() {
        return refreshTokenRepositoryProvider.getIfAvailable(() -> {
            throw new IllegalStateException("RefreshTokenRepository is required for registration");
        });
    }

    public static class EmailAlreadyExistsException extends RuntimeException {
    }

    public static class InvalidCredentialsException extends RuntimeException {
    }

    public static class InvalidRefreshTokenException extends RuntimeException {
    }

    public static class CurrentUserNotFoundException extends RuntimeException {
    }
}
