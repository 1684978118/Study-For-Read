# M11-F02-T01 Mobile Reader Inline Translate Hotspot

## Task ID

`M11-F02-T01`

## Title

Keep the Reader paragraph translation `+` close to the paragraph end.

## Goal

Fix emulator acceptance where the Reader translation `+` appears on a separate left-aligned line instead of staying near the end of the paragraph text.

## Scope

This task only does:

- Add a focused Reader widget test for translate hotspot placement.
- Render the paragraph `+` inline with the paragraph text.
- Preserve the existing lookup tap and paragraph translation tap behavior.
- Preserve the subtle visual style of the `+`.

This task does not:

- Change Reader routing or controls.
- Change lookup bottom sheet behavior.
- Change paragraph translation API calls or caching.
- Add copy/save/collapse controls to translated paragraphs.
- Change database, sync payload, auth, or import behavior.

## Allowed Files

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F02-T01-mobile-reader-inline-translate-hotspot.md`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/app/**`
- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`
- `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`
- `docs/plans/IMPLEMENTATION_START_GATE.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`

## Tests First

Modify:

- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`

Test behavior:

- A long paragraph wraps naturally and the `paragraph-translate-hotspot-0` top edge is close to the paragraph text bottom edge, not a separate left-aligned row below the paragraph.
- Existing behavior still holds: tapping `+` translates exactly one paragraph and keeps the `+` visible.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_paragraph_translation_test.dart
```

Expected red result:

- The new placement test fails because the current `Wrap` layout can place `+` below the paragraph on its own line.

## Implementation Steps

- [ ] Step 1: Add the failing hotspot placement test.
- [ ] Step 2: Run the focused Reader paragraph translation test and confirm the placement failure.
- [ ] Step 3: Update `ReadingTextView` so paragraph text and `+` are rendered in one inline text flow.
- [ ] Step 4: Run the focused test and confirm it passes.
- [ ] Step 5: Run full Flutter tests and analyze.
- [ ] Step 6: Reinstall on emulator and capture a Reader screenshot for manual acceptance.
- [ ] Step 7: Commit and push the task card plus implementation.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_paragraph_translation_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Manual Emulator Acceptance

- Install the debug app on `emulator-5554`.
- Open Library, then open the local smoke book.
- Confirm the paragraph translation `+` is visually near the paragraph end instead of a separate left-aligned line.

## Acceptance Criteria

- Reader `+` remains subtle.
- Reader `+` stays near paragraph text end on a phone viewport.
- Tapping paragraph text still opens lookup.
- Tapping `+` still translates exactly one selected paragraph.
- The app still sends only the selected paragraph string for translation and does not send full chapter or full book text.

## Stop Conditions

- Implementation requires modifying files outside Allowed Files.
- Inline placement requires changing Reader screen or controller contracts.
- Tests fail because lookup or translation behavior changed unexpectedly.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Manual emulator acceptance screenshot path.
- Whether any Allowed Files boundary was crossed.
- Blockers.
- Recommended next task card.
