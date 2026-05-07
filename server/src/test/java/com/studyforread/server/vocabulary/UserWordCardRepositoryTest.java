package com.studyforread.server.vocabulary;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
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
class UserWordCardRepositoryTest {

    private static final String SOURCE_BOOK_FINGERPRINT =
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    @Autowired
    private UserAccountRepository userAccountRepository;

    @Autowired
    private LexemeRepository lexemeRepository;

    @Autowired
    private UserWordCardRepository userWordCardRepository;

    @Autowired
    private EntityManager entityManager;

    @Test
    void userCanSaveLexemeCardLinkedToPublicLexeme() {
        var user = saveUser("card-owner@example.com");
        var lexeme = saveLexeme("kokoro", "kokoro");
        var card = new UserWordCard(
                user,
                lexeme,
                WordCardType.LEXEME,
                null,
                null,
                null,
                SOURCE_BOOK_FINGERPRINT,
                "Kokoro",
                ReviewStatus.NEW,
                0,
                null,
                null);

        userWordCardRepository.saveAndFlush(card);
        entityManager.clear();

        var foundById = userWordCardRepository.findByUserIdAndId(user.getId(), card.getId());
        var foundByLexeme = userWordCardRepository.findByUserIdAndLexemeId(user.getId(), lexeme.getId());

        assertThat(foundById).isPresent();
        assertThat(foundById.orElseThrow().getUser().getId()).isEqualTo(user.getId());
        assertThat(foundById.orElseThrow().getLexeme().getId()).isEqualTo(lexeme.getId());
        assertThat(foundById.orElseThrow().getCardType()).isEqualTo(WordCardType.LEXEME);
        assertThat(foundById.orElseThrow().getReviewStatus()).isEqualTo(ReviewStatus.NEW);
        assertThat(foundById.orElseThrow().getReviewCount()).isZero();
        assertThat(foundByLexeme).isPresent();
    }

    @Test
    void sameUserCannotSaveDuplicateCardForSameLexeme() {
        var user = saveUser("duplicate-card-owner@example.com");
        var lexeme = saveLexeme("hashiru", "hashiru");

        userWordCardRepository.saveAndFlush(newLexemeCard(user, lexeme, null));

        var duplicate = newLexemeCard(user, lexeme, null);

        assertThatThrownBy(() -> userWordCardRepository.saveAndFlush(duplicate))
                .isInstanceOf(Exception.class);
    }

    @Test
    void differentUsersCanSaveCardsForSameLexeme() {
        var firstUser = saveUser("first-card-owner@example.com");
        var secondUser = saveUser("second-card-owner@example.com");
        var lexeme = saveLexeme("taberu", "taberu");

        userWordCardRepository.saveAndFlush(newLexemeCard(firstUser, lexeme, null));
        userWordCardRepository.saveAndFlush(newLexemeCard(secondUser, lexeme, null));
        entityManager.clear();

        assertThat(userWordCardRepository.findByUserIdAndLexemeId(firstUser.getId(), lexeme.getId())).isPresent();
        assertThat(userWordCardRepository.findByUserIdAndLexemeId(secondUser.getId(), lexeme.getId())).isPresent();
    }

    @Test
    void privateSentenceCardRequiresPrivateSurfaceAndPrivateDefinition() {
        var user = saveUser("private-sentence-owner@example.com");

        assertThatThrownBy(() -> insertUserWordCardNative(
                        user,
                        null,
                        "private_sentence",
                        null,
                        "private meaning",
                        SOURCE_BOOK_FINGERPRINT,
                        0))
                .isInstanceOf(Exception.class);
        assertThatThrownBy(() -> insertUserWordCardNative(
                        user,
                        null,
                        "private_sentence",
                        "心が静かになる。",
                        null,
                        SOURCE_BOOK_FINGERPRINT,
                        0))
                .isInstanceOf(Exception.class);
    }

    @Test
    void lexemeCardRequiresLexemeId() {
        var user = saveUser("missing-lexeme-card-owner@example.com");

        assertThatThrownBy(() -> insertUserWordCardNative(
                        user,
                        null,
                        "lexeme",
                        null,
                        null,
                        SOURCE_BOOK_FINGERPRINT,
                        0))
                .isInstanceOf(Exception.class);
    }

