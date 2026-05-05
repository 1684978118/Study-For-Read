# M6-F01-T02 Mobile Routing Theme Auth Gate

## Task ID

`M6-F01-T02`

## Title

Add mobile app routing, theme, and signed-out gate.

## Goal

Replace the generated Flutter counter app with Study For Read mobile shell screens and routing that sends signed-out users to authentication screens.

## Scope

This task only does:

- Add app root widget.
- Add routing shell.
- Add light and dark theme baseline.
- Add placeholder screens for Sign In, Register, Library, Vocabulary, Stats, and Settings.
- Add Reader route as a standalone full-screen route, not a bottom-navigation tab.
- Add widget tests for initial signed-out routing and bottom navigation placeholders.

This task does not:

- Implement real login.
- Store tokens.
- Call backend APIs.
- Add local database.
- Add file import.

## Allowed Files

- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/src/app/study_for_read_app.dart`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/lib/src/app/app_theme.dart`
- `apps/mobile/lib/src/features/auth/presentation/sign_in_screen.dart`
- `apps/mobile/lib/src/features/auth/presentation/register_screen.dart`
- `apps/mobile/lib/src/features/library/presentation/library_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_screen.dart`
- `apps/mobile/lib/src/features/settings/presentation/settings_screen.dart`
- `apps/mobile/test/src/app/app_router_test.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `apps/mobile/ios/**`
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
- `docs/specs/ARCHITECTURE.md`
- `apps/mobile/lib/main.dart`
- `apps/mobile/pubspec.yaml`

## Tests First

Create:

- `apps/mobile/test/src/app/app_router_test.dart`

Test behavior:

- App starts on the Sign In screen when no session provider exists.
- Sign In screen has a route to Register.
- Signed-out users cannot open Library directly through router location.
- Placeholder bottom navigation labels exist for Library, Vocabulary, Stats, and Settings when the app shell is built with a signed-in test override.
- Reader route exists but does not appear as a bottom-navigation item.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/app/app_router_test.dart
```

Expected red result:

- Test fails because `StudyForReadApp` or routing files do not exist.

## Implementation Steps

- [ ] Step 1: Write `app_router_test.dart`.
- [ ] Step 2: Run red test and confirm missing app or route failure.
- [ ] Step 3: Replace generated `main.dart` with `ProviderScope` and `StudyForReadApp`.
- [ ] Step 4: Create `StudyForReadApp` using `MaterialApp.router`.
- [ ] Step 5: Create `app_theme.dart` with light and dark `ThemeData`.
- [ ] Step 6: Create `app_router.dart` with routes for `/sign-in`, `/register`, `/library`, `/reader`, `/vocabulary`, `/stats`, and `/settings`.
- [ ] Step 7: Redirect signed-out users to `/sign-in`.
- [ ] Step 8: Create placeholder screens with stable keys and visible titles from `UI_FLOWS.md` and `MOBILE_UI_STYLE.md`.
- [ ] Step 9: Ensure bottom navigation excludes Reader.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/app/app_router_test.dart
flutter analyze
```

## Acceptance Criteria

- Generated counter app is gone.
- Signed-out default route is Sign In.
- Register route is reachable from Sign In.
- App shell screen placeholders exist.
- Bottom navigation contains Library, Vocabulary, Stats, and Settings only.
- Reader is reachable as a standalone route only.
- No backend, database, or import logic is added.

## Stop Conditions

- M6-F01-T01 is incomplete.
- Router implementation requires dependencies not listed in `pubspec.yaml`.
- Widget tests cannot start because generated project is broken.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
