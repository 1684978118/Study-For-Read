# M12 Mobile Reader Visual Polish From Emulator

## Summary

M12-F11 polished two emulator-visible Reader issues:

- Paragraph translation action no longer renders a visible `+` text node in the reading flow.
- The seeded acceptance Reader now uses Chinese synthetic title, chapter titles, and body copy.

## Red Test

Command:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_paragraph_translation_test.dart test/src/app/app_router_acceptance_test.dart
```

Initial result:

- Failed because `Icons.add_circle_outline` hotspots were not present.
- Failed because the seeded acceptance Reader still used the old English-heavy text.
- This matched the intended red state.

## Verification

Commands:

```powershell
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_paragraph_translation_test.dart test/src/app/app_router_acceptance_test.dart test/src/regression/mobile_learning_loop_regression_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --target-platform android-x64 --dart-define=ENABLE_ACCEPTANCE_READER=true
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.studyforread.study_for_read_mobile -c android.intent.category.LAUNCHER 1
```

Results:

- Focused tests: 7 tests passed.
- Full Flutter tests: 200 tests passed.
- Flutter analyze: No issues found.
- Debug APK build: passed.
- Install and launch on `emulator-5554`: passed.

## Screenshots

Captured locally and not committed:

- `artifacts/m12-f11-reader-polished-initial.png`
- `artifacts/m12-f11-reader-polished-controls.png`

## Visual Notes

- The paragraph action is now a low-alpha `add_circle_outline` icon instead of a text `+`.
- The icon remains near the paragraph end and keeps the existing paragraph translation tap target.
- The seeded Reader body is Chinese synthetic text, which makes visual review closer to the intended reading experience.
- The route remains gated behind `ENABLE_ACCEPTANCE_READER=true`.

## Boundary Confirmation

- Backend calls: none.
- User EPUB/book content committed: no.
- Original file path, selected text, translation, chapter content sync payload, or secrets added: no.
- Screenshots/binaries committed: no.
