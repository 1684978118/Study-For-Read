package com.studyforread.server.vocabulary;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserWordCardRepository extends JpaRepository<UserWordCard, UUID> {

    Optional<UserWordCard> findByUserIdAndId(UUID userId, UUID id);

    Optional<UserWordCard> findByUserIdAndLexemeId(UUID userId, UUID lexemeId);

    @Query("""
            select card
            from UserWordCard card
            where card.user.id = :userId
              and (card.nextReviewAt is null or card.nextReviewAt <= :now)
            """)
    List<UserWordCard> findDueCardsByUserId(@Param("userId") UUID userId, @Param("now") OffsetDateTime now);
}
