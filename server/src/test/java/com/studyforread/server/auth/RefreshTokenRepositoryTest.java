package com.studyforread.server.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class RefreshTokenRepositoryTest {

    private static final String TOKEN_HASH =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @Autowired
    private EntityManager entityManager;

    @Test
    void savesRefreshTokenAndFindsItByTokenHash() {
        var user = saveUser("token-owner@example.com");
        var token = new RefreshToken(user, TOKEN_HASH, OffsetDateTime.now().plusDays(30));

        refreshTokenRepository.saveAndFlush(token);
        entityManager.clear();

        var found = refreshTokenRepository.findByTokenHash(TOKEN_HASH);

        assertThat(found).isPresent();
        assertThat(found.orElseThrow().getTokenHash()).isEqualTo(TOKEN_HASH);
        assertThat(found.orElseThrow().getTokenHash()).hasSize(64);
    }

    @Test
    void revokedTokenHasRevokedAt() {
        var user = saveUser("revoked-token-owner@example.com");
        var token = new RefreshToken(user, TOKEN_HASH, OffsetDateTime.now().plusDays(30));

        token.revoke(OffsetDateTime.now());
        refreshTokenRepository.saveAndFlush(token);

        assertThat(token.getRevokedAt()).isNotNull();
    }

    @Test
    void rejectsTokenHashThatIsNotSha256HexLength() {
        var user = saveUser("short-token-owner@example.com");
        var shortTokenHash = "abc123";
        var token = new RefreshToken(user, shortTokenHash, OffsetDateTime.now().plusDays(30));

        assertThatThrownBy(() -> refreshTokenRepository.saveAndFlush(token))
                .isInstanceOf(Exception.class);
    }

    private UserAccount saveUser(String email) {
        return userAccountRepository.saveAndFlush(new UserAccount(
                email,
                "hash-1",
                "Reader",
                "ja",
                "zh-CN",
                UserStatus.ACTIVE));
    }
}
