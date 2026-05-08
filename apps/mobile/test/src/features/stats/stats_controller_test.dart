import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_controller.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late Database db;
  late LocalStudyStatsRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    repository = LocalStudyStatsRepository(db);
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('loads today, last 7 days, and all-time local summaries', () async {
    final today = DateTime(2026, 5, 8);
    await repository.increment(
      ownerUserId: 'user-1',
      statDate: today,
      readingMinutes: 10,
      lookupCount: 2,
      paragraphTranslationCount: 1,
      cardsCreated: 1,
      cardsReviewed: 3,
    );
    await repository.increment(
      ownerUserId: 'user-1',
      statDate: today.subtract(const Duration(days: 6)),
      readingMinutes: 20,
      lookupCount: 4,
      paragraphTranslationCount: 2,
      cardsCreated: 2,
      cardsReviewed: 6,
    );
    await repository.increment(
      ownerUserId: 'user-1',
      statDate: today.subtract(const Duration(days: 8)),
      readingMinutes: 40,
      lookupCount: 8,
      paragraphTranslationCount: 4,
      cardsCreated: 4,
      cardsReviewed: 12,
    );
    await repository.increment(
      ownerUserId: 'user-2',
      statDate: today,
      readingMinutes: 99,
      lookupCount: 99,
      paragraphTranslationCount: 99,
      cardsCreated: 99,
      cardsReviewed: 99,
    );
    final controller = StatsController(
      ownerUserId: 'user-1',
      repository: repository,
      now: () => today,
    );

    await controller.load();

    expect(controller.today.readingMinutes, 10);
    expect(controller.today.lookupCount, 2);
    expect(controller.last7Days.readingMinutes, 30);
    expect(controller.last7Days.cardsReviewed, 9);
    expect(controller.allTime.readingMinutes, 70);
    expect(controller.allTime.paragraphTranslationCount, 7);
    expect(controller.errorMessage, isNull);
  });
}
