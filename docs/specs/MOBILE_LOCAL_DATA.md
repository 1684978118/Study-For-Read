# Mobile Local Data

This document defines the first-release Flutter local data boundary.

## 1. Storage Decisions

Mobile storage choices are locked for first release:

- Relational local database: SQLite through `sqflite`.
- SQLite tests: `sqflite_common_ffi`.
- Token storage: Flutter secure storage.
- Imported file storage: app documents directory.
- Parsed chapter storage: SQLite `local_chapters.content`.

Do not introduce Hive, Isar, ObjectBox, Drift, Realm, or another local persistence layer in first release unless a later task card explicitly changes this document.

## 2. Privacy Boundary

The mobile app may store original book files and parsed chapters locally because the user imported them on that device.

The mobile app must not:

- Upload original files to the backend.
- Put chapter content into reading sync payloads.
- Put chapter content into `pending_sync_events.payload_json`.
- Print chapter content, paragraph content, access tokens, or refresh tokens in logs.
- Store access tokens or refresh tokens in SQLite.

The backend sync boundary remains:

- Book metadata.
- Reading position.
- Vocabulary state.
- Study statistics.

## 3. Local Database Standards

- Table names use snake_case.
- Primary keys use `text` UUID strings unless the table naturally uses a unique business key.
- SHA-256 fingerprints use lowercase 64-character hex strings.
- Timestamps use UTC ISO-8601 strings.
- Enum-like values use lowercase strings checked in Dart before insert.
- Counters and positions are zero or positive.
- Foreign key constraints must be enabled after opening SQLite.
- Migrations must be deterministic and covered by tests.

## 4. local_books

Stores imported book metadata and local file location for one signed-in user on this device.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID |
| owner_user_id | text | yes | Backend user id string |
| book_fingerprint | text | yes | SHA-256 hex |
| title | text | yes | Parsed or file-derived title |
| author | text | no | Parsed when available |
| file_type | text | yes | `txt`, `epub` |
| source_lang | text | yes | Default `ja` |
| target_lang | text | yes | Default `zh-CN` |
| original_file_path | text | yes | App-private local copy |
| chapter_count | integer | yes | At least 1 |
| metadata_sync_status | text | yes | `local_only`, `synced`, `dirty`, `failed` |
| last_opened_at | text | no | UTC ISO-8601 |
| last_synced_at | text | no | UTC ISO-8601 |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Unique key:

- `owner_user_id, book_fingerprint`

Rules:

- `original_file_path` is local only and must never be sent to the backend.
- `chapter_count >= 1`.
- `metadata_sync_status` uses one of the listed values.

## 5. local_chapters

Stores parsed chapter text for local reading.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID |
| book_id | text | yes | References `local_books.id` |
| chapter_index | integer | yes | Zero-based |
| title | text | yes | Display title |
| content | text | yes | Local chapter content |
| paragraph_count | integer | yes | At least 1 |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Unique key:

- `book_id, chapter_index`

Rules:

- `content` stays local.
- `paragraph_count >= 1`.
- Deleting a local book deletes its local chapters.

## 6. local_reading_positions

Stores local reading progress and sync status.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID |
| book_id | text | yes | References `local_books.id` |
| current_chapter_index | integer | yes | Zero-based |
| current_paragraph_index | integer | yes | Zero-based |
| current_char_offset | integer | yes | Zero-based |
| progress_sync_status | text | yes | `local_only`, `synced`, `dirty`, `failed` |
| last_read_at | text | no | UTC ISO-8601 |
| last_synced_at | text | no | UTC ISO-8601 |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Unique key:

- `book_id`

Rules:

- Position fields are zero or positive.
- `current_chapter_index` must be less than the book's `chapter_count` in repository validation.
- `progress_sync_status` uses one of the listed values.

## 7. pending_sync_events

Stores outbound sync events while offline or after a failed request.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID |
| owner_user_id | text | yes | Backend user id string |
| event_type | text | yes | `book_metadata`, `reading_progress`, `word_card_create`, `word_card_review`, `daily_stats` |
| aggregate_key | text | no | Example book fingerprint |
| payload_json | text | yes | Metadata or counters only |
| status | text | yes | `pending`, `in_progress`, `failed`, `done` |
| attempt_count | integer | yes | Starts at 0 |
| last_error_code | text | no | Stable local or server error code |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Rules:

- `payload_json` must not contain `content`, `chapterContent`, `chapter_content`, `originalFile`, `original_file`, `filePath`, `file_path`, `rawText`, `raw_text`, `translatedText`, `translated_text`, or paragraph text.
- `attempt_count >= 0`.
- `event_type` and `status` use one of the listed values.

## 8. Import Parser Output

All book parsers return the same normalized structure:

- `title`
- `author`
- `fileType`
- `sourceLang`
- `targetLang`
- `chapters`

Each chapter contains:

- `chapterIndex`
- `title`
- `content`
- `paragraphs`

Parser rules:

