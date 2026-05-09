package com.studyforread.server.vocabulary;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LexemeRepository extends JpaRepository<Lexeme, UUID> {

    Optional<Lexeme> findBySourceLangAndTargetLangAndNormalizedSurfaceAndEntryType(
            String sourceLang,
            String targetLang,
            String normalizedSurface,
            String entryType);

    @Query("""
            select lexeme
            from Lexeme lexeme
            where (:query is null
                or lower(lexeme.surface) like concat('%', lower(:query), '%')
                or lower(lexeme.normalizedSurface) like concat('%', lower(:query), '%'))
              and (:sourceLang is null or lexeme.sourceLang = :sourceLang)
              and (:targetLang is null or lexeme.targetLang = :targetLang)
              and (:entryType is null or lexeme.entryType = :entryType)
              and (:status is null or lexeme.status = :status)
            """)
    Page<Lexeme> searchForAdmin(
            @Param("query") String query,
            @Param("sourceLang") String sourceLang,
            @Param("targetLang") String targetLang,
            @Param("entryType") String entryType,
            @Param("status") String status,
            Pageable pageable);
}
