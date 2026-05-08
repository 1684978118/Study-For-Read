import '../domain/study_stats_summary.dart';
import 'local_study_stats_repository.dart';

class StudyStatsTracker {
  StudyStatsTracker({
    required String ownerUserId,
    required LocalStudyStatsRepository repository,
    DateTime Function()? now,
  }) : _ownerUserId = ownerUserId,
       _repository = repository,
       _now = now ?? DateTime.now;

  final String _ownerUserId;
  final LocalStudyStatsRepository _repository;
  final DateTime Function() _now;

  Future<void> recordReadingSession(Duration elapsed) async {
    final minutes = elapsed.inMinutes;
    if (minutes <= 0) {
      return;
    }
    await _increment(readingMinutes: minutes);
  }

  Future<void> recordLookup() {
    return _increment(lookupCount: 1);
  }

  Future<void> recordParagraphTranslation() {
    return _increment(paragraphTranslationCount: 1);
  }

  Future<void> recordCardCreated() {
    return _increment(cardsCreated: 1);
  }

  Future<void> recordCardReviewed() {
    return _increment(cardsReviewed: 1);
  }

  Future<void> _increment({
    int readingMinutes = 0,
    int lookupCount = 0,
    int paragraphTranslationCount = 0,
    int cardsCreated = 0,
    int cardsReviewed = 0,
  }) async {
    await _repository.increment(
      ownerUserId: _ownerUserId,
      statDate: _now(),
      readingMinutes: readingMinutes,
      lookupCount: lookupCount,
      paragraphTranslationCount: paragraphTranslationCount,
      cardsCreated: cardsCreated,
      cardsReviewed: cardsReviewed,
    );
  }

  Future<StudyStatsSummary> today() {
    return _repository.summaryForToday(
      ownerUserId: _ownerUserId,
      today: _now(),
    );
  }
}