- TXT first supports UTF-8 and UTF-8 with BOM.
- Unsupported encodings return a typed import failure instead of garbled text.
- TXT chapter detection recognizes common Japanese and Chinese chapter headings, and falls back to one chapter when no heading exists.
- EPUB parser reads container metadata, package metadata, spine order, and XHTML text.
- EPUB parser ignores images, CSS, scripts, and remote resources in first release.

## 9. local_lexeme_cache

Stores public lexeme snapshots returned by lookup or vocabulary APIs for local display.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Backend lexeme id |
| surface | text | yes | Display text |
| reading | text | no | Furigana or pronunciation |
| source_lang | text | yes | Example `ja` |
| target_lang | text | yes | Example `zh-CN` |
| entry_type | text | yes | `word`, `phrase`, `idiom` |
| part_of_speech | text | no | Optional |
| definition | text | yes | Definition from backend |
| short_definition | text | no | Compact display |
| cached_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Rules:

- Public lexeme cache may be reused locally.
- Public lexeme cache must not contain user review state.
- `entry_type` uses one of the listed values.

## 10. local_word_cards

Stores local copies of user vocabulary cards and offline review state.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID until server id exists |
| server_card_id | text | no | Backend card id after sync |
| owner_user_id | text | yes | Backend user id string |
| card_type | text | yes | `lexeme`, `private_sentence` |
| lexeme_id | text | no | References `local_lexeme_cache.id` when public lexeme card |
| private_surface | text | no | Private sentence surface |
| private_definition | text | no | Private sentence meaning |
| private_context | text | no | Private user context |
| source_book_fingerprint | text | no | SHA-256 hex |
| source_book_title | text | no | Metadata only |
| review_status | text | yes | `new`, `learning`, `known` |
| review_count | integer | yes | Starts at 0 |
| next_review_at | text | no | UTC ISO-8601 |
| last_reviewed_at | text | no | UTC ISO-8601 |
| sync_status | text | yes | `local_only`, `synced`, `dirty`, `failed` |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Unique keys:

- `owner_user_id, server_card_id` when `server_card_id` is not null.
- `owner_user_id, lexeme_id` when `lexeme_id` is not null.

Rules:

- `lexeme_id` is required when `card_type=lexeme`.
- `private_surface` and `private_definition` are required when `card_type=private_sentence`.
- Private sentence data is user-private and must not be inserted into `local_lexeme_cache`.
- `review_count >= 0`.
- `sync_status` uses one of the listed values.

## 11. local_translation_cache

Stores user-local paragraph translation results for convenience.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID |
| owner_user_id | text | yes | Backend user id string |
| book_fingerprint | text | no | SHA-256 hex when available |
| chapter_index | integer | no | Zero-based when available |
| paragraph_index | integer | no | Zero-based when available |
| source_text_hash | text | yes | SHA-256 hex of selected paragraph |
| source_text_preview | text | no | Short local-only preview, max 120 chars |
| translated_text | text | yes | Local-only translation result |
| source_lang | text | yes | Example `ja` |
| target_lang | text | yes | Example `zh-CN` |
| provider | text | no | Provider name |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Unique key:

- `owner_user_id, source_lang, target_lang, source_text_hash`

Rules:

- Translation cache is local-only.
- Translation cache must never be uploaded as corpus.
- Pending sync events must not include `source_text_preview` or `translated_text`.

## 12. local_study_daily_stats

Stores mobile-collected daily counters before and after sync.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | text | yes | Local UUID |
| owner_user_id | text | yes | Backend user id string |
| stat_date | text | yes | Local date `YYYY-MM-DD` |
| reading_minutes | integer | yes | Default 0 |
| lookup_count | integer | yes | Default 0 |
| paragraph_translation_count | integer | yes | Default 0 |
| cards_created | integer | yes | Default 0 |
| cards_reviewed | integer | yes | Default 0 |
| sync_status | text | yes | `local_only`, `synced`, `dirty`, `failed` |
| last_synced_at | text | no | UTC ISO-8601 |
| created_at | text | yes | UTC ISO-8601 |
| updated_at | text | yes | UTC ISO-8601 |

Unique key:

- `owner_user_id, stat_date`

Rules:

- Counter fields are zero or positive.
- Sync sends incremental counters through `/api/v1/stats/daily`.
- Stats sync payload must include counters only, not book content or paragraph text.

## 13. Learning API Local Rules

- Lookup and paragraph translation require network.
- Lookup failures must not block reading.
- Paragraph translation sends only one selected paragraph.
- Full chapter and full book translation are not part of first release.
- Annotation tokens are local UI helpers and do not need to be persisted in first release.
- Offline vocabulary review must update `local_word_cards` immediately and enqueue `word_card_review`.

## 14. Mobile Foundation Non-Goals

These are not part of the mobile foundation milestone:

- Offline paragraph translation.
- Full-book translation.
- Cloud bookshelf.
- Public book discovery.
- Complex charts.
- Payment.
- Admin screens.
