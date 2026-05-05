# M6-F06-T01 Mobile Library Screen Import Flow

## Task ID

`M6-F06-T01`

## Title

Implement mobile library screen and import flow.

## Goal

Show local imported books and let the signed-in user choose a TXT or EPUB file to import.

## Scope

This task only does:

- Add file picker abstraction.
- Add library controller.
- Update Library screen for empty, loading, imported list, and error states.
- Add widget tests with fake picker and fake import service.

This task does not:

- Implement reader page.
- Call backend sync APIs.
- Add lookup or translation.
- Add vocabulary.

## Allowed Files

- `apps/mobile/lib/src/features/library/data/book_file_picker.dart`
- `apps/mobile/lib/src/features/library/data/book_import_service.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/library/presentation/library_controller.dart`
- `apps/mobile/lib/src/features/library/presentation/library_screen.dart`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/test/src/features/library/library_screen_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/reader/**`
- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/study/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/library/data/book_import_service.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/library/presentation/library_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/library/library_screen_test.dart`

Test behavior:

- Empty Library shows an import action and text that books stay on this device.
- Tapping import calls file picker.
- Selecting TXT calls `BookImportService`.
- Successful import refreshes the visible book list.
- Import failure shows inline error.
- Imported list item shows title, author when present, file type, and sync status.
- Library screen does not display original file path.
- Tapping a book navigates to Reader with local book id.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/library_screen_test.dart
```

Expected red result:

- Test fails because library controller or import UI does not exist.

## Implementation Steps

- [ ] Step 1: Write library screen widget tests.
- [ ] Step 2: Run red test and confirm missing controller or UI behavior.
- [ ] Step 3: Create `BookFilePicker` abstraction wrapping `file_picker`.
- [ ] Step 4: Create `LibraryController` that loads local books for current user.
- [ ] Step 5: Add import action that calls picker and import service.
- [ ] Step 6: Render empty, loading, imported list, and error states.
- [ ] Step 7: Hide original local file path from UI.
- [ ] Step 8: Add route navigation from book item to Reader using local book id.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/library_screen_test.dart
flutter analyze
```

## Acceptance Criteria

- Library screen tests pass.
- User can start import through file picker abstraction.
- Imported books appear in Library.
- Original file path and chapter content are not displayed.
- Reader navigation passes local book id only.
- No backend sync call is added.

## Stop Conditions

- Import service is incomplete.
- Current user id is not available from auth session.
- Widget test requires platform file picker instead of fake picker.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
