package com.studyforread.server.vocabulary;

import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.vocabulary.dto.CreateVocabularyCardRequest;
import com.studyforread.server.vocabulary.dto.DueVocabularyCardsResponse;
import com.studyforread.server.vocabulary.dto.LexemeSummaryResponse;
import com.studyforread.server.vocabulary.dto.ReviewVocabularyCardRequest;
import com.studyforread.server.vocabulary.dto.VocabularyCardResponse;
import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VocabularyService {

    private final ObjectProvider<UserAccountRepository> userAccountRepositoryProvider;
    private final ObjectProvider<LexemeRepository> lexemeRepositoryProvider;
    private final ObjectProvider<UserWordCardRepository> userWordCardRepositoryProvider;
    private final ObjectProvider<EntityManager> entityManagerProvider;

    public VocabularyService(
            ObjectProvider<UserAccountRepository> userAccountRepositoryProvider,
            ObjectProvider<LexemeRepository> lexemeRepositoryProvider,
            ObjectProvider<UserWordCardRepository> userWordCardRepositoryProvider,
            ObjectProvider<EntityManager> entityManagerProvider) {
        this.userAccountRepositoryProvider = userAccountRepositoryProvider;
        this.lexemeRepositoryProvider = lexemeRepositoryProvider;
        this.userWordCardRepositoryProvider = userWordCardRepositoryProvider;
        this.entityManagerProvider = entityManagerProvider;
    }

    @Transactional
    public VocabularyCardResponse createCard(UUID userId, CreateVocabularyCardRequest request) {
        var userAccountRepository = required(userAccountRepositoryProvider);
        var lexemeRepository = required(lexemeRepositoryProvider);
        var userWordCardRepository = required(userWordCardRepositoryProvider);
        var user = userAccountRepository.findById(userId).orElseThrow(CurrentUserNotFoundException::new);

        if (WordCardType.LEXEME.databaseValue().equals(request.cardType())) {
            var lexemeId = request.lexemeId();
            var lexeme = lexemeRepository.findById(lexemeId).orElseThrow(LexemeNotFoundException::new);
            var card = userWordCardRepository.findByUserIdAndLexemeId(userId, lexemeId)
                    .orElseGet(() -> userWordCardRepository.saveAndFlush(new UserWordCard(
                            user,
                            lexeme,
                            WordCardType.LEXEME,
                            null,
                            null,
                            null,
                            request.sourceBookFingerprint(),
                            request.sourceBookTitle(),
                            ReviewStatus.NEW,
                            0,
                            null,
                            null)));
            return toResponse(card);
        }

        var card = userWordCardRepository.saveAndFlush(new UserWordCard(
                user,
                null,
                WordCardType.PRIVATE_SENTENCE,
                request.privateSurface(),
                request.privateDefinition(),
                request.privateContext(),
                request.sourceBookFingerprint(),
                request.sourceBookTitle(),
                ReviewStatus.NEW,
                0,
                null,
                null));
        return toResponse(card);
    }

    @Transactional(readOnly = true)
    public DueVocabularyCardsResponse listDueCards(UUID userId) {
        var userAccountRepository = required(userAccountRepositoryProvider);
        var userWordCardRepository = required(userWordCardRepositoryProvider);
        userAccountRepository.findById(userId).orElseThrow(CurrentUserNotFoundException::new);

        var items = userWordCardRepository.findDueCardsByUserId(userId, OffsetDateTime.now()).stream()
                .map(this::toResponse)
                .toList();
        return new DueVocabularyCardsResponse(items);
    }

    @Transactional
    public VocabularyCardResponse reviewCard(UUID userId, UUID cardId, ReviewVocabularyCardRequest request) {
        if (request == null || request.known() == null || request.reviewedAt() == null) {
            throw new InvalidReviewRequestException();
        }

        var userWordCardRepository = required(userWordCardRepositoryProvider);
        var entityManager = required(entityManagerProvider);
        var card = userWordCardRepository.findByUserIdAndId(userId, cardId)
                .orElseThrow(WordCardNotFoundException::new);
        var reviewCount = card.getReviewCount() + 1;
        var nextReviewAt = request.known()
                ? request.reviewedAt().plusDays(knownIntervalDays(reviewCount))
                : request.reviewedAt().plusDays(1);

        entityManager.createQuery("""
                        update UserWordCard card
                        set card.reviewStatus = :reviewStatus,
                            card.reviewCount = :reviewCount,
                            card.nextReviewAt = :nextReviewAt,
                            card.lastReviewedAt = :lastReviewedAt,
                            card.updatedAt = :updatedAt
                        where card.id = :cardId
                          and card.user.id = :userId
                        """)
                .setParameter("reviewStatus", ReviewStatus.LEARNING.databaseValue())
                .setParameter("reviewCount", reviewCount)
                .setParameter("nextReviewAt", nextReviewAt)
                .setParameter("lastReviewedAt", request.reviewedAt())
                .setParameter("updatedAt", OffsetDateTime.now())
                .setParameter("cardId", cardId)
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.flush();
        entityManager.clear();

        return toResponse(userWordCardRepository.findByUserIdAndId(userId, cardId)
                .orElseThrow(WordCardNotFoundException::new));
    }

    private int knownIntervalDays(int reviewCount) {
        if (reviewCount == 1) {
            return 3;
        }
        if (reviewCount == 2) {
            return 7;
        }
        if (reviewCount == 3) {
            return 15;
        }
        return 30;
    }

    private <T> T required(ObjectProvider<T> provider) {
        return provider.getIfAvailable(() -> {
            throw new IllegalStateException("Vocabulary persistence is not available");
        });
    }

    private VocabularyCardResponse toResponse(UserWordCard card) {
        var lexeme = card.getLexeme();
        var lexemeResponse = lexeme == null
                ? null
                : new LexemeSummaryResponse(
                        lexeme.getId(),
                        lexeme.getSurface(),
                        lexeme.getReading(),
                        lexeme.getDefinition());

        return new VocabularyCardResponse(
                card.getId(),
                card.getCardType().databaseValue(),
                lexemeResponse,
                card.getPrivateSurface(),
                card.getPrivateDefinition(),
                card.getReviewStatus().databaseValue(),
                card.getReviewCount(),
                card.getNextReviewAt(),
                card.getLastReviewedAt());
    }

    public static class CurrentUserNotFoundException extends RuntimeException {
    }

    public static class LexemeNotFoundException extends RuntimeException {
    }

    public static class WordCardNotFoundException extends RuntimeException {
    }

    public static class InvalidReviewRequestException extends RuntimeException {
    }
}
