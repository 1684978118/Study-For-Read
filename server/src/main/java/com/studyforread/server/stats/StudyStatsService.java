package com.studyforread.server.stats;

import com.studyforread.server.stats.dto.AddDailyStatsRequest;
import com.studyforread.server.stats.dto.DailyStatsResponse;
import com.studyforread.server.stats.dto.StudySummaryResponse;
import com.studyforread.server.user.UserAccountRepository;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StudyStatsService {

    private final ObjectProvider<StudyDailyStatRepository> studyDailyStatRepositoryProvider;
    private final ObjectProvider<UserAccountRepository> userAccountRepositoryProvider;

    public StudyStatsService(
            ObjectProvider<StudyDailyStatRepository> studyDailyStatRepositoryProvider,
            ObjectProvider<UserAccountRepository> userAccountRepositoryProvider) {
        this.studyDailyStatRepositoryProvider = studyDailyStatRepositoryProvider;
        this.userAccountRepositoryProvider = userAccountRepositoryProvider;
    }

    @Transactional
    public DailyStatsResponse addDailyStats(UUID userId, AddDailyStatsRequest request) {
        var studyDailyStatRepository = required(studyDailyStatRepositoryProvider);
        var userAccountRepository = required(userAccountRepositoryProvider);
        var user = userAccountRepository.findById(userId).orElseThrow(CurrentUserNotFoundException::new);
        var existing = studyDailyStatRepository.findByUserIdAndStatDate(userId, request.statDate());
        if (existing.isEmpty()) {
            var created = studyDailyStatRepository.saveAndFlush(new StudyDailyStat(
                    user,
                    request.statDate(),
                    request.readingMinutes(),
                    request.lookupCount(),
                    request.paragraphTranslationCount(),
                    request.cardsCreated(),
                    request.cardsReviewed()));
            return toResponse(created);
        }

        var stat = existing.orElseThrow();
        guardNoOverflow(stat, request);
        studyDailyStatRepository.incrementCounters(
                stat.getId(),
                request.readingMinutes(),
                request.lookupCount(),
                request.paragraphTranslationCount(),
                request.cardsCreated(),
                request.cardsReviewed(),
                OffsetDateTime.now());
        var updated = studyDailyStatRepository.findById(stat.getId()).orElseThrow();
        return toResponse(updated);
    }

    @Transactional(readOnly = true)
    public StudySummaryResponse getSummary(UUID userId) {
        var studyDailyStatRepository = required(studyDailyStatRepositoryProvider);
        var userAccountRepository = required(userAccountRepositoryProvider);
        if (!userAccountRepository.existsById(userId)) {
            throw new CurrentUserNotFoundException();
        }

        long readingMinutes = 0;
        long lookupCount = 0;
        long paragraphTranslationCount = 0;
        long cardsCreated = 0;
        long cardsReviewed = 0;

        for (var stat : studyDailyStatRepository.findByUserIdOrderByStatDateDesc(userId)) {
            readingMinutes += stat.getReadingMinutes();
            lookupCount += stat.getLookupCount();
            paragraphTranslationCount += stat.getParagraphTranslationCount();
            cardsCreated += stat.getCardsCreated();
            cardsReviewed += stat.getCardsReviewed();
        }

        return new StudySummaryResponse(
                readingMinutes,
                lookupCount,
                paragraphTranslationCount,
                cardsCreated,
                cardsReviewed);
    }

    private void guardNoOverflow(StudyDailyStat stat, AddDailyStatsRequest request) {
        if (overflows(stat.getReadingMinutes(), request.readingMinutes())
                || overflows(stat.getLookupCount(), request.lookupCount())
                || overflows(stat.getParagraphTranslationCount(), request.paragraphTranslationCount())
                || overflows(stat.getCardsCreated(), request.cardsCreated())
                || overflows(stat.getCardsReviewed(), request.cardsReviewed())) {
            throw new InvalidDailyStatsException();
        }
    }

    private boolean overflows(int currentValue, int increment) {
        return (long) currentValue + increment > Integer.MAX_VALUE;
    }

    private <T> T required(ObjectProvider<T> provider) {
        return provider.getIfAvailable(() -> {
            throw new IllegalStateException("Study stats persistence is not available");
        });
    }

    private DailyStatsResponse toResponse(StudyDailyStat stat) {
        return new DailyStatsResponse(
                stat.getStatDate(),
                stat.getReadingMinutes(),
                stat.getLookupCount(),
                stat.getParagraphTranslationCount(),
                stat.getCardsCreated(),
                stat.getCardsReviewed());
    }

    public static class CurrentUserNotFoundException extends RuntimeException {
    }

    public static class InvalidDailyStatsException extends RuntimeException {
    }
}
