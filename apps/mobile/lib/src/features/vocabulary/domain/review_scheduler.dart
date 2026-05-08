import 'review_result.dart';

class ReviewScheduler {
  const ReviewScheduler();

  ReviewResult schedule({
    required bool known,
    required int currentReviewCount,
    required DateTime reviewedAt,
  }) {
    if (currentReviewCount < 0) {
      throw ArgumentError('currentReviewCount must be zero or positive');
    }

    final nextCount = currentReviewCount + 1;
    final intervalDays = known ? _knownIntervalDays(nextCount) : 1;
    return ReviewResult(
      reviewStatus: known && nextCount >= 4 ? 'known' : 'learning',
      reviewCount: nextCount,
      nextReviewAt: reviewedAt.toUtc().add(Duration(days: intervalDays)),
      lastReviewedAt: reviewedAt.toUtc(),
    );
  }

  int _knownIntervalDays(int nextReviewCount) {
    return switch (nextReviewCount) {
      1 => 3,
      2 => 7,
      3 => 15,
      _ => 30,
    };
  }
}
