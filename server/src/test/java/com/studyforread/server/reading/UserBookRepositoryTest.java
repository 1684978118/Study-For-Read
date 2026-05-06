package com.studyforread.server.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import jakarta.persistence.EntityManager;
import java.sql.DatabaseMetaData;
import java.time.OffsetDateTime;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import javax.sql.DataSource;
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
class UserBookRepositoryTest {

    private static final String BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private static final String SECOND_BOOK_FINGERPRINT =
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private UserBookRepository userBookRepository;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private DataSource dataSource;

    @Test
    void savesUserBookAndFindsItByUserIdAndBookFingerprint() {
        var user = saveUser("book-owner@example.com");
        var book = new UserBook(
                user,
                BOOK_FINGERPRINT,
                "Kokoro",
                "Natsume Soseki",
                BookFileType.TXT,
                "ja",
                "zh-CN",
                42,
                3,
                12,
                48,
                OffsetDateTime.now());

        userBookRepository.saveAndFlush(book);
        entityManager.clear();

        var found = userBookRepository.findByUserIdAndBookFingerprint(user.getId(), BOOK_FINGERPRINT);

        assertThat(found).isPresent();
        assertThat(found.orElseThrow().getBookFingerprint()).isEqualTo(BOOK_FINGERPRINT);
        assertThat(found.orElseThrow().getBookFingerprint()).hasSize(64);
        assertThat(found.orElseThrow().getFileType()).isEqualTo(BookFileType.TXT);
        assertThat(found.orElseThrow().getTitle()).isEqualTo("Kokoro");
        assertThat(found.orElseThrow().getCurrentChapterIndex()).isEqualTo(3);
        assertThat(found.orElseThrow().getCurrentParagraphIndex()).isEqualTo(12);
        assertThat(found.orElseThrow().getCurrentCharOffset()).isEqualTo(48);
    }

    @Test
    void rejectsDuplicateUserIdAndBookFingerprint() {
        var user = saveUser("duplicate-book-owner@example.com");
        userBookRepository.saveAndFlush(newBook(user, BOOK_FINGERPRINT, "Kokoro", OffsetDateTime.now()));

        var duplicate = newBook(user, BOOK_FINGERPRINT, "Kokoro Again", OffsetDateTime.now().plusHours(1));

        assertThatThrownBy(() -> userBookRepository.saveAndFlush(duplicate))
                .isInstanceOf(Exception.class);
    }

    @Test
    void queryingByUserReturnsOnlyThatUsersBooksOrderedByLastReadAtDescending() {
        var firstUser = saveUser("first-reader@example.com");
        var secondUser = saveUser("second-reader@example.com");
        var older = newBook(firstUser, BOOK_FINGERPRINT, "Older", OffsetDateTime.now().minusDays(1));
        var newer = newBook(firstUser, SECOND_BOOK_FINGERPRINT, "Newer", OffsetDateTime.now());
        var otherUsersBook = newBook(secondUser, BOOK_FINGERPRINT, "Other User", OffsetDateTime.now().plusDays(1));

        userBookRepository.saveAndFlush(older);
        userBookRepository.saveAndFlush(newer);
        userBookRepository.saveAndFlush(otherUsersBook);
        entityManager.clear();

        var books = userBookRepository.findByUserIdOrderByLastReadAtDesc(firstUser.getId());

        assertThat(books).extracting(UserBook::getTitle).containsExactly("Newer", "Older");
        assertThat(books).extracting(book -> book.getUser().getId()).containsOnly(firstUser.getId());
    }

    @Test
    void entityAndMigrationDoNotExposeOriginalContentFields() throws Exception {
        var forbiddenJavaFields = Set.of("content", "chapterContent", "originalFile", "filePath");
        var entityFields = Arrays.stream(UserBook.class.getDeclaredFields())
                .map(field -> field.getName())
                .collect(Collectors.toSet());

        assertThat(entityFields).doesNotContainAnyElementsOf(forbiddenJavaFields);

        var forbiddenColumns = Set.of("content", "chapter_content", "original_file", "file_path");
        try (var connection = dataSource.getConnection()) {
            var columns = connection.getMetaData().getColumns(null, null, "user_books", null);
            while (columns.next()) {
                assertThat(columns.getString("COLUMN_NAME")).isNotIn(forbiddenColumns);
            }
        }
    }

    @Test
    void bookFingerprintColumnIsChar64() throws Exception {
        try (var connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            var columns = metaData.getColumns(null, null, "user_books", "book_fingerprint");

            assertThat(columns.next()).isTrue();
            assertThat(columns.getString("TYPE_NAME").toLowerCase()).contains("char");
            assertThat(columns.getInt("COLUMN_SIZE")).isEqualTo(64);
        }
    }

    @Test
    void fileTypeRejectsValuesOutsideTxtAndEpub() {
        var user = saveUser("invalid-file-type-owner@example.com");

        assertThatThrownBy(() -> insertUserBookNative(user, "pdf", 1, 0, 0, 0))
                .isInstanceOf(Exception.class);
    }

    @Test
    void chapterCountRejectsValuesBelowOne() {
        var user = saveUser("invalid-chapter-count-owner@example.com");

        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 0, 0, 0, 0))
                .isInstanceOf(Exception.class);
    }

    @Test
    void progressIndexesAndOffsetsRejectNegativeValues() {
        var user = saveUser("invalid-progress-owner@example.com");

        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 1, -1, 0, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 1, 0, -1, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertUserBookNative(user, "txt", 1, 0, 0, -1))
                .isInstanceOf(Exception.class);
    }

    private UserBook newBook(UserAccount user, String bookFingerprint, String title, OffsetDateTime lastReadAt) {
        return new UserBook(
                user,
                bookFingerprint,
                title,
                "Natsume Soseki",
                BookFileType.TXT,
                "ja",
                "zh-CN",
                42,
                0,
                0,
                0,
                lastReadAt);
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

    private void insertUserBookNative(
            UserAccount user,
            String fileType,
            int chapterCount,
            int currentChapterIndex,
            int currentParagraphIndex,
            int currentCharOffset) {
        entityManager.createNativeQuery("""
                        insert into user_books (
                            id,
                            user_id,
                            book_fingerprint,
                            title,
                            author,
                            file_type,
                            source_lang,
                            target_lang,
                            chapter_count,
                            current_chapter_index,
                            current_paragraph_index,
                            current_char_offset,
                            last_read_at,
                            created_at,
                            updated_at
                        ) values (
                            random_uuid(),
                            :userId,
                            :bookFingerprint,
                            'Kokoro',
                            'Natsume Soseki',
                            :fileType,
                            'ja',
                            'zh-CN',
                            :chapterCount,
                            :currentChapterIndex,
                            :currentParagraphIndex,
                            :currentCharOffset,
                            current_timestamp,
                            current_timestamp,
                            current_timestamp
                        )
                        """)
                .setParameter("userId", user.getId())
                .setParameter("bookFingerprint", BOOK_FINGERPRINT)
                .setParameter("fileType", fileType)
                .setParameter("chapterCount", chapterCount)
                .setParameter("currentChapterIndex", currentChapterIndex)
                .setParameter("currentParagraphIndex", currentParagraphIndex)
                .setParameter("currentCharOffset", currentCharOffset)
                .executeUpdate();
        entityManager.flush();
    }
}
