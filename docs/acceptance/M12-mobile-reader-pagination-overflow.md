# M12 Mobile Reader Pagination Overflow

## Summary

M12-F13 removes the Flutter debug overflow stripe from mobile Reader pages. The Reader pagination engine now splits a single oversized text paragraph into multiple page-sized chunks instead of placing the entire paragraph on one page.

## Root Cause

The paginated Reader measured each paragraph and assigned whole paragraphs to pages. If one paragraph was taller than the page, `_buildParagraphColumn` still rendered it as one child inside a fixed-height `PageView` page, causing `A RenderFlex overflowed` and the yellow/black debug stripe.

## Red Test

Command:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart --plain-name "paginated Japanese reader pages do not overflow at bottom"
```

Initial result:

- Failed with `A RenderFlex overflowed by 2305 pixels on the bottom`.
- The failing widget was the Reader paragraph `Column` in `reading_text_view.dart`.

## Fix

- Added a small pagination safety inset.
- Added text chunking for paragraphs whose measured height exceeds one page.
- Preserved the original paragraph index for translation state while using unique chunk keys for rendered split paragraphs.

## Verification

Commands:

```powershell
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart --plain-name "paginated Japanese reader pages do not overflow at bottom"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --target-platform android-x64 --dart-define=API_BASE_URL=http://10.0.2.2:8080
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
```

Results:

- Focused overflow regression: passed.
- Reader screen tests: 32 tests passed.
- Full Flutter tests: 202 tests passed.
- Flutter analyze: No issues found.
- Debug APK build: passed.
- Install and launch on `emulator-5554`: passed.

## Boundary Confirmation

- Debug overflow stripe hidden by disabling debug mode: no.
- EPUB image support changed: no.
- Backend/API/auth/deployment changed: no.
- User EPUB/book content committed: no.
