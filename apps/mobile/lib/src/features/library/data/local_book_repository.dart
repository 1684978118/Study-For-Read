import 'package:sqflite/sqflite.dart';

import '../domain/local_book.dart';

class LocalBookRepository {
  LocalBookRepository(this._db);

  final DatabaseExecutor _db;

  Future<int> insert(LocalBook book) {
    return _db.insert('local_books', book.toMap());
  }

  Future<int> update(LocalBook book) {
    return _db.update(
      'local_books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<LocalBook?> findByOwnerUserIdAndBookFingerprint({
    required String ownerUserId,
    required String bookFingerprint,
  }) async {
    final rows = await _db.query(
      'local_books',
      where: 'owner_user_id = ? AND book_fingerprint = ?',
      whereArgs: [ownerUserId, bookFingerprint],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalBook.fromMap(rows.single);
  }

  Future<List<LocalBook>> findByOwnerUserId(String ownerUserId) async {
    final rows = await _db.query(
      'local_books',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(LocalBook.fromMap).toList(growable: false);
  }
}
