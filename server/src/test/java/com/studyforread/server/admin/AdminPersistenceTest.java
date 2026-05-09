package com.studyforread.server.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.persistence.EntityManager;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class AdminPersistenceTest {

    @Autowired
    private AdminUserRepository adminUserRepository;

    @Autowired
    private AdminAuditLogRepository adminAuditLogRepository;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void usernameIsUniqueAndAdminCanBeLoadedByUsername() {
        adminUserRepository.saveAndFlush(newAdminUser("operations", AdminRole.ADMIN, AdminStatus.ACTIVE));

        var duplicate = newAdminUser("operations", AdminRole.OPERATOR, AdminStatus.ACTIVE);

        assertThat(adminUserRepository.findByUsername("operations")).isPresent();
        assertThatThrownBy(() -> adminUserRepository.saveAndFlush(duplicate))
                .isInstanceOf(Exception.class);
    }

    @Test
    void roleAcceptsOnlyAdminAndOperator() {
        assertThat(AdminRole.fromDatabaseValue("admin")).isEqualTo(AdminRole.ADMIN);
        assertThat(AdminRole.fromDatabaseValue("operator")).isEqualTo(AdminRole.OPERATOR);

        assertThatThrownBy(() -> insertAdminUserNative("invalid-role-admin", "super_admin", "active"))
                .isInstanceOf(Exception.class);
    }

    @Test
    void statusAcceptsOnlyActiveAndDisabled() {
        assertThat(AdminStatus.fromDatabaseValue("active")).isEqualTo(AdminStatus.ACTIVE);
        assertThat(AdminStatus.fromDatabaseValue("disabled")).isEqualTo(AdminStatus.DISABLED);

        assertThatThrownBy(() -> insertAdminUserNative("invalid-status-admin", "admin", "pending"))
                .isInstanceOf(Exception.class);
    }

    @Test
    void auditLogReferencesAdminUserWithDeleteRestrict() {
        var admin = adminUserRepository.saveAndFlush(newAdminUser("audit-owner", AdminRole.ADMIN, AdminStatus.ACTIVE));
        adminAuditLogRepository.saveAndFlush(new AdminAuditLog(
                admin,
                "lexeme.create",
                "lexeme",
                UUID.randomUUID(),
                "{\"surface\":\"kokoro\",\"redacted\":true}",
                "127.0.0.1"));
        entityManager.clear();

        var found = adminAuditLogRepository.findByAdminUserIdOrderByCreatedAtDesc(admin.getId());

        assertThat(found).hasSize(1);
        assertThat(found.getFirst().getAdminUser().getId()).isEqualTo(admin.getId());
        assertThat(found.getFirst().getDetailsJson()).contains("\"redacted\":true");
        assertThatThrownBy(() -> entityManager.createNativeQuery("delete from admin_users where id = :id")
                .setParameter("id", admin.getId())
                .executeUpdate())
                .isInstanceOf(Exception.class);
    }

    @Test
    void auditDetailsCanStoreRedactedJson() {
        var admin = adminUserRepository.saveAndFlush(newAdminUser("redacted-details", AdminRole.OPERATOR, AdminStatus.ACTIVE));
        var log = adminAuditLogRepository.saveAndFlush(new AdminAuditLog(
                admin,
                "user.disable",
                "user",
                UUID.randomUUID(),
                "{\"reason\":\"policy\",\"redacted\":true}",
                null));
        entityManager.clear();

        var found = adminAuditLogRepository.findById(log.getId()).orElseThrow();

        assertThat(found.getAction()).isEqualTo("user.disable");
        assertThat(found.getTargetType()).isEqualTo("user");
        assertThat(found.getDetailsJson()).contains("\"reason\":\"policy\"");
        assertThat(found.getDetailsJson()).contains("\"redacted\":true");
    }

    @Test
    void adminTablesDoNotContainSecretOrRawContentColumns() {
        var forbiddenColumns = Set.of(
                "password",
                "password_hash",
                "token",
                "token_hash",
                "content",
                "chapter_content",
                "raw_text",
                "translated_text",
                "paragraph_text");
        var columnNames = jdbcTemplate.queryForList(
                        """
                                select lower(column_name)
                                from information_schema.columns
                                where lower(table_name) in ('admin_users', 'admin_audit_logs')
                                """,
                        String.class)
                .stream()
                .toList();

        assertThat(columnNames).doesNotContainAnyElementsOf(forbiddenColumns);
    }

    @Test
    void lexemeCreatedByAdminIdReferencesAdminUsersWhenColumnExists() {
        var hasColumn = Boolean.TRUE.equals(jdbcTemplate.queryForObject(
                """
                        select count(*) > 0
                        from information_schema.columns
                        where lower(table_name) = 'lexemes'
                            and lower(column_name) = 'created_by_admin_id'
                        """,
                Boolean.class));

        if (!hasColumn) {
            return;
        }

        assertThatThrownBy(() -> insertLexemeWithAdminId(UUID.randomUUID()))
                .isInstanceOf(Exception.class);

        var admin = adminUserRepository.saveAndFlush(newAdminUser("lexeme-admin", AdminRole.ADMIN, AdminStatus.ACTIVE));
        var lexemeId = insertLexemeWithAdminId(admin.getId());
        entityManager.createNativeQuery("delete from admin_users where id = :id")
                .setParameter("id", admin.getId())
                .executeUpdate();
        entityManager.flush();

        var createdByAdminId = jdbcTemplate.queryForObject(
                "select created_by_admin_id from lexemes where id = ?",
                UUID.class,
                lexemeId);
        assertThat(createdByAdminId).isNull();
    }

    private AdminUser newAdminUser(String username, AdminRole role, AdminStatus status) {
        return new AdminUser(username, "hash-1", role, status);
    }

    private UUID insertAdminUserNative(String username, String role, String status) {
        var id = UUID.randomUUID();
        entityManager.createNativeQuery(
                        """
                                insert into admin_users (
                                    id, username, credential_hash, role, status, created_at, updated_at
                                ) values (
                                    :id, :username, 'hash-1', :role, :status, current_timestamp, current_timestamp
                                )
                                """)
                .setParameter("id", id)
                .setParameter("username", username)
                .setParameter("role", role)
                .setParameter("status", status)
                .executeUpdate();
        entityManager.flush();
        return id;
    }

    private UUID insertLexemeWithAdminId(UUID adminUserId) {
        var id = UUID.randomUUID();
        entityManager.createNativeQuery(
                        """
                                insert into lexemes (
                                    id,
                                    surface,
                                    normalized_surface,
                                    reading,
                                    source_lang,
                                    target_lang,
                                    entry_type,
                                    part_of_speech,
                                    definition,
                                    short_definition,
                                    example,
                                    status,
                                    created_by_admin_id,
                                    created_at,
                                    updated_at
                                ) values (
                                    :id,
                                    'Kokoro',
                                    :normalizedSurface,
                                    'kokoro',
                                    'ja',
                                    'zh-CN',
                                    'word',
                                    'noun',
                                    'definition',
                                    null,
                                    null,
                                    'active',
                                    :adminUserId,
                                    current_timestamp,
                                    current_timestamp
                                )
                                """)
                .setParameter("id", id)
                .setParameter("normalizedSurface", "kokoro-" + id)
                .setParameter("adminUserId", adminUserId)
                .executeUpdate();
        entityManager.flush();
        return id;
    }
}
