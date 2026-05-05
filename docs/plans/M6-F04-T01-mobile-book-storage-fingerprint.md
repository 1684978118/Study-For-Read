# M6-F04-T01 Mobile Book Storage Fingerprint

## Task ID

`M6-F04-T01`

## Title

Implement local book file storage and fingerprinting.

## Goal

Copy selected book files into app-private storage and calculate stable lowercase SHA-256 fingerprints without uploading file content.

## Scope

This task only does:

- Add file type detection for TXT and EPUB.
- Add app-private copy service.
- Add SHA-256 fingerprint service.
- Add tests using temporary local files.

This task does not:

- Parse book chapters.
- Insert database rows.
- Open file picker UI.
- Call backend APIs.

## Allowed Files

- `apps/mobile/lib/src/features/library/domain/book_file_type.dart`
- `apps/mobile/lib/src/features/library/data/book_file_storage_service.dart`
- `apps/mobile/lib/src/features/library/data/book_fingerprint_service.dart`
- `apps/mobile/lib/src/features/library/data/stored_book_file.dart`
- `apps/mobile/test/src/features/library/book_file_storage_service_test.dart`
- `apps/mobile/test/src/features/library/book_fingerprint_service_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/core/database/**`
- `apps/mobile/lib/src/features/library/data/*parser*.dart`
- `apps/mobile/lib/src/features/library/presentation/**`
- `apps/mobile/lib/src/features/reader/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `apps/mobile/pubspec.yaml`

## Tests First

Create:

- `apps/mobile/test/src/features/library/book_file_storage_service_test.dart`
- `apps/mobile/test/src/features/library/book_fingerprint_service_test.dart`

Test behavior:

- `.txt` maps to `BookFileType.txt`.
- `.epub` maps to `BookFileType.epub`.
- Unsupported extension returns a typed import failure.
- Fingerprint for known bytes equals expected lowercase SHA-256 hex.
- Copied file is placed under an app-private books directory.
- Returned storage model includes local path, original filename, file type, and fingerprint.
- Service never returns file bytes or content in the model.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/book_file_storage_service_test.dart test/src/features/library/book_fingerprint_service_test.dart
```

Expected red result:

- Tests fail because storage and fingerprint services do not exist.

## Implementation Steps

- [ ] Step 1: Write storage and fingerprint tests.
- [ ] Step 2: Run red tests and confirm missing class failures.
- [ ] Step 3: Create `BookFileType` enum with `txt` and `epub`.
- [ ] Step 4: Create `BookFingerprintService` that streams file bytes and returns SHA-256 lowercase hex.
- [ ] Step 5: Create `StoredBookFile` without file content fields.
- [ ] Step 6: Create `BookFileStorageService` that copies selected file into an app-private books directory.
- [ ] Step 7: Reject unsupported file extensions with a typed import failure.
- [ ] Step 8: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/book_file_storage_service_test.dart test/src/features/library/book_fingerprint_service_test.dart
flutter analyze
```

## Acceptance Criteria

- TXT and EPUB file types are recognized.
- SHA-256 fingerprint is deterministic and lowercase.
- Original file content is copied only to app-private storage.
- No backend API or database code is added.
- No returned DTO includes original file bytes or chapter content.

## Stop Conditions

- File storage requires a dependency not already in `pubspec.yaml`.
- Platform-specific storage behavior cannot be tested with temporary files.
- Any file outside Allowed Files must be modified.
- Any implementation uploads or logs file content.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
