import 'package:sqflite/sqflite.dart';

class MobileDatabaseMigrations {
  static const int version = 1;

  static Future<void> create(Database db, int version) async {
    if (version >= 1) {
      await _createV1(db);
    }
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE local_books (
        id TEXT PRIMARY KEY,
        owner_user_id TEXT NOT NULL,
        book_fingerprint TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT,
        file_type TEXT NOT NULL CHECK (file_type IN ('txt', 'epub')),
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        original_file_path TEXT NOT NULL,
        chapter_count INTEGER NOT NULL CHECK (chapter_count >= 1),
        metadata_sync_status TEXT NOT NULL CHECK (
          metadata_sync_status IN ('local_only', 'synced', 'dirty', 'failed')
        ),
        last_opened_at TEXT,
        last_synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (owner_user_id, book_fingerprint)
      )
    ''');

    await db.execute('''
      CREATE TABLE local_chapters (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_index INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        paragraph_count INTEGER NOT NULL CHECK (paragraph_count >= 1),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (book_id, chapter_index),
        FOREIGN KEY (book_id) REFERENCES local_books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE local_reading_positions (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL UNIQUE,
        current_chapter_index INTEGER NOT NULL CHECK (current_chapter_index >= 0),
        current_paragraph_index INTEGER NOT NULL CHECK (current_paragraph_index >= 0),
        current_char_offset INTEGER NOT NULL CHECK (current_char_offset >= 0),
        progress_sync_status TEXT NOT NULL CHECK (
          progress_sync_status IN ('local_only', 'synced', 'dirty', 'failed')
        ),
        last_read_at TEXT,
        last_synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES local_books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sync_events (
        id TEXT PRIMARY KEY,
        owner_user_id TEXT NOT NULL,
        event_type TEXT NOT NULL CHECK (
          event_type IN (
            'book_metadata',
            'reading_progress',
            'word_card_create',
            'word_card_review',
            'daily_stats'
          )
        ),
        aggregate_key TEXT,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'failed', 'done')),
        attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
        last_error_code TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
