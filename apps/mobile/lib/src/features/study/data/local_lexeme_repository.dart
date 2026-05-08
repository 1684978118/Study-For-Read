import 'package:sqflite/sqflite.dart';

import '../domain/local_lexeme.dart';

class LocalLexemeRepository {
  LocalLexemeRepository(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(LocalLexeme lexeme) async {
    await _db.insert(
      'local_lexeme_cache',
      lexeme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalLexeme?> findById(String id) async {
    final rows = await _db.query(
      'local_lexeme_cache',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalLexeme.fromMap(rows.single);
  }
}
