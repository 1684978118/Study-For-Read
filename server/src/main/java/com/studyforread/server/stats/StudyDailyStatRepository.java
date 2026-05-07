package com.studyforread.server.stats;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudyDailyStatRepository extends JpaRepository<StudyDailyStat, UUID> {

    Optional<StudyDailyStat> findByUserIdAndStatDate(UUID userId, LocalDate statDate);

    List<StudyDailyStat> findByUserIdOrderByStatDateDesc(UUID userId);
}
