# M12 Mobile Reader Seeded Emulator Acceptance

## Summary

M12-F10 added a compile-time gated seeded Reader entry for emulator visual QA. The route is unavailable by default and only opens when `ENABLE_ACCEPTANCE_READER=true`.

## Red Test

Command:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/app/app_router_acceptance_test.dart
```

Initial result:

- Failed at compile time because `StudyForReadApp(enableAcceptanceReader:)` did not exist.
- This matched the intended red state for the new gated acceptance entry.

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

- Focused acceptance route test: 2 tests passed.
- Full Flutter tests: 200 tests passed.
- Flutter analyze: No issues found.
- Debug APK build: passed after using an existing local sqlite3 native-asset cache because this machine could not resolve `release-assets.githubusercontent.com`.
- Install and launch on `emulator-5554`: passed.

## Local Build Note

The first APK build failed because `package:sqlite3` tried to download `libsqlite3.x64.android.so` and DNS resolution for `release-assets.githubusercontent.com` failed. The same binary already existed in local Flutter native-assets cache with the expected SHA-256 hash, so the APK was built using the local cached binary. No project dependency, source package, or committed file was changed for this workaround.

## Screenshots

Captured locally and not committed:

- `artifacts/m12-f10-reader-initial.png`
- `artifacts/m12-f10-reader-controls.png`
- `artifacts/m12-f10-reader-directory.png`
- `artifacts/m12-f10-reader-settings.png`

## Visual Notes

- The seeded acceptance build launches directly into the Reader instead of the signed-out auth page.
- Reader text is visible with pagination and first-line indentation.
- Tapping blank reading space opens the top/bottom Reader overlay.
- Real directory sheet opens and lists the two seeded chapters.
- Settings sheet opens and shows brightness, eye-protection, font size, background, page-turn, line spacing, paragraph spacing, and volume-key paging controls.
- The route has no main bottom navigation.

## Boundary Confirmation

- Route hidden by default: yes, covered by widget test.
- Backend calls: none.
- Real user EPUB/book content committed: no.
- Original file path, selected text, translation, chapter content sync payload, or secrets added: no.
- Screenshots/binaries committed: no.
