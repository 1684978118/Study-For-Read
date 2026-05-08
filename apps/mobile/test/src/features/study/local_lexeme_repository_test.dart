import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late Database db;
  late LocalLexemeRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    repository = LocalLexemeRepository(db);
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('upserts public lexeme snapshots by backend id', () async {
    await repository.upsert(_lexeme(definition: 'heart'));
    await repository.upsert(
      _lexeme(definition: 'heart; mind', shortDefinition: 'heart'),
    );

    final cached = await repository.findById('lexeme-1');

    expect(cached, isNotNull);
    expect(cached!.definition, 'heart; mind');
    expect(cached.shortDefinition, 'heart');
    expect(cached.surface, '心');
  });

  test('local_lexeme_cache stores no review state columns', () async {
    final columns = await db.rawQuery('PRAGMA table_info(local_lexeme_cache)');
    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(columnNames, isNot(contains('review_status')));
    expect(columnNames, isNot(contains('review_count')));
    expect(columnNames, isNot(contains('next_review_at')));
    expect(columnNames, isNot(contains('last_reviewed_at')));
  });
}

LocalLexeme _lexeme({required String definition, String? shortDefinition}) {
  final now = DateTime.utc(2026, 5, 8, 1);
  return LocalLexeme(
    id: 'lexeme-1',
    surface: '心',
    reading: 'こころ',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: definition,
    shortDefinition: shortDefinition,
    cachedAt: now,
    updatedAt: now,
  );
}
