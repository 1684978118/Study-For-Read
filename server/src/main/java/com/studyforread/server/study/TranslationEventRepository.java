package com.studyforread.server.study;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TranslationEventRepository extends JpaRepository<TranslationEvent, UUID> {

    List<TranslationEvent> findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(
            UUID userId,
            OffsetDateTime start,
            OffsetDateTime end);
}
