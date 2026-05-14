# M12-F04-T01 Mobile Reader Settings Panel

## Task ID

`M12-F04-T01`

## Title

Add the Fanqie-style mobile Reader settings panel.

## Goal

Make the Reader `设置` button open a real bottom settings panel that updates and persists reading preferences for font size, background, eye-protection mode, page-turn mode selection, line height, and paragraph spacing.

## Scope

This task does:

- Open a Reader settings bottom sheet from the existing `设置` action.
- Show settings sections: `亮度`, `护眼模式`, `字号`, `背景`, `翻页`, and `其他`.
- Keep `亮度` visible as the next task entry point, but do not implement app-local brightness effect in this task.
- Toggle `护眼模式` and visibly apply a warm Reader overlay.
- Change `字号` through settings controls and persist it.
- Select background presets and persist the selected background.
- Select page-turn mode and persist the selected mode.
- Change `行距` and `段距`, persist them, and apply them to the reading text layout.

This task does not:

- Implement real app-local brightness rendering; that belongs to M12-F05.
- Implement real page-turn animations; that belongs to M12-F07.
- Implement hardware volume-key paging; that belongs to M12-F08.
- Add comments, listen/read-aloud, share, download, or platform more-menu features.
- Add backend APIs or sync Reader preferences.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F04-T01-mobile-reader-settings-panel.md`

Allowed for implementation:

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/test/src/features/reader/reader_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `apps/mobile/lib/src/core/database/**`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/settings/**`
- `apps/mobile/lib/src/features/reader/domain/reader_preferences.dart`
- `apps/mobile/lib/src/features/reader/data/local_reader_preferences_repository.dart`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Tests First

Before production changes:

- Add controller tests proving background theme, eye-protection mode, line height, paragraph spacing, and page-turn mode persist.
- Add widget test proving tapping `设置` opens the settings panel with the required Chinese sections.
- Add widget test proving font-size controls update `ReadingTextView.fontSize`.
- Add widget test proving background selection changes persisted preference.
- Add widget test proving eye-protection toggle shows a visible Reader overlay and persists.
- Add widget test proving line height and paragraph spacing are applied to `ReadingTextView`.
- Run focused tests and confirm red before implementation.

## Implementation Steps

- [x] Step 1: Add red controller and widget tests.
- [x] Step 2: Confirm focused tests fail for missing controller preference methods and missing settings panel.
- [x] Step 3: Add controller methods for background, eye protection, line height, paragraph spacing, and page-turn mode.
- [x] Step 4: Pass persisted line height and paragraph spacing into `ReadingTextView`.
- [x] Step 5: Build the Reader settings bottom sheet.
- [x] Step 6: Apply background and eye-protection presentation to the Reader surface.
- [x] Step 7: Run focused tests, full Flutter tests, and analyze.
- [x] Step 8: Commit and push only allowed tracked files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- `设置` opens a bottom sheet in Reader.
- Settings panel shows `亮度`, `护眼模式`, `字号`, `背景`, `翻页`, and `其他`.
- Font-size controls update Reader text size and persist the preference.
- Background preset selection persists and changes Reader background.
- Eye-protection toggle persists and visibly adds a warm Reader presentation.
- Line height and paragraph spacing persist and affect reading layout.
- Page-turn mode selection persists, even though the animation behavior is implemented later.
- Existing `目录`, `夜间`, lookup, paragraph translation, and EPUB image display remain usable.
- No backend call is added.
- No sync payload contains original file path, full chapter/book content, selected text, paragraph text, translated text, image bytes, tokens, passwords, or secrets.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Real brightness rendering requires Android native or platform-channel work; stop and handle it in M12-F05.
- Real page-turn animations require a pagination engine; stop and handle them in M12-F06/F07.
- Any new third-party dependency is required.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Whether production code changed.
- Whether any Allowed Files boundary was crossed.
- Whether code was uploaded.
- Blockers.
- Recommended next task card.
