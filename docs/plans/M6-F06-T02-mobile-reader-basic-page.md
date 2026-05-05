# M6-F06-T02 Mobile Reader Basic Page

## Task ID

`M6-F06-T02`

## Title

Implement basic local reader page.

## Goal

Open a locally imported book, display one chapter, navigate chapters, adjust font size, theme, and save local reading position.

## Scope

This task only does:

- Add reader controller.
- Load local book, chapters, and reading position.
- Render readable chapter text.
- Add temporary full-screen reader controls for previous chapter, next chapter, font size, and progress.
- Save local reading position when leaving or changing chapter.
- Add widget tests.

This task does not:

- Add word lookup.
- Add paragraph translation.
- Add furigana annotation.
- Add sync API calls.
- Add EPUB styling.

## Allowed Files

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/reader/data/local_reading_position_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`
- `apps/mobile/test/src/features/reader/reader_controller_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/auth/**`
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
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
- `apps/mobile/lib/src/features/reader/data/local_reading_position_repository.dart`
- `apps/mobile/lib/src/app/app_router.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/reader/reader_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

Test behavior:

- Opening Reader with a valid local book id loads saved chapter index.
- Reader default state displays chapter text full-screen without bottom app navigation.
- Tapping blank reading space toggles temporary reader controls.
- Temporary controls display book title, chapter title, previous, next, progress, and font size control.
- Next chapter updates visible chapter and saves progress.
- Previous chapter updates visible chapter and saves progress.
- Reader disables previous on first chapter and next on last chapter.
- Font size control changes text size within configured min and max.
- Missing local book id shows a not-found state.
- Reader does not call backend APIs.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
```

Expected red result:

- Tests fail because reader controller or UI behavior does not exist.

## Implementation Steps

- [ ] Step 1: Write reader controller and widget tests.
- [ ] Step 2: Run red tests and confirm missing reader behavior.
- [ ] Step 3: Create `ReaderController` that loads local book, chapters, and position.
- [ ] Step 4: Create `ReadingTextView` for chapter text with configurable font size.
- [ ] Step 5: Update `ReaderScreen` to show full-screen text by default.
- [ ] Step 6: Add tap-to-toggle temporary top and bottom reader controls matching `MOBILE_UI_STYLE.md`.
- [ ] Step 7: Implement previous and next chapter commands.
- [ ] Step 8: Save local reading position with `progress_sync_status=dirty`.
- [ ] Step 9: Add not-found and empty-chapter states.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
flutter analyze
```

## Acceptance Criteria

- Reader tests pass.
- Reader opens local book by local book id.
- Reader displays local chapter text.
- Reader hides main bottom navigation while reading.
- Reader controls appear only as temporary overlays.
- Chapter navigation works.
- Reading position saves locally.
- No lookup, translation, vocabulary, or backend sync behavior is added.

## Stop Conditions

- Library navigation task is incomplete.
- Local chapter repository cannot load chapter by index.
- Widget layout cannot fit text controls in mobile test viewport.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
