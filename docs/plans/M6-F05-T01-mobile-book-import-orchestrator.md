# M6-F05-T01 Mobile Book Import Orchestrator

## Task ID

`M6-F05-T01`

## Title

Implement mobile book import orchestration.

## Goal

Connect local file storage, fingerprinting, parsing, local database writes, and pending metadata sync events into one import service.

## Scope

This task only does:

- Add import service.
- Choose TXT or EPUB parser by file type.
- Store local book metadata, chapters, initial reading position, and pending metadata sync event.
- Add service tests with fake parsers and temporary files.

This task does not:

- Add file picker UI.
- Call backend APIs.
- Add reader UI.
- Add lookup, translation, or vocabulary.

## Allowed Files

- `apps/mobile/lib/src/features/library/data/book_import_service.dart`
- `apps/mobile/lib/src/features/library/data/book_file_storage_service.dart`
- `apps/mobile/lib/src/features/library/data/book_fingerprint_service.dart`
- `apps/mobile/lib/src/features/library/data/txt_book_parser.dart`
- `apps/mobile/lib/src/features/library/data/epub_book_parser.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
- `apps/mobile/lib/src/features/reader/data/local_reading_position_repository.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/test/src/features/library/book_import_service_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/library/presentation/**`
- `apps/mobile/lib/src/features/reader/presentation/**`
- `apps/mobile/lib/src/features/auth/**`
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
- `apps/mobile/lib/src/features/library/data/book_file_storage_service.dart`
- `apps/mobile/lib/src/features/library/data/txt_book_parser.dart`
- `apps/mobile/lib/src/features/library/data/epub_book_parser.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/library/book_import_service_test.dart`

Test behavior:

- Importing a TXT file stores one local book row, parsed chapter rows, and one reading position row.
- Importing an EPUB file uses the EPUB parser.
- Re-importing the same owner and fingerprint updates metadata without duplicating the book.
- Pending `book_metadata` sync event contains fingerprint, title, author, file type, language pair, and chapter count.
- Pending sync payload does not contain chapter content, original file path, or original file bytes.
- Import failure from parser does not insert partial book rows.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/book_import_service_test.dart
```

Expected red result:

- Test fails because import service does not exist.

## Implementation Steps

- [ ] Step 1: Write import service tests.
- [ ] Step 2: Run red test and confirm missing service failure.
- [ ] Step 3: Create `BookImportService`.
- [ ] Step 4: Copy the selected file through `BookFileStorageService`.
- [ ] Step 5: Select TXT or EPUB parser from `BookFileType`.
- [ ] Step 6: Insert or update `local_books` for current owner and fingerprint.
- [ ] Step 7: Replace local chapters for that book inside one database transaction.
- [ ] Step 8: Create initial reading position at chapter 0, paragraph 0, char offset 0 when missing.
- [ ] Step 9: Enqueue pending `book_metadata` sync event without local-only fields or content.
- [ ] Step 10: Roll back database writes on parser failure.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/book_import_service_test.dart
flutter analyze
```

## Acceptance Criteria

- Import service tests pass.
- Imported books and chapters are local-only.
- Pending sync event contains metadata only.
- Duplicate owner and fingerprint does not create duplicate books.
- No backend API call happens in this task.

## Stop Conditions

- Local database foundation is incomplete.
- TXT or EPUB parser task is incomplete.
- Import transaction cannot be implemented without changing database files outside Allowed Files.
- Any implementation uploads, logs, or stores raw content in sync payloads.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

