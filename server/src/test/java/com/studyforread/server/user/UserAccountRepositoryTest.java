package com.studyforread.server.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.persistence.EntityManager;
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
class UserAccountRepositoryTest {

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private EntityManager entityManager;

    @Test
    void savesLowerCaseEmailAndFindsItByEmail() {
        var user = new UserAccount(
                "reader@example.com",
                "hash-1",
                "Reader",
                "ja",
                "zh-CN",
                UserStatus.ACTIVE);

        userAccountRepository.saveAndFlush(user);
        entityManager.clear();

        var found = userAccountRepository.findByEmail("reader@example.com");

        assertThat(found).isPresent();
        assertThat(found.orElseThrow().getEmail()).isEqualTo("reader@example.com");
    }

    @Test
    void rejectsDuplicateEmail() {
        userAccountRepository.saveAndFlush(new UserAccount(
                "duplicate@example.com",
                "hash-1",
                "Reader One",
                "ja",
                "zh-CN",
                UserStatus.ACTIVE));

        var duplicate = new UserAccount(
                "duplicate@example.com",
                "hash-2",
                "Reader Two",
                "ja",
                "zh-CN",
                UserStatus.ACTIVE);

        assertThatThrownBy(() -> userAccountRepository.saveAndFlush(duplicate))
                .isInstanceOf(Exception.class);
    }

    @Test
    void rejectsStatusOutsideActiveAndDisabled() {
        assertThatThrownBy(() -> entityManager.createNativeQuery("""
                        insert into users (
                            id, email, password_hash, display_name, source_lang, target_lang, status, created_at, updated_at
                        ) values (
                            random_uuid(),
                            'invalid-status@example.com',
                            'hash-1',
                            'Reader',
                            'ja',
                            'zh-CN',
                            'pending',
                            current_timestamp,
                            current_timestamp
                        )
                        """)
                .executeUpdate())
                .isInstanceOf(Exception.class);
    }
}
