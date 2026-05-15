# M12-F10-T01 Mobile Reader Seeded Emulator Acceptance

## Task ID

`M12-F10-T01`

## Title

Add a gated seeded Reader entry for Android emulator visual acceptance.

## Goal

Make emulator acceptance able to open the real Reader UI directly with a tiny synthetic local book fixture, without weakening normal auth routing or requiring backend/login/import setup.

## Scope

This task does:

- Add a debug/acceptance-only Reader route gated by a Dart compile-time flag.
- Keep the route unavailable by default.
- Render the existing Reader screen using a seeded in-memory book and real Reader controller behavior.
- Use synthetic sample text only.
- Capture emulator screenshots of the Reader UI when possible.
- Record acceptance results and remaining visual issues.

This task does not:

- Change production signed-out auth behavior.
- Add a public button to the normal app.
- Use the user's EPUB or copyrighted content as a committed fixture.
- Add backend calls, live auth, sync worker behavior, or remote storage.
- Commit screenshots or build artifacts.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F10-T01-mobile-reader-seeded-emulator-acceptance.md`

Allowed mobile source:

- `apps/mobile/lib/src/app/study_for_read_app.dart`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/lib/src/features/reader/presentation/acceptance_reader_screen.dart`

Allowed tests:

- `apps/mobile/test/src/app/app_router_acceptance_test.dart`

Allowed acceptance report:

- `docs/acceptance/M12-mobile-reader-seeded-emulator-acceptance.md`

Allowed local-only artifacts, not committed:

- `artifacts/**`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## TDD Steps

- [x] Step 1: Write a widget test proving `/acceptance/reader` is hidden by default and redirects signed-out users to Sign In.
- [x] Step 2: Run the focused test and verify it fails only because the new acceptance behavior does not exist yet.
- [x] Step 3: Write a widget test proving `/acceptance/reader` opens a full-screen seeded Reader when explicitly enabled.
- [x] Step 4: Run the focused test and verify it fails only because the route/screen does not exist yet.
- [x] Step 5: Implement the minimal gated route and seeded Reader screen.
- [x] Step 6: Run the focused test until it passes.
- [x] Step 7: Run full mobile tests and analyze.
- [x] Step 8: Build/install/launch an Android debug APK with `--dart-define=ENABLE_ACCEPTANCE_READER=true`.
- [x] Step 9: Capture local screenshots under `artifacts/` and record visual acceptance notes.
- [x] Step 10: Commit and push only tracked task/code/test/report files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/app/app_router_acceptance_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --dart-define=ENABLE_ACCEPTANCE_READER=true
D:\Android\Sdk\platform-tools\adb.exe devices
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.studyforread.study_for_read_mobile -c android.intent.category.LAUNCHER 1
```

## Acceptance Criteria

- `/acceptance/reader` remains unavailable by default.
- A debug build with `ENABLE_ACCEPTANCE_READER=true` can start directly on `/acceptance/reader`.
- The seeded Reader shows real Reader pagination, tap overlay, directory, night/settings controls, and no bottom navigation.
- The seeded fixture contains no original book file path, user EPUB content, secrets, selected text, translations, or backend payload.
- Full Flutter tests and analyze pass.
- Emulator screenshots are captured locally and not committed.

## Stop Conditions

- Flutter tests fail outside the new intended red tests.
- Android build tooling or emulator is unavailable.
- The implementation requires weakening auth for normal routes.
- The implementation would commit raw book content, screenshots, binaries, `.env`, or secrets.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Emulator/device result.
- Screenshot artifact paths, if captured.
- Whether the route is gated off by default.
- Whether screenshots/binaries were committed.
- Whether code was uploaded.
- Blockers.
- Recommended next task card.
