# M12-F11-T01 Mobile Reader Visual Polish From Emulator

## Task ID

`M12-F11-T01`

## Title

Polish Reader paragraph action and seeded acceptance copy after emulator screenshots.

## Goal

Fix the most visible emulator acceptance issues: the paragraph translation `+` should not look like inserted book text, and the seeded acceptance Reader should use natural Chinese copy for visual review.

## Scope

This task does:

- Replace the visible paragraph translation `+` text with a subtle icon-style touch target that stays near the paragraph end.
- Keep paragraph translation behavior and tests for tapping the hotspot.
- Update the seeded acceptance book title, chapter titles, and sample body to Chinese-only synthetic text.
- Keep the acceptance route gated by `ENABLE_ACCEPTANCE_READER=true`.
- Capture updated emulator screenshots when possible.

This task does not:

- Redesign the full Reader page.
- Change lookup behavior, translation API calls, or vocabulary save flow.
- Add new Reader settings.
- Use the user's EPUB or copyrighted content as a fixture.
- Commit screenshots or APK/build artifacts.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F11-T01-mobile-reader-visual-polish-from-emulator.md`

Allowed mobile source:

- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/reader/presentation/acceptance_reader_screen.dart`

Allowed tests:

- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`
- `apps/mobile/test/src/app/app_router_acceptance_test.dart`
- `apps/mobile/test/src/regression/mobile_learning_loop_regression_test.dart`

Allowed acceptance report:

- `docs/acceptance/M12-mobile-reader-visual-polish-from-emulator.md`

Allowed local-only artifacts, not committed:

- `artifacts/**`

## Forbidden Files

- `apps/mobile/lib/src/app/**`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## TDD Steps

- [x] Step 1: Update Reader paragraph translation tests to require the hotspot icon and reject visible `+` text.
- [x] Step 2: Run the focused Reader paragraph translation test and verify it fails because the current UI renders `+`.
- [x] Step 3: Update acceptance route tests to require Chinese seeded copy and reject the old English seeded paragraph.
- [x] Step 4: Run the focused acceptance route test and verify it fails because the current fixture is English-heavy.
- [x] Step 5: Implement the minimal Reader hotspot icon and Chinese seed copy.
- [x] Step 6: Run focused tests until they pass.
- [x] Step 7: Run full mobile tests and analyze.
- [x] Step 8: Build/install/launch an Android debug APK with `--dart-define=ENABLE_ACCEPTANCE_READER=true` when possible.
- [x] Step 9: Capture updated local screenshots under `artifacts/` and record notes.
- [x] Step 10: Commit and push only tracked task/code/test/report files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_paragraph_translation_test.dart test/src/app/app_router_acceptance_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --target-platform android-x64 --dart-define=ENABLE_ACCEPTANCE_READER=true
```

## Acceptance Criteria

- Paragraph translation hotspot remains tappable.
- Reader no longer renders visible `+` text as paragraph content.
- Seeded acceptance Reader uses Chinese-only synthetic body copy.
- Full Flutter tests and analyze pass.
- Emulator screenshots, if captured, are local-only and not committed.

## Stop Conditions

- The change requires touching lookup/translation API or backend code.
- The acceptance fixture would include user book content or original file paths.
- Flutter tests fail outside the intended red phase.
- APK build is blocked by local tooling or native asset cache.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Emulator/device result.
- Screenshot artifact paths, if captured.
- Whether screenshots/binaries were committed.
- Whether code was uploaded.
- Blockers.
- Recommended next task card.
