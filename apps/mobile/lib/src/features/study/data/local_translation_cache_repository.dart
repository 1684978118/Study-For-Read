import 'package:sqflite/sqflite.dart';

import '../domain/local_translation_cache_entry.dart';

class LocalTranslationCacheRepository {
  LocalTranslationCacheRepository(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(LocalTranslationCacheEntry entry) async {
    await _db.insert(
      'local_translation_cache',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalTranslationCacheEntry?>
  findByOwnerAndLanguagePairAndSourceTextHash({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required String sourceTextHash,
  }) async {
    final rows = await _db.query(
      'local_translation_cache',
      where:
          'owner_user_id = ? AND source_lang = ? AND target_lang = ? '
          'AND source_text_hash = ?',
      whereArgs: [ownerUserId, sourceLang, targetLang, sourceTextHash],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalTranslationCacheEntry.fromMap(rows.single);
  }
}
