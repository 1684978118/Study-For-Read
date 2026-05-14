# M12-F09-T01 Mobile Reader Emulator Acceptance

## Task ID

`M12-F09-T01`

## Title

Run Android emulator acceptance for the Tomato-style mobile Reader.

## Goal

Validate the current mobile Reader experience on an Android emulator after the Reader UI, settings, pagination, page-turn modes, and volume-key paging tasks.

## Scope

This task does:

- Check Android emulator and ADB availability.
- Run the current Flutter verification commands.
- Build and install the mobile app on the emulator when available.
- Launch the app and capture local screenshots when possible.
- Record acceptance results and any blockers.

This task does not:

- Modify Reader production code.
- Commit screenshots or binary artifacts.
- Add backend calls, cloud sync, or new dependencies.
- Claim real hardware behavior if only emulator key events are verified.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F09-T01-mobile-reader-emulator-acceptance.md`

Allowed for acceptance report:

- `docs/acceptance/M12-mobile-reader-emulator-acceptance.md`

Allowed local-only artifacts, not committed:

- `artifacts/**`

## Forbidden Files

- `apps/mobile/lib/**`
- `apps/mobile/android/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Acceptance Steps

- [x] Step 1: Run `git status --short --branch`.
- [x] Step 2: Run focused Reader tests.
- [x] Step 3: Run full Flutter tests and analyze.
- [x] Step 4: Check `adb devices` and `flutter devices`.
- [x] Step 5: Build/install/launch the app on an emulator if one is available.
- [x] Step 6: Capture local screenshots under `artifacts/` if the app launches.
- [x] Step 7: Record emulator acceptance notes and blockers.
- [x] Step 8: Commit and push only the task card/report, not screenshots.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\Android\Sdk\platform-tools\adb.exe devices
D:\flutter\flutter\bin\flutter.bat devices
```

## Acceptance Criteria

- Reader automated tests pass.
- Full Flutter tests pass.
- `flutter analyze` reports no issues.
- Emulator availability is truthfully recorded.
- If emulator is available, the app is installed/launched and screenshots are captured locally.
- Screenshots and build artifacts are not committed.

## Stop Conditions

- No emulator/device is available.
- Flutter Android build tooling is unavailable.
- App launch requires credentials or backend state not available locally.

## Completion Report Format

Reply with:

- Modified files.
- Verification commands.
- Verification results.
- Emulator/device result.
- Screenshot artifact paths, if captured.
- Whether production code changed.
- Whether screenshots/binaries were committed.
- Whether code was uploaded.
- Blockers.
- Recommended next task card.
