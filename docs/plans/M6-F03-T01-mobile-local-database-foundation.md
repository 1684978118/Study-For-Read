# M6-F03-T01 Mobile Local Database Foundation

## Task ID

`M6-F03-T01`

## Title

Implement mobile SQLite database foundation.

## Goal

Create the mobile SQLite schema and repositories for local books, chapters, reading positions, and pending sync events.

## Scope

This task only does:

- Add database open and migration code.
- Add local data models for books, chapters, reading positions, and pending sync events.
- Add repository methods needed by import and reader tasks.
- Add SQLite tests with `sqflite_common_ffi`.

This task does not:

- Add UI.
- Parse TXT or EPUB.
- Copy files.
- Call backend sync APIs.
- Store tokens.

## Allowed Files

- `apps/mobile/lib/src/core/database/mobile_database.dart`
- `apps/mobile/lib/src/core/database/mobile_database_migrations.dart`
- `apps/mobile/lib/src/features/library/domain/local_book.dart`
- `apps/mobile/lib/src/features/library/domain/local_chapter.dart`
- `apps/mobile/lib/src/features/library/domain/local_reading_position.dart`
- `apps/mobile/lib/src/features/sync/domain/pending_sync_event.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
- `apps/mobile/lib/src/features/reader/data/local_reading_position_repository.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/test/src/core/database/mobile_database_test.dart`
- `apps/mobile/test/src/features/library/local_book_repository_test.dart`
- `apps/mobile/test/src/features/sync/pending_sync_event_repository_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/lib/src/features/library/presentation/**`
- `apps/mobile/lib/src/features/reader/presentation/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `docs/specs/API_CONTRACT.md`
- `apps/mobile/pubspec.yaml`

## Tests First

Create:

- `apps/mobile/test/src/core/database/mobile_database_test.dart`
- `apps/mobile/test/src/features/library/local_book_repository_test.dart`
- `apps/mobile/test/src/features/sync/pending_sync_event_repository_test.dart`

Test behavior:

- Database opens with foreign keys enabled.
- `local_books` enforces unique `owner_user_id + book_fingerprint`.
- `local_chapters` cascade-delete when the book is deleted.
- `local_reading_positions` allows only one row per book.
- Position fields reject negative values at repository validation.
- `pending_sync_events.payload_json` rejects forbidden content field names.
- Access tokens and refresh tokens have no SQLite columns.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/core/database test/src/features/library/local_book_repository_test.dart test/src/features/sync/pending_sync_event_repository_test.dart
```

Expected red result:

- Tests fail because database and repositories do not exist.

## Implementation Steps

- [ ] Step 1: Write database and repository tests.
- [ ] Step 2: Run red tests and confirm missing class failures.
- [ ] Step 3: Create `MobileDatabase` that opens SQLite and enables foreign keys.
- [ ] Step 4: Create migration version 1 with `local_books`, `local_chapters`, `local_reading_positions`, and `pending_sync_events`.
- [ ] Step 5: Create domain models matching `MOBILE_LOCAL_DATA.md`.
- [ ] Step 6: Create repository methods for inserting and listing books.
- [ ] Step 7: Create repository methods for inserting and loading chapters by book and index.
- [ ] Step 8: Create repository methods for upserting and loading reading position by book.
- [ ] Step 9: Create pending sync event repository with payload forbidden-field validation.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/core/database test/src/features/library/local_book_repository_test.dart test/src/features/sync/pending_sync_event_repository_test.dart
flutter analyze
```

## Acceptance Criteria

- SQLite schema matches `MOBILE_LOCAL_DATA.md`.
- Repository tests pass.
- Foreign keys are enabled.
- Tokens are not stored in SQLite.
- Sync payload validation rejects raw content fields.
- No parser, UI, or backend sync behavior is created.

## Stop Conditions

- `sqflite` or `sqflite_common_ffi` dependency is missing.
- Schema requires changing `MOBILE_LOCAL_DATA.md`.
- Any file outside Allowed Files must be modified.
- Any implementation stores tokens or raw sync content in the wrong place.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

