package com.studyforread.server.vocabulary;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.persistence.EntityManager;
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
class LexemeRepositoryTest {

    @Autowired
    private LexemeRepository lexemeRepository;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private DataSource dataSource;

    @Test
    void activeWordLexemeCanBeFoundByLanguagePairNormalizedSurfaceAndEntryType() {
        var lexeme = new Lexeme(
                "kokoro",
                "kokoro",
                "kokoro",
                "ja",
                "zh-CN",
                LexemeEntryType.WORD,
                "noun",
                "heart; mind",
                "heart",
                null,
                LexemeStatus.ACTIVE);

        lexemeRepository.saveAndFlush(lexeme);
        entityManager.clear();

        var found = lexemeRepository.findBySourceLangAndTargetLangAndNormalizedSurfaceAndEntryType(
                "ja",
                "zh-CN",
                "kokoro",
                LexemeEntryType.WORD.databaseValue());

        assertThat(found).isPresent();
        assertThat(found.orElseThrow().getSurface()).isEqualTo("kokoro");
        assertThat(found.orElseThrow().getNormalizedSurface()).isEqualTo("kokoro");
        assertThat(found.orElseThrow().getReading()).isEqualTo("kokoro");
        assertThat(found.orElseThrow().getSourceLang()).isEqualTo("ja");
        assertThat(found.orElseThrow().getTargetLang()).isEqualTo("zh-CN");
        assertThat(found.orElseThrow().getEntryType()).isEqualTo(LexemeEntryType.WORD);
        assertThat(found.orElseThrow().getStatus()).isEqualTo(LexemeStatus.ACTIVE);
    }

    @Test
    void duplicateLanguagePairNormalizedSurfaceAndEntryTypeIsRejected() {
        lexemeRepository.saveAndFlush(newLexeme("kokoro", "kokoro", LexemeEntryType.WORD, LexemeStatus.ACTIVE));

        var duplicate = newLexeme("heart", "kokoro", LexemeEntryType.WORD, LexemeStatus.CANDIDATE);

        assertThatThrownBy(() -> lexemeRepository.saveAndFlush(duplicate))
                .isInstanceOf(Exception.class);
    }

    @Test
    void entryTypeRejectsUnsupportedValues() {
        assertThatThrownBy(() -> insertLexemeNative("verb", "active", "kokoro"))
                .isInstanceOf(Exception.class);
    }

    @Test
    void statusRejectsUnsupportedValues() {
        assertThatThrownBy(() -> insertLexemeNative("word", "pending", "kokoro"))
                .isInstanceOf(Exception.class);
    }

    @Test
    void normalizedSurfaceMustBeLowercaseTrimmed() {
        assertThatThrownBy(() -> insertLexemeNative("word", "active", " Kokoro "))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertLexemeNative("word", "active", "Kokoro"))
                .isInstanceOf(Exception.class);
    }

    @Test
    void lexemesTableDoesNotExposeUserReviewFields() throws Exception {
        var forbiddenJavaFields = Set.of("userId", "reviewState", "reviewStatus", "reviewCount", "nextReviewAt", "easeFactor");
        var entityFields = Arrays.stream(Lexeme.class.getDeclaredFields())
                .map(field -> field.getName())
                .collect(Collectors.toSet());

        assertThat(entityFields).doesNotContainAnyElementsOf(forbiddenJavaFields);

        var forbiddenColumns = Set.of(
                "user_id",
                "review_state",
                "review_status",
                "review_count",
                "next_review_at",
                "ease_factor");
        try (var connection = dataSource.getConnection()) {
            var columns = connection.getMetaData().getColumns(null, null, "lexemes", null);
            while (columns.next()) {
                assertThat(columns.getString("COLUMN_NAME")).isNotIn(forbiddenColumns);
            }
        }
    }

    private Lexeme newLexeme(
            String surface,
            String normalizedSurface,
            LexemeEntryType entryType,
            LexemeStatus status) {
        return new Lexeme(
                surface,
                normalizedSurface,
                null,
                "ja",
                "zh-CN",
                entryType,
                "noun",
                "definition",
                null,
                null,
                status);
    }

    private void insertLexemeNative(String entryType, String status, String normalizedSurface) {
        entityManager.createNativeQuery("""
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
                            created_at,
                            updated_at
                        ) values (
                            random_uuid(),
                            'Kokoro',
                            :normalizedSurface,
                            'kokoro',
                            'ja',
                            'zh-CN',
                            :entryType,
                            'noun',
                            'definition',
                            null,
                            null,
                            :status,
                            current_timestamp,
                            current_timestamp
                        )
                        """)
                .setParameter("normalizedSurface", normalizedSurface)
                .setParameter("entryType", entryType)
                .setParameter("status", status)
                .executeUpdate();
        entityManager.flush();
    }
}
