# M12 Mobile Acceptance Reader Exit

## Summary

M12-F12 fixes the gated acceptance build getting stuck on the seeded Reader page. The acceptance Reader now passes an explicit close callback to `ReaderScreen`, so the top-left Reader close button returns to Sign In.

## Root Cause

Normal local book Reader routes pass `onClose` into `ReaderScreen`. The gated `AcceptanceReaderScreen` directly created `ReaderScreen(controller: _controller)` without `onClose`, so the visible close button had no exit behavior.

## Red Test

Command:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/app/app_router_acceptance_test.dart
```

Initial result:

- Failed because tapping `reader-close-button` did not show `sign-in-email-field`.
- This matched the reported stuck-on-acceptance-reader bug.

## Verification

Commands:

```powershell
D:\flutter\flutter\bin\flutter.bat test test/src/app/app_router_acceptance_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --target-platform android-x64 --dart-define=ENABLE_ACCEPTANCE_READER=true
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.studyforread.study_for_read_mobile -c android.intent.category.LAUNCHER 1
```

Results:

- Focused acceptance route test: 3 tests passed.
- Full Flutter tests: 201 tests passed.
- Flutter analyze: No issues found.
- Debug APK build: passed.
- Install and launch on `emulator-5554`: passed.
- Manual emulator check: tapping blank reader area, then top-left close, returns to Sign In.

## Screenshot

Captured locally and not committed:

- `artifacts/m12-f12-acceptance-reader-exit.png`

## Boundary Confirmation

- Normal Reader close behavior changed: no.
- Production auth route weakened: no.
- Backend calls: none.
- User EPUB/book content committed: no.
- Screenshots/binaries committed: no.