    @Test
    void sourceBookFingerprintMustBeSha256HexWhenPresent() {
        var user = saveUser("fingerprint-card-owner@example.com");
        var lexeme = saveLexeme("miru", "miru");

        assertThatThrownBy(() -> insertUserWordCardNative(
                        user,
                        lexeme,
                        "lexeme",
                        null,
                        null,
                        "not-a-sha-256-fingerprint",
                        0))
                .isInstanceOf(Exception.class);
    }

    @Test
    void reviewCountRejectsNegativeValues() {
        var user = saveUser("negative-review-count-owner@example.com");
        var lexeme = saveLexeme("kiku", "kiku");

        assertThatThrownBy(() -> insertUserWordCardNative(
                        user,
                        lexeme,
                        "lexeme",
                        null,
                        null,
                        SOURCE_BOOK_FINGERPRINT,
                        -1))
                .isInstanceOf(Exception.class);
    }

    @Test
    void dueCardQueryReturnsOnlyCurrentUsersDueCards() {
        var currentUser = saveUser("current-due-card-owner@example.com");
        var otherUser = saveUser("other-due-card-owner@example.com");
        var dueLexeme = saveLexeme("asa", "asa");
        var nullDueLexeme = saveLexeme("hiru", "hiru");
        var futureLexeme = saveLexeme("yoru", "yoru");
        var otherUserLexeme = saveLexeme("yume", "yume");
        var now = OffsetDateTime.now();

        userWordCardRepository.saveAndFlush(newLexemeCard(currentUser, dueLexeme, now.minusMinutes(1)));
        userWordCardRepository.saveAndFlush(newLexemeCard(currentUser, nullDueLexeme, null));
        userWordCardRepository.saveAndFlush(newLexemeCard(currentUser, futureLexeme, now.plusDays(1)));
        userWordCardRepository.saveAndFlush(newLexemeCard(otherUser, otherUserLexeme, now.minusMinutes(1)));
        entityManager.clear();

        var dueCards = userWordCardRepository.findDueCardsByUserId(currentUser.getId(), now);

        assertThat(dueCards)
                .extracting(card -> card.getLexeme().getId())
                .containsExactlyInAnyOrder(dueLexeme.getId(), nullDueLexeme.getId());
        assertThat(dueCards).extracting(card -> card.getUser().getId()).containsOnly(currentUser.getId());
    }

    private UserWordCard newLexemeCard(UserAccount user, Lexeme lexeme, OffsetDateTime nextReviewAt) {
        return new UserWordCard(
                user,
                lexeme,
                WordCardType.LEXEME,
                null,
                null,
                null,
                SOURCE_BOOK_FINGERPRINT,
                "Kokoro",
                ReviewStatus.NEW,
                0,
                nextReviewAt,
                null);
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

    private Lexeme saveLexeme(String surface, String normalizedSurface) {
        return lexemeRepository.saveAndFlush(new Lexeme(
                surface,
                normalizedSurface,
                null,
                "ja",
                "zh-CN",
                LexemeEntryType.WORD,
                "noun",
                "definition",
                null,
                null,
                LexemeStatus.ACTIVE));
    }

    private void insertUserWordCardNative(
            UserAccount user,
            Lexeme lexeme,
            String cardType,
            String privateSurface,
            String privateDefinition,
            String sourceBookFingerprint,
            int reviewCount) {
        entityManager.createNativeQuery("""
                        insert into user_word_cards (
                            id,
                            user_id,
                            lexeme_id,
                            card_type,
                            private_surface,
                            private_definition,
                            private_context,
                            source_book_fingerprint,
                            source_book_title,
                            review_status,
                            review_count,
                            next_review_at,
                            last_reviewed_at,
                            created_at,
                            updated_at
                        ) values (
                            random_uuid(),
                            :userId,
                            :lexemeId,
                            :cardType,
                            :privateSurface,
                            :privateDefinition,
                            null,
                            :sourceBookFingerprint,
                            'Kokoro',
                            'new',
                            :reviewCount,
                            null,
                            null,
                            current_timestamp,
                            current_timestamp
                        )
                        """)
                .setParameter("userId", user.getId())
                .setParameter("lexemeId", lexeme == null ? null : lexeme.getId())
                .setParameter("cardType", cardType)
                .setParameter("privateSurface", privateSurface)
                .setParameter("privateDefinition", privateDefinition)
                .setParameter("sourceBookFingerprint", sourceBookFingerprint)
                .setParameter("reviewCount", reviewCount)
                .executeUpdate();
        entityManager.flush();
    }
}
