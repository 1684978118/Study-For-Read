package com.studyforread.server.stats;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StudyDailyStatRepository extends JpaRepository<StudyDailyStat, UUID> {

    Optional<StudyDailyStat> findByUserIdAndStatDate(UUID userId, LocalDate statDate);

    List<StudyDailyStat> findByUserIdOrderByStatDateDesc(UUID userId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("""
            update StudyDailyStat stat
            set stat.readingMinutes = stat.readingMinutes + :readingMinutes,
                stat.lookupCount = stat.lookupCount + :lookupCount,
                stat.paragraphTranslationCount =
                    stat.paragraphTranslationCount + :paragraphTranslationCount,
                stat.cardsCreated = stat.cardsCreated + :cardsCreated,
                stat.cardsReviewed = stat.cardsReviewed + :cardsReviewed,
                stat.updatedAt = :updatedAt
            where stat.id = :id
            """)
    int incrementCounters(
            @Param("id") UUID id,
            @Param("readingMinutes") int readingMinutes,
            @Param("lookupCount") int lookupCount,
            @Param("paragraphTranslationCount") int paragraphTranslationCount,
            @Param("cardsCreated") int cardsCreated,
            @Param("cardsReviewed") int cardsReviewed,
            @Param("updatedAt") OffsetDateTime updatedAt);

    @Query("""
            select coalesce(sum(stat.readingMinutes), 0) as readingMinutes,
                   coalesce(sum(stat.lookupCount), 0) as lookupCount,
                   coalesce(sum(stat.paragraphTranslationCount), 0) as paragraphTranslationCount,
                   coalesce(sum(stat.cardsCreated), 0) as cardsCreated,
                   coalesce(sum(stat.cardsReviewed), 0) as cardsReviewed
            from StudyDailyStat stat
            """)
    PlatformStatsTotals sumPlatformTotals();

    interface PlatformStatsTotals {
        long getReadingMinutes();

        long getLookupCount();

        long getParagraphTranslationCount();

        long getCardsCreated();

        long getCardsReviewed();
    }
}
