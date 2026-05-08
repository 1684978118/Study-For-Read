import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';

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

  test('increments non-negative counters per owner and date', () async {
    final statDate = DateTime.utc(2026, 5, 8);

    final first = await repository.increment(
      ownerUserId: 'user-1',
      statDate: statDate,
      readingMinutes: 10,
      lookupCount: 2,
      paragraphTranslationCount: 1,
      cardsCreated: 1,
      cardsReviewed: 0,
    );
    final second = await repository.increment(
      ownerUserId: 'user-1',
      statDate: statDate,
      readingMinutes: 5,
      lookupCount: 3,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: 4,
    );
    await repository.increment(
      ownerUserId: 'user-2',
      statDate: statDate,
      readingMinutes: 99,
      lookupCount: 99,
      paragraphTranslationCount: 99,
      cardsCreated: 99,
      cardsReviewed: 99,
    );

    final stored = await repository.findByOwnerUserIdAndStatDate(
      ownerUserId: 'user-1',
      statDate: statDate,
    );
    final userOneRows = await repository.findByOwnerUserId('user-1');

    expect(first.readingMinutes, 10);
    expect(second.readingMinutes, 15);
    expect(second.lookupCount, 5);
    expect(second.paragraphTranslationCount, 1);
    expect(second.cardsCreated, 1);
    expect(second.cardsReviewed, 4);
    expect(stored!.readingMinutes, 15);
    expect(userOneRows, hasLength(1));
    expect(userOneRows.single.ownerUserId, 'user-1');
  });

  test('rejects negative counter increments', () {
    expect(
      () => repository.increment(
        ownerUserId: 'user-1',
        statDate: DateTime.utc(2026, 5, 8),
        readingMinutes: -1,
        lookupCount: 0,
        paragraphTranslationCount: 0,
        cardsCreated: 0,
        cardsReviewed: 0,
      ),
      throwsArgumentError,
    );
  });
}
