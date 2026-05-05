# Web Reader Local Data

This document defines the first-release browser-local data boundary for `apps/web-reader`.

## 1. Storage Decisions

Web reader storage choices are locked for first release:

- Framework: Nuxt and Vue.
- Browser database: IndexedDB through Dexie.
- Token storage: a web auth token store abstraction; first release may use `localStorage`.
- Imported book storage: parsed chapters in IndexedDB, not uploaded by default.
- Original file storage: do not store original file blobs in first release unless a later task card explicitly changes this document.

Do not introduce Firebase, Supabase, cloud object storage, server-side book upload, or a second browser database abstraction in first release.

## 2. Privacy Boundary

The browser may store parsed book content locally because the user imported it in that browser.

The web reader must not:

- Upload original files to the backend.
- Send full chapters to the backend.
- Put chapter content, paragraph content, translated text, or original file blobs into pending sync payloads.
- Log access tokens, refresh tokens, original book text, selected paragraph text, or translated paragraph text.
- Add cloud bookshelf behavior.

The backend sync boundary remains:

- Book metadata.
- Reading position.
- Vocabulary state.
- Study statistics.

## 3. IndexedDB Standards

- Store names use snake_case.
- Local ids use string UUIDs unless a business key is more natural.
- SHA-256 fingerprints use lowercase 64-character hex strings.
- Timestamps use UTC ISO-8601 strings.
- Enum-like values use lowercase strings checked before insert.
- Counters and positions are zero or positive.
- Migrations must be deterministic and covered by tests.

## 4. web_books

Stores imported book metadata for one signed-in user in one browser profile.

Fields:

| Field | Required | Notes |
| --- | --- | --- |
| id | yes | Local UUID |
| ownerUserId | yes | Backend user id string |
| bookFingerprint | yes | SHA-256 hex |
| title | yes | Parsed or file-derived title |
| author | no | Parsed when available |
| fileType | yes | `txt`, `epub` |
| sourceLang | yes | Default `ja` |
| targetLang | yes | Default `zh-CN` |
| originalFileName | yes | Browser-local display metadata only |
| chapterCount | yes | At least 1 |
| metadataSyncStatus | yes | `local_only`, `synced`, `dirty`, `failed` |
| lastOpenedAt | no | UTC ISO-8601 |
| lastSyncedAt | no | UTC ISO-8601 |
| createdAt | yes | UTC ISO-8601 |
| updatedAt | yes | UTC ISO-8601 |

Unique key:

- `ownerUserId, bookFingerprint`

Rules:

- `originalFileName` may be displayed but must not be sent to backend sync.
- `chapterCount >= 1`.

## 5. web_chapters

Stores parsed chapter text for browser-local reading.

Fields:

| Field | Required | Notes |
| --- | --- | --- |
| id | yes | Local UUID |
| bookId | yes | References `web_books.id` by application logic |
| chapterIndex | yes | Zero-based |
| title | yes | Display title |
| content | yes | Browser-local chapter content |
| paragraphCount | yes | At least 1 |
| createdAt | yes | UTC ISO-8601 |
| updatedAt | yes | UTC ISO-8601 |

Unique key:

- `bookId, chapterIndex`

Rules:

- `content` stays browser-local.
- Sync code must not read this store.

## 6. web_reading_positions

Stores browser-local reading progress and sync status.

Fields:

| Field | Required | Notes |
| --- | --- | --- |
| id | yes | Local UUID |
| bookId | yes | References `web_books.id` by application logic |
| currentChapterIndex | yes | Zero-based |
| currentParagraphIndex | yes | Zero-based |
| currentCharOffset | yes | Zero-based |
| progressSyncStatus | yes | `local_only`, `synced`, `dirty`, `failed` |
| lastReadAt | no | UTC ISO-8601 |
| lastSyncedAt | no | UTC ISO-8601 |
| createdAt | yes | UTC ISO-8601 |
| updatedAt | yes | UTC ISO-8601 |

Unique key:

- `bookId`

Rules:

- Position fields are zero or positive.
- Sync sends position only.

## 7. web_lexeme_cache

Stores public lexeme snapshots returned by lookup or vocabulary APIs.

Rules:

- Public lexeme cache may be reused locally.
- Public lexeme cache must not contain user review state.
- Fields mirror mobile `local_lexeme_cache`.

## 8. web_word_cards

Stores browser-local copies of user vocabulary cards and offline review state.

Rules:

- Public lexeme cards reference `web_lexeme_cache`.
- Private sentence cards store private sentence data only in `web_word_cards`.
- Private sentence cards must not be inserted into `web_lexeme_cache`.
- Fields mirror mobile `local_word_cards`.

## 9. web_translation_cache

Stores user-local paragraph translation results for convenience.

Rules:

- Translation cache is browser-local only.
- Translation cache must never be uploaded as corpus.
- Pending sync events must not include source paragraph previews or translated text.
- Fields mirror mobile `local_translation_cache`.

## 10. web_study_daily_stats

Stores browser-collected daily counters before and after sync.

Rules:

- Counter fields are zero or positive.
- Sync sends incremental counters through `/api/v1/stats/daily`.
- Fields mirror mobile `local_study_daily_stats`.

## 11. web_pending_sync_events

Stores outbound sync events while offline or after a failed request.

Fields mirror mobile `pending_sync_events`.

Allowed event types:

- `book_metadata`
- `reading_progress`
- `word_card_create`
- `word_card_review`
- `daily_stats`

Rules:

- `payloadJson` must not contain `content`, `chapterContent`, `chapter_content`, `originalFile`, `original_file`, `filePath`, `file_path`, `rawText`, `raw_text`, `translatedText`, `translated_text`, `paragraphText`, or `paragraph_text`.
- Sync worker must never read `web_chapters.content` or `web_translation_cache.translatedText`.

## 12. Parser Rules

The web reader uses browser `File` objects:

- TXT first supports UTF-8 and UTF-8 with BOM.
- Unsupported encodings return a typed import failure instead of garbled text.
- TXT chapter detection recognizes common Japanese and Chinese chapter headings, and falls back to one chapter when no heading exists.
- EPUB parser reads container metadata, package metadata, spine order, and XHTML text.
- EPUB parser ignores images, CSS, scripts, and remote resources in first release.

## 13. Web Reader Non-Goals

These are not part of first web reader milestone:

- Server-side book upload.
- Cloud bookshelf.
- Full-book translation.
- Public book discovery.
- Social sharing.
- Admin screens.
- Payment.
- Complex charts.
