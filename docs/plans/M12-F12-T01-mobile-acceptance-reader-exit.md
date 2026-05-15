# M12-F12-T01 Mobile Acceptance Reader Exit

## Task ID

`M12-F12-T01`

## Title

Let the gated acceptance Reader exit back to the signed-out app.

## Goal

Fix the emulator acceptance build getting stuck on the seeded Reader page by wiring the Reader close button to return to Sign In.

## Scope

This task does:

- Add a regression test for closing the gated acceptance Reader.
- Wire `AcceptanceReaderScreen` to pass an `onClose` callback to `ReaderScreen`.
- Keep the acceptance route gated by `ENABLE_ACCEPTANCE_READER=true`.

This task does not:

- Change normal production Reader close behavior.
- Change auth routing for regular signed-out users.
- Add backend calls or seeded real user data.
- Commit screenshots or APK/build artifacts.

## Allowed Files

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F12-T01-mobile-acceptance-reader-exit.md`
- `apps/mobile/lib/src/features/reader/presentation/acceptance_reader_screen.dart`
- `apps/mobile/test/src/app/app_router_acceptance_test.dart`
- `docs/acceptance/M12-mobile-acceptance-reader-exit.md`

Allowed local-only artifacts, not committed:

- `artifacts/**`

## Forbidden Files

- `apps/mobile/lib/src/app/**`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## TDD Steps

- [x] Step 1: Add a failing widget test that opens `/acceptance/reader`, shows controls, taps `reader-close-button`, and expects Sign In.
- [x] Step 2: Run the focused acceptance route test and verify it fails because the close button does not exit.
- [x] Step 3: Implement the minimal `onClose` callback in `AcceptanceReaderScreen`.
- [x] Step 4: Run the focused acceptance route test until it passes.
- [x] Step 5: Run full mobile tests and analyze.
- [x] Step 6: Build/install the acceptance APK when possible so the emulator can leave the seeded page.
- [x] Step 7: Commit and push only tracked task/code/test/report files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/app/app_router_acceptance_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --target-platform android-x64 --dart-define=ENABLE_ACCEPTANCE_READER=true
```

## Acceptance Criteria

- The acceptance Reader close button returns to Sign In.
- Normal signed-out users still cannot open `/acceptance/reader` without the flag.
- Full Flutter tests and analyze pass.
- No screenshots, APKs, `.env`, secrets, or user book content are committed.

## Stop Conditions

- The fix requires changing normal Reader close behavior.
- The fix requires weakening production auth redirects.
- Flutter tests fail outside the intended red phase.
