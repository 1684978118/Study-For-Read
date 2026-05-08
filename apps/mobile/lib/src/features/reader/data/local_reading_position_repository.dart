import 'package:sqflite/sqflite.dart';

import '../../library/domain/local_reading_position.dart';

class LocalReadingPositionRepository {
  LocalReadingPositionRepository(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(LocalReadingPosition position) async {
    _validate(position);
    final bookRows = await _db.query(
      'local_books',
      columns: ['chapter_count'],
      where: 'id = ?',
      whereArgs: [position.bookId],
      limit: 1,
    );
    if (bookRows.isEmpty) {
      throw ArgumentError('Unknown book');
    }
    final chapterCount = bookRows.single['chapter_count'] as int;
    if (position.currentChapterIndex >= chapterCount) {
      throw ArgumentError('currentChapterIndex must be less than chapterCount');
    }

    final values = position.toMap();
    final existing = await _db.query(
      'local_reading_positions',
      columns: ['id'],
      where: 'book_id = ?',
      whereArgs: [position.bookId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _db.insert('local_reading_positions', values);
    } else {
      await _db.update(
        'local_reading_positions',
        values,
        where: 'book_id = ?',
        whereArgs: [position.bookId],
      );
    }
  }

  Future<LocalReadingPosition?> findByBookId(String bookId) async {
    final rows = await _db.query(
      'local_reading_positions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalReadingPosition.fromMap(rows.single);
  }

  void _validate(LocalReadingPosition position) {
    if (position.currentChapterIndex < 0) {
      throw ArgumentError('currentChapterIndex must be zero or positive');
    }
    if (position.currentParagraphIndex < 0) {
      throw ArgumentError('currentParagraphIndex must be zero or positive');
    }
    if (position.currentCharOffset < 0) {
      throw ArgumentError('currentCharOffset must be zero or positive');
    }
  }
}
