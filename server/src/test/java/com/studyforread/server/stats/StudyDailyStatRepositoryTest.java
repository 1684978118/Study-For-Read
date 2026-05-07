package com.studyforread.server.stats;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import jakarta.persistence.EntityManager;
import java.sql.DatabaseMetaData;
import java.time.LocalDate;
import java.util.Set;
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
class StudyDailyStatRepositoryTest {

    private static final LocalDate STAT_DATE = LocalDate.of(2026, 5, 5);
    private static final LocalDate OTHER_STAT_DATE = LocalDate.of(2026, 5, 6);

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private StudyDailyStatRepository studyDailyStatRepository;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private DataSource dataSource;

    @Test
    void savesOneDailyStatForOneUserAndDate() {
        var user = saveUser("stats-owner@example.com");
        var stat = new StudyDailyStat(
                user,
                STAT_DATE,
                12,
                8,
                3,
                2,
                5);

        studyDailyStatRepository.saveAndFlush(stat);
        entityManager.clear();

        var found = studyDailyStatRepository.findByUserIdAndStatDate(user.getId(), STAT_DATE);

        assertThat(found).isPresent();
        assertThat(found.orElseThrow().getUser().getId()).isEqualTo(user.getId());
        assertThat(found.orElseThrow().getStatDate()).isEqualTo(STAT_DATE);
        assertThat(found.orElseThrow().getReadingMinutes()).isEqualTo(12);
        assertThat(found.orElseThrow().getLookupCount()).isEqualTo(8);
        assertThat(found.orElseThrow().getParagraphTranslationCount()).isEqualTo(3);
        assertThat(found.orElseThrow().getCardsCreated()).isEqualTo(2);
        assertThat(found.orElseThrow().getCardsReviewed()).isEqualTo(5);
    }

    @Test
    void rejectsDuplicateUserIdAndStatDate() {
        var user = saveUser("duplicate-stat-owner@example.com");
        insertStudyDailyStatNative(user.getId(), STAT_DATE, 1, 2, 3, 4, 5);

        assertThatThrownBy(() -> insertStudyDailyStatNative(user.getId(), STAT_DATE, 6, 7, 8, 9, 10))
                .isInstanceOf(Exception.class);
    }

    @Test
    void rejectsNegativeCounterValues() {
        var user = saveUser("negative-stat-owner@example.com");

        assertThatThrownBy(() -> insertStudyDailyStatNative(user.getId(), STAT_DATE, -1, 0, 0, 0, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertStudyDailyStatNative(user.getId(), STAT_DATE, 0, -1, 0, 0, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertStudyDailyStatNative(user.getId(), STAT_DATE, 0, 0, -1, 0, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertStudyDailyStatNative(user.getId(), STAT_DATE, 0, 0, 0, -1, 0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertStudyDailyStatNative(user.getId(), STAT_DATE, 0, 0, 0, 0, -1))
                .isInstanceOf(Exception.class);
    }

    @Test
    void allowsZeroCounters() {
        var user = saveUser("zero-stat-owner@example.com");

        var stat = new StudyDailyStat(user, STAT_DATE, 0, 0, 0, 0, 0);
        studyDailyStatRepository.saveAndFlush(stat);
        entityManager.clear();

        var found = studyDailyStatRepository.findByUserIdAndStatDate(user.getId(), STAT_DATE);
        assertThat(found).isPresent();
        assertThat(found.orElseThrow().getReadingMinutes()).isZero();
        assertThat(found.orElseThrow().getLookupCount()).isZero();
        assertThat(found.orElseThrow().getParagraphTranslationCount()).isZero();
        assertThat(found.orElseThrow().getCardsCreated()).isZero();
        assertThat(found.orElseThrow().getCardsReviewed()).isZero();
    }

    @Test
    void deletingUserCascadesToDailyStats() {
        var user = saveUser("cascade-stat-owner@example.com");
        insertStudyDailyStatNative(user.getId(), STAT_DATE, 1, 1, 1, 1, 1);

        userAccountRepository.delete(user);
        userAccountRepository.flush();
        entityManager.clear();

        assertThat(studyDailyStatRepository.findByUserIdAndStatDate(user.getId(), STAT_DATE)).isEmpty();
        assertThat(studyDailyStatRepository.findByUserIdOrderByStatDateDesc(user.getId())).isEmpty();
    }

    @Test
    void studyDailyStatsTableDoesNotContainForbiddenContentColumns() throws Exception {
        var forbiddenColumns = Set.of(
                "content",
                "chapter_content",
                "original_file",
                "file_path",
                "source_text",
                "raw_text",
                "translated_text",
                "paragraph_text");

        try (var connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            var columns = metaData.getColumns(null, null, "study_daily_stats", null);
            while (columns.next()) {
                assertThat(columns.getString("COLUMN_NAME").toLowerCase()).isNotIn(forbiddenColumns);
            }
        }
    }

    @Test
    void repositoryQueryByUserReturnsOnlyCurrentUsersRowsOrderedByStatDateDesc() {
        var firstUser = saveUser("first-stat-reader@example.com");
        var secondUser = saveUser("second-stat-reader@example.com");

        studyDailyStatRepository.saveAndFlush(new StudyDailyStat(firstUser, STAT_DATE, 10, 1, 2, 3, 4));
        studyDailyStatRepository.saveAndFlush(new StudyDailyStat(firstUser, OTHER_STAT_DATE, 20, 5, 6, 7, 8));
        studyDailyStatRepository.saveAndFlush(new StudyDailyStat(secondUser, STAT_DATE, 30, 9, 10, 11, 12));
        entityManager.clear();

        var stats = studyDailyStatRepository.findByUserIdOrderByStatDateDesc(firstUser.getId());

        assertThat(stats).extracting(StudyDailyStat::getStatDate).containsExactly(OTHER_STAT_DATE, STAT_DATE);
        assertThat(stats).extracting(stat -> stat.getUser().getId()).containsOnly(firstUser.getId());
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

    private void insertStudyDailyStatNative(
            java.util.UUID userId,
            LocalDate statDate,
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
        entityManager.createNativeQuery("""
                        insert into study_daily_stats (
                            id,
                            user_id,
                            stat_date,
                            reading_minutes,
                            lookup_count,
                            paragraph_translation_count,
                            cards_created,
                            cards_reviewed,
                            created_at,
                            updated_at
                        ) values (
                            random_uuid(),
                            :userId,
                            :statDate,
                            :readingMinutes,
                            :lookupCount,
                            :paragraphTranslationCount,
                            :cardsCreated,
                            :cardsReviewed,
                            current_timestamp,
                            current_timestamp
                        )
                        """)
                .setParameter("userId", userId)
                .setParameter("statDate", statDate)
                .setParameter("readingMinutes", readingMinutes)
                .setParameter("lookupCount", lookupCount)
                .setParameter("paragraphTranslationCount", paragraphTranslationCount)
                .setParameter("cardsCreated", cardsCreated)
                .setParameter("cardsReviewed", cardsReviewed)
                .executeUpdate();
        entityManager.flush();
    }
}
