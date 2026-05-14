# M12-F08-T01 Mobile Reader Volume-Key Paging

## Task ID

`M12-F08-T01`

## Title

Add Reader-only volume-key paging.

## Goal

Make the Reader `音量键翻页` preference real: when enabled, volume down moves forward and volume up moves backward inside the Reader only.

## Scope

This task does:

- Add `ReaderController.setVolumeKeyPagingEnabled`.
- Add `音量键翻页` switch to the Reader settings `其他` section.
- Handle Flutter key events for volume up/down while Reader is focused.
- Map volume down to next page or next chapter at page edge.
- Map volume up to previous page or previous chapter at page edge.
- Keep the behavior Reader-only.

This task does not:

- Add Android native code or permissions.
- Override OS/system volume outside Flutter key events.
- Add background service handling.
- Add backend APIs or sync Reader preferences.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F08-T01-mobile-reader-volume-key-paging.md`

Allowed for implementation:

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
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
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
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

- Add controller test proving the volume-key paging preference persists.
- Add widget test proving the settings switch toggles and persists `音量键翻页`.
- Add widget test proving volume down advances a page when enabled.
- Add widget test proving volume up moves backward when enabled.
- Add widget test proving volume keys do nothing when the preference is disabled.
- Run focused tests and confirm red before implementation.

## Implementation Steps

- [x] Step 1: Add red controller and widget tests.
- [x] Step 2: Confirm focused tests fail for missing controller method and missing key handling.
- [x] Step 3: Add `setVolumeKeyPagingEnabled` to `ReaderController`.
- [x] Step 4: Add the settings switch.
- [x] Step 5: Add Reader-only `Focus`/key event handling for volume up/down.
- [x] Step 6: Run focused tests, full Flutter tests, and analyze.
- [x] Step 7: Commit and push only allowed tracked files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- `音量键翻页` appears in Reader settings under `其他`.
- The switch persists to local Reader preferences.
- With the switch on, volume down moves forward and volume up moves backward.
- With the switch off, volume keys do not page the Reader.
- The behavior is scoped to Reader UI and does not add native Android code.
- No backend call is added.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Reliable hardware volume capture requires Android native code.
- A system permission or platform channel becomes necessary.

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
