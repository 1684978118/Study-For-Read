import 'package:sqflite/sqflite.dart';

import '../domain/local_chapter.dart';

class LocalChapterRepository {
  LocalChapterRepository(this._db);

  final DatabaseExecutor _db;

  Future<int> insert(LocalChapter chapter) {
    return _db.insert('local_chapters', chapter.toMap());
  }

  Future<int> deleteByBookId(String bookId) {
    return _db.delete(
      'local_chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  Future<LocalChapter?> findByBookIdAndChapterIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    final rows = await _db.query(
      'local_chapters',
      where: 'book_id = ? AND chapter_index = ?',
      whereArgs: [bookId, chapterIndex],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalChapter.fromMap(rows.single);
  }

  Future<List<LocalChapter>> findByBookIdOrderByChapterIndex(
    String bookId,
  ) async {
    final rows = await _db.query(
      'local_chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'chapter_index ASC',
    );
    return rows.map(LocalChapter.fromMap).toList(growable: false);
  }
}
