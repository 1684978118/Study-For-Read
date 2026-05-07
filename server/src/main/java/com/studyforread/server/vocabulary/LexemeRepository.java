package com.studyforread.server.vocabulary;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LexemeRepository extends JpaRepository<Lexeme, UUID> {

    Optional<Lexeme> findBySourceLangAndTargetLangAndNormalizedSurfaceAndEntryType(
            String sourceLang,
            String targetLang,
            String normalizedSurface,
            String entryType);
}
