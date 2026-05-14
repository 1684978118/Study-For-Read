# M12-F02-T01 Mobile Reader Preferences Persistence

## Task ID

`M12-F02-T01`

## Title

Persist global mobile Reader preferences for the Tomato-style Reader.

## Goal

Add local persistence for global Reader preferences so the later Fanqie/Tomato-style controls and settings panel can read and update real settings instead of temporary UI state.

## Scope

This task only does:

- Add a SQLite v3 migration for one global Reader preferences row.
- Add a Reader preferences domain model.
- Add a local Reader preferences repository.
- Load persisted preferences into `ReaderController`.
- Persist Reader preference changes made through controller methods.
- Keep current Reader UI behavior mostly unchanged except using persisted font size when available.

This task does not:

- Build the new Tomato-style bottom bar.
- Build the settings panel UI.
- Build the chapter directory UI.
- Implement app-local brightness effect.
- Implement real pagination or page-turn animations.
- Implement hardware volume-key handling.
- Add dependencies.
- Add backend APIs or sync Reader preferences.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F02-T01-mobile-reader-preferences-persistence.md`

Allowed for implementation:

- `apps/mobile/lib/src/core/database/mobile_database_migrations.dart`
- `apps/mobile/lib/src/features/reader/domain/reader_preferences.dart`
- `apps/mobile/lib/src/features/reader/data/local_reader_preferences_repository.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/test/src/core/database/mobile_database_test.dart`
- `apps/mobile/test/src/features/reader/local_reader_preferences_repository_test.dart`
- `apps/mobile/test/src/features/reader/reader_controller_test.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/settings/**`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Reader Preference Fields

Persist one global row with:

- `fontSize`
- `lineHeight`
- `paragraphSpacing`
- `backgroundTheme`
- `nightModeEnabled`
- `previousBackgroundTheme`
- `brightness`
- `eyeProtectionEnabled`
- `pageTurnMode`
- `volumeKeyPagingEnabled`

Initial defaults:

- `fontSize`: existing `ReaderController.defaultFontSize`
- `lineHeight`: `1.72`
- `paragraphSpacing`: `18`
- `backgroundTheme`: `paperWhite`
- `nightModeEnabled`: `false`
- `previousBackgroundTheme`: `paperWhite`
- `brightness`: `1.0`
- `eyeProtectionEnabled`: `false`
- `pageTurnMode`: `slide`
- `volumeKeyPagingEnabled`: `false`

## Tests First

Before production changes:

- Add database test proving `local_reader_preferences` exists with expected columns and no raw-content/secrets columns.
- Add repository test proving defaults are returned when no row exists.
- Add repository test proving updated preferences persist and reload.
- Add controller test proving `load()` applies persisted font size.
- Add controller test proving changing font size persists through the preferences repository.
- Run focused tests and confirm red.

## Implementation Steps

- [x] Step 1: Add red database/repository/controller tests.
- [x] Step 2: Confirm focused tests fail for missing table/classes/controller wiring.
- [x] Step 3: Add v3 migration and create the local preferences table.
- [x] Step 4: Add `ReaderPreferences` model and validation/default helpers.
- [x] Step 5: Add `LocalReaderPreferencesRepository`.
- [x] Step 6: Wire `ReaderController.local()` and constructor injection to load preferences.
- [x] Step 7: Persist font-size changes through the preferences repository.
- [x] Step 8: Run focused tests, full Flutter tests, and analyze.
- [x] Step 9: Commit and push only allowed tracked files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/core/database/mobile_database_test.dart test/src/features/reader/local_reader_preferences_repository_test.dart test/src/features/reader/reader_controller_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- SQLite database version increases to v3.
- Fresh databases include `local_reader_preferences`.
- Upgrade from v1/v2 creates `local_reader_preferences`.
- Repository returns defaults when the table is empty.
- Repository persists and reloads all confirmed Reader preference fields.
- `ReaderController.load()` applies persisted font size.
- `ReaderController.setFontSize()` persists the updated font size.
- No preferences table or payload includes book content, chapter content, selected text, paragraph text, translated text, original file path, token, password, or secret.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Persisting preferences requires new third-party dependencies.
- A preference must be synced to backend.
- Implementation needs Android native code; that belongs to the later brightness or volume-key cards.

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
