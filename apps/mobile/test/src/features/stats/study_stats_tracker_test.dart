import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/data/study_stats_tracker.dart';

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

  test('records positive reading minutes for the current local date', () async {
    final tracker = StudyStatsTracker(
      ownerUserId: 'user-1',
      repository: repository,
      now: () => DateTime(2026, 5, 8, 22, 30),
    );

    await tracker.recordReadingSession(const Duration(minutes: 12));

    final summary = await repository.summaryForToday(
      ownerUserId: 'user-1',
      today: DateTime(2026, 5, 8),
    );
    expect(summary.readingMinutes, 12);
    expect(summary.lookupCount, 0);
  });

  test('ignores zero or negative reading sessions', () async {
    final tracker = StudyStatsTracker(
      ownerUserId: 'user-1',
      repository: repository,
      now: () => DateTime(2026, 5, 8, 22, 30),
    );

    await tracker.recordReadingSession(Duration.zero);
    await tracker.recordReadingSession(const Duration(minutes: -3));

    final summary = await repository.summaryForToday(
      ownerUserId: 'user-1',
      today: DateTime(2026, 5, 8),
    );
    expect(summary.readingMinutes, 0);
  });
}
