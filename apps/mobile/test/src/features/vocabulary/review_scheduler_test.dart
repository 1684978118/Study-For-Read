import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/review_scheduler.dart';

void main() {
  test('unknown review schedules tomorrow and increments count', () {
    final reviewedAt = DateTime.utc(2026, 5, 8, 12);
    const scheduler = ReviewScheduler();

    final result = scheduler.schedule(
      known: false,
      currentReviewCount: 3,
      reviewedAt: reviewedAt,
    );

    expect(result.reviewStatus, 'learning');
    expect(result.reviewCount, 4);
    expect(result.lastReviewedAt, reviewedAt);
    expect(result.reviewedAt, reviewedAt);
    expect(result.nextReviewAt, reviewedAt.add(const Duration(days: 1)));
  });

  test('known first review schedules in 3 days', () {
    final reviewedAt = DateTime.utc(2026, 5, 8, 12);
    const scheduler = ReviewScheduler();

    final result = scheduler.schedule(
      known: true,
      currentReviewCount: 0,
      reviewedAt: reviewedAt,
    );

    expect(result.reviewStatus, 'learning');
    expect(result.reviewCount, 1);
    expect(result.nextReviewAt, reviewedAt.add(const Duration(days: 3)));
  });

  test('known repeated reviews schedule 7, 15, then 30 days', () {
    final reviewedAt = DateTime.utc(2026, 5, 8, 12);
    const scheduler = ReviewScheduler();

    expect(
      scheduler
          .schedule(known: true, currentReviewCount: 1, reviewedAt: reviewedAt)
          .nextReviewAt,
      reviewedAt.add(const Duration(days: 7)),
    );
    expect(
      scheduler
          .schedule(known: true, currentReviewCount: 2, reviewedAt: reviewedAt)
          .nextReviewAt,
      reviewedAt.add(const Duration(days: 15)),
    );
    final mature = scheduler.schedule(
      known: true,
      currentReviewCount: 3,
      reviewedAt: reviewedAt,
    );
    expect(mature.reviewStatus, 'known');
    expect(mature.nextReviewAt, reviewedAt.add(const Duration(days: 30)));
  });
}
