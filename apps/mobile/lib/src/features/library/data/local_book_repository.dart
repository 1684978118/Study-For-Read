import 'package:sqflite/sqflite.dart';

import '../domain/local_book.dart';

class LocalBookRepository {
  LocalBookRepository(this._db);

  final Database _db;

  Future<int> insert(LocalBook book) {
    return _db.insert('local_books', book.toMap());
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
