import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database_migrations.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late Database db;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('opens with SQLite foreign keys enabled', () async {
    final rows = await db.rawQuery('PRAGMA foreign_keys');

    expect(rows.single.values.single, 1);
  });

  test('local_chapters cascade-delete when the book is deleted', () async {
    await db.insert('local_books', _bookRow(id: 'book-1'));
    await db.insert('local_chapters', _chapterRow(id: 'chapter-1'));

    await db.delete('local_books', where: 'id = ?', whereArgs: ['book-1']);

    final chapters = await db.query('local_chapters');
    expect(chapters, isEmpty);
  });

  test('local_reading_positions allows only one row per book', () async {
    await db.insert('local_books', _bookRow(id: 'book-1'));
    await db.insert('local_reading_positions', _positionRow(id: 'position-1'));

    expect(
      () =>
          db.insert('local_reading_positions', _positionRow(id: 'position-2')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('access and refresh tokens have no SQLite columns', () async {
    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );

    for (final table in tableRows.map((row) => row['name'] as String)) {
      if (table.startsWith('sqlite_')) {
        continue;
      }
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final columnNames = columns.map((row) => row['name'] as String).toSet();
      expect(columnNames, isNot(contains('access_token')), reason: table);
      expect(columnNames, isNot(contains('refresh_token')), reason: table);
    }
  });

  test('local_reader_preferences stores global reader settings only', () async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(local_reader_preferences)',
    );
    final columnNames = columns.map((row) => row['name'] as String).toSet();

    expect(
      columnNames,
      containsAll({
        'id',
        'font_size',
        'line_height',
        'paragraph_spacing',
        'background_theme',
        'night_mode_enabled',
        'previous_background_theme',
        'brightness',
        'eye_protection_enabled',
        'page_turn_mode',
        'volume_key_paging_enabled',
        'lookup_translation_engine',
        'paragraph_translation_engine',
        'local_translation_models_ready',
        'ai_prefetch_page_count',
        'furigana_enabled',
        'created_at',
        'updated_at',
      }),
    );
    for (final forbidden in [
      'content',
      'chapter_content',
      'selected_text',
      'paragraph_text',
      'translated_text',
      'original_file_path',
      'access_token',
      'refresh_token',
      'password',
      'secret',
    ]) {
      expect(columnNames, isNot(contains(forbidden)));
    }
  });

  test('v6 migration tightens old reader typography only', () async {
    await mobileDatabase.close();
    final path =
        '${Directory.systemTemp.path}/sfr_reader_v6_${DateTime.now().microsecondsSinceEpoch}.db';
    final oldDb = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, version) => MobileDatabaseMigrations.create(db, version),
      ),
    );
    await oldDb.insert('local_reader_preferences', {
      'id': 'global',
      'font_size': 24.0,
      'line_height': 2.0,
      'paragraph_spacing': 30.0,
      'background_theme': 'eye_care_green',
      'night_mode_enabled': 1,
      'previous_background_theme': 'warm_beige',
      'brightness': 0.62,
      'eye_protection_enabled': 1,
      'page_turn_mode': 'cover',
      'volume_key_paging_enabled': 1,
      'lookup_translation_engine': 'ai',
      'paragraph_translation_engine': 'local_machine',
      'local_translation_models_ready': 1,
      'ai_prefetch_page_count': 3,
      'furigana_enabled': 1,
      'created_at': '2026-05-07T00:00:00.000Z',
      'updated_at': '2026-05-07T00:00:00.000Z',
    });
    await oldDb.close();

    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: path,
    );
    db = await mobileDatabase.open();
    final row = (await db.query(
      'local_reader_preferences',
      where: 'id = ?',
      whereArgs: ['global'],
    )).single;

    expect(row['font_size'], 18.0);
    expect(row['line_height'], 1.55);
    expect(row['paragraph_spacing'], 10.0);
    expect(row['background_theme'], 'eye_care_green');
    expect(row['night_mode_enabled'], 1);
    expect(row['page_turn_mode'], 'cover');
    expect(row['volume_key_paging_enabled'], 1);
    expect(row['lookup_translation_engine'], 'ai');
    expect(row['paragraph_translation_engine'], 'local_machine');
    expect(row['local_translation_models_ready'], 1);
    expect(row['furigana_enabled'], 1);
  });
}

Map<String, Object?> _bookRow({required String id}) {
  return {
    'id': id,
    'owner_user_id': 'user-1',
    'book_fingerprint':
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    'title': 'Kokoro',
    'author': 'Natsume Soseki',
    'file_type': 'txt',
    'source_lang': 'ja',
    'target_lang': 'zh-CN',
    'original_file_path': '/app/books/kokoro.txt',
    'chapter_count': 1,
    'metadata_sync_status': 'local_only',
    'last_opened_at': null,
    'last_synced_at': null,
    'created_at': '2026-05-07T00:00:00.000Z',
    'updated_at': '2026-05-07T00:00:00.000Z',
  };
}

Map<String, Object?> _chapterRow({required String id}) {
  return {
    'id': id,
    'book_id': 'book-1',
    'chapter_index': 0,
    'title': 'Chapter 1',
    'content': 'local chapter content',
    'paragraph_count': 1,
    'created_at': '2026-05-07T00:00:00.000Z',
    'updated_at': '2026-05-07T00:00:00.000Z',
  };
}

Map<String, Object?> _positionRow({required String id}) {
  return {
    'id': id,
    'book_id': 'book-1',
    'current_chapter_index': 0,
    'current_paragraph_index': 0,
    'current_char_offset': 0,
    'progress_sync_status': 'local_only',
    'last_read_at': null,
    'last_synced_at': null,
    'created_at': '2026-05-07T00:00:00.000Z',
    'updated_at': '2026-05-07T00:00:00.000Z',
  };
}
