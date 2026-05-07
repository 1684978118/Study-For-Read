package com.studyforread.server.study;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
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
class TranslationEventRepositoryTest {

    private static final String SHA256_HEX =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void savingWordLookupEventStoresSha256HexHashOnly() {
        var user = saveUser("word-lookup-event-owner@example.com");
        var event = new TranslationEvent(
                user,
                TranslationRequestType.WORD_LOOKUP,
                "ja",
                "zh-CN",
                "public_lexeme",
                SHA256_HEX,
                4,
                true,
                null);

        translationEventRepository.saveAndFlush(event);
        entityManager.clear();

        var found = translationEventRepository.findById(event.getId()).orElseThrow();
        assertThat(found.getRequestType()).isEqualTo(TranslationRequestType.WORD_LOOKUP);
        assertThat(found.getSourceTextHash()).matches("[0-9a-f]{64}");
        assertThat(found.getSourceTextHash()).isEqualTo(SHA256_HEX);
        assertThat(found.getSourceTextLength()).isEqualTo(4);
        assertThat(found.isSuccess()).isTrue();
    }

    @Test
    void sourceTextLengthMustBePositive() {
        var user = saveUser("invalid-length-event-owner@example.com");

        assertThatThrownBy(() -> insertTranslationEventNative(
                        user.getId(),
                        "word_lookup",
                        SHA256_HEX,
                        0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertTranslationEventNative(
                        user.getId(),
                        "word_lookup",
                        SHA256_HEX,
                        -1))
                .isInstanceOf(Exception.class);
    }

    @Test
    void requestTypeRejectsUnsupportedValues() {
        var user = saveUser("invalid-request-type-owner@example.com");

        assertThatThrownBy(() -> insertTranslationEventNative(
                        user.getId(),
                        "full_book_translation",
                        SHA256_HEX,
                        12))
                .isInstanceOf(Exception.class);
    }

    @Test
    void sourceTextHashMustBeSha256Hex() {
        var user = saveUser("invalid-hash-event-owner@example.com");

        assertThatThrownBy(() -> insertTranslationEventNative(
                        user.getId(),
                        "word_lookup",
                        "not-a-sha-256-hash",
                        12))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertTranslationEventNative(
                        user.getId(),
                        "word_lookup",
                        "ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
                        12))
                .isInstanceOf(Exception.class);
    }

    @Test
    void translationEventsTableDoesNotContainRawOrTranslatedTextColumns() {
        var forbiddenColumns = Set.of(
                "source_text",
                "raw_text",
                "translated_text",
                "paragraph_text",
                "chapter_content");
        var columnNames = jdbcTemplate.queryForList(
                        """
                                select lower(column_name)
                                from information_schema.columns
                                where lower(table_name) = 'translation_events'
                                """,
                        String.class)
                .stream()
                .toList();

        assertThat(columnNames).doesNotContainAnyElementsOf(forbiddenColumns);
    }

    @Test
    void queryByUserAndCreatedTimeReturnsOnlyThatUsersEvents() {
        var currentUser = saveUser("current-event-owner@example.com");
        var otherUser = saveUser("other-event-owner@example.com");
        var start = OffsetDateTime.parse("2026-05-01T00:00:00Z");
        var insideRange = OffsetDateTime.parse("2026-05-02T12:00:00Z");
        var outsideRange = OffsetDateTime.parse("2026-05-05T12:00:00Z");
        var end = OffsetDateTime.parse("2026-05-03T00:00:00Z");
        var currentEventId = insertTranslationEventNative(
                currentUser.getId(),
                "word_lookup",
                SHA256_HEX,
                4,
                insideRange);
        insertTranslationEventNative(
                currentUser.getId(),
                "paragraph_translation",
                "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
                24,
                outsideRange);
        insertTranslationEventNative(
                otherUser.getId(),
                "annotation",
                "1111111111111111111111111111111111111111111111111111111111111111",
                8,
                insideRange);
        entityManager.clear();

        var found = translationEventRepository.findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(
                currentUser.getId(),
                start,
                end);

        assertThat(found).hasSize(1);
        assertThat(found.getFirst().getId()).isEqualTo(currentEventId);
        assertThat(found.getFirst().getUser().getId()).isEqualTo(currentUser.getId());
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

    private UUID insertTranslationEventNative(
            UUID userId,
            String requestType,
            String sourceTextHash,
            int sourceTextLength) {
        return insertTranslationEventNative(
                userId,
                requestType,
                sourceTextHash,
                sourceTextLength,
                OffsetDateTime.now());
    }

    private UUID insertTranslationEventNative(
            UUID userId,
            String requestType,
            String sourceTextHash,
            int sourceTextLength,
            OffsetDateTime createdAt) {
        var id = UUID.randomUUID();
        entityManager.createNativeQuery(
                        """
                                insert into translation_events (
                                    id,
                                    user_id,
                                    request_type,
                                    source_lang,
                                    target_lang,
                                    provider,
                                    source_text_hash,
                                    source_text_length,
                                    success,
                                    error_code,
                                    created_at
                                ) values (
                                    :id,
                                    :userId,
                                    :requestType,
                                    'ja',
                                    'zh-CN',
                                    'test_provider',
                                    :sourceTextHash,
                                    :sourceTextLength,
                                    true,
                                    null,
                                    :createdAt
                                )
                                """)
                .setParameter("id", id)
                .setParameter("userId", userId)
                .setParameter("requestType", requestType)
                .setParameter("sourceTextHash", sourceTextHash)
                .setParameter("sourceTextLength", sourceTextLength)
                .setParameter("createdAt", createdAt)
                .executeUpdate();
        entityManager.flush();
        return id;
    }
}
