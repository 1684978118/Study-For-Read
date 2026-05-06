package com.studyforread.server.auth;

import com.studyforread.server.auth.dto.AuthResponse;
import com.studyforread.server.auth.dto.RegisterRequest;
import com.studyforread.server.auth.dto.UserProfileResponse;
import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import java.util.Locale;
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

            var refreshToken = tokenService.createRefreshToken();
            refreshTokenRepository.saveAndFlush(new RefreshToken(
                    user,
                    tokenService.sha256Hex(refreshToken),
                    tokenService.refreshTokenExpiresAt()));

            return new AuthResponse(toProfile(user), tokenService.createAccessToken(user), refreshToken);
        } catch (DataIntegrityViolationException exception) {
            throw new EmailAlreadyExistsException();
        }
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
}
