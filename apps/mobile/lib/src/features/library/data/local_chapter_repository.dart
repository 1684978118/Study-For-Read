import 'package:sqflite/sqflite.dart';

import '../domain/local_chapter.dart';

class LocalChapterRepository {
  LocalChapterRepository(this._db);

  final Database _db;

  Future<int> insert(LocalChapter chapter) {
    return _db.insert('local_chapters', chapter.toMap());
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
}
