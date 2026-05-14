import 'package:sqflite/sqflite.dart';

class MobileDatabaseMigrations {
  static const int version = 3;

  static Future<void> create(Database db, int version) async {
    if (version >= 1) {
      await _createV1(db);
    }
    if (version >= 2) {
      await _createV2(db);
    }
    if (version >= 3) {
      await _createV3(db);
    }
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createV2(db);
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await _createV3(db);
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

  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE local_lexeme_cache (
        id TEXT PRIMARY KEY,
        surface TEXT NOT NULL,
        reading TEXT,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        entry_type TEXT NOT NULL CHECK (entry_type IN ('word', 'phrase', 'idiom')),
        part_of_speech TEXT,
        definition TEXT NOT NULL,
        short_definition TEXT,
        cached_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_word_cards (
        id TEXT PRIMARY KEY,
        server_card_id TEXT,
        owner_user_id TEXT NOT NULL,
        card_type TEXT NOT NULL CHECK (card_type IN ('lexeme', 'private_sentence')),
        lexeme_id TEXT,
        private_surface TEXT,
        private_definition TEXT,
        private_context TEXT,
        source_book_fingerprint TEXT,
        source_book_title TEXT,
        review_status TEXT NOT NULL CHECK (review_status IN ('new', 'learning', 'known')),
        review_count INTEGER NOT NULL DEFAULT 0 CHECK (review_count >= 0),
        next_review_at TEXT,
        last_reviewed_at TEXT,
        sync_status TEXT NOT NULL CHECK (
          sync_status IN ('local_only', 'synced', 'dirty', 'failed')
        ),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        CHECK (
          (card_type = 'lexeme' AND lexeme_id IS NOT NULL) OR
          (
            card_type = 'private_sentence' AND
            private_surface IS NOT NULL AND
            private_definition IS NOT NULL
          )
        ),
        FOREIGN KEY (lexeme_id) REFERENCES local_lexeme_cache (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX local_word_cards_owner_server_card_idx
      ON local_word_cards (owner_user_id, server_card_id)
      WHERE server_card_id IS NOT NULL
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX local_word_cards_owner_lexeme_idx
      ON local_word_cards (owner_user_id, lexeme_id)
      WHERE lexeme_id IS NOT NULL
    ''');

    await db.execute('''
      CREATE TABLE local_translation_cache (
        id TEXT PRIMARY KEY,
        owner_user_id TEXT NOT NULL,
        book_fingerprint TEXT,
        chapter_index INTEGER CHECK (chapter_index IS NULL OR chapter_index >= 0),
        paragraph_index INTEGER CHECK (paragraph_index IS NULL OR paragraph_index >= 0),
        source_text_hash TEXT NOT NULL CHECK (
          length(source_text_hash) = 64 AND
          source_text_hash NOT GLOB '*[^0-9a-f]*'
        ),
        source_text_preview TEXT CHECK (
          source_text_preview IS NULL OR length(source_text_preview) <= 120
        ),
        translated_text TEXT NOT NULL,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        provider TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (owner_user_id, source_lang, target_lang, source_text_hash)
      )
    ''');

    await db.execute('''
      CREATE TABLE local_study_daily_stats (
        id TEXT PRIMARY KEY,
        owner_user_id TEXT NOT NULL,
        stat_date TEXT NOT NULL,
        reading_minutes INTEGER NOT NULL DEFAULT 0 CHECK (reading_minutes >= 0),
        lookup_count INTEGER NOT NULL DEFAULT 0 CHECK (lookup_count >= 0),
        paragraph_translation_count INTEGER NOT NULL DEFAULT 0 CHECK (
          paragraph_translation_count >= 0
        ),
        cards_created INTEGER NOT NULL DEFAULT 0 CHECK (cards_created >= 0),
        cards_reviewed INTEGER NOT NULL DEFAULT 0 CHECK (cards_reviewed >= 0),
        sync_status TEXT NOT NULL CHECK (
          sync_status IN ('local_only', 'synced', 'dirty', 'failed')
        ),
        last_synced_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (owner_user_id, stat_date)
      )
    ''');
  }

  static Future<void> _createV3(Database db) async {
    await db.execute('''
      CREATE TABLE local_reader_preferences (
        id TEXT PRIMARY KEY CHECK (id = 'global'),
        font_size REAL NOT NULL CHECK (font_size >= 12 AND font_size <= 40),
        line_height REAL NOT NULL CHECK (line_height >= 1.0 AND line_height <= 3.0),
        paragraph_spacing REAL NOT NULL CHECK (
          paragraph_spacing >= 0 AND paragraph_spacing <= 80
        ),
        background_theme TEXT NOT NULL CHECK (
          background_theme IN (
            'paper_white',
            'warm_beige',
            'eye_care_green',
            'light_blue',
            'dark_gray',
            'pure_black'
          )
        ),
        night_mode_enabled INTEGER NOT NULL CHECK (
          night_mode_enabled IN (0, 1)
        ),
        previous_background_theme TEXT NOT NULL CHECK (
          previous_background_theme IN (
            'paper_white',
            'warm_beige',
            'eye_care_green',
            'light_blue',
            'dark_gray',
            'pure_black'
          )
        ),
        brightness REAL NOT NULL CHECK (brightness >= 0 AND brightness <= 1),
        eye_protection_enabled INTEGER NOT NULL CHECK (
          eye_protection_enabled IN (0, 1)
        ),
        page_turn_mode TEXT NOT NULL CHECK (
          page_turn_mode IN (
            'simulation',
            'cover',
            'slide',
            'vertical',
            'none'
          )
        ),
        volume_key_paging_enabled INTEGER NOT NULL CHECK (
          volume_key_paging_enabled IN (0, 1)
        ),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
