# M11-F07-T01 Mobile Reader Controls Occlusion Polish

## Task ID

`M11-F07-T01`

## Title

Make mobile Reader controls cover underlying text cleanly.

## Goal

Fix the emulator acceptance issue where the bottom Reader controls are translucent enough that chapter text remains visible underneath, making the page look visually noisy and partially obscured.

## Scope

This task only does:

- Make the top and bottom Reader control surfaces visually opaque.
- Keep the existing Reader controls, chapter navigation, font-size slider, and toggle behavior.
- Add a focused widget test that prevents the controls from using a translucent surface.

This task does not:

- Redesign Reader navigation or add new controls.
- Change reader scrolling, parsing, import, lookup, translation, sync, or database behavior.
- Change library, vocabulary, stats, settings, backend, web-reader, web-admin, or infra.

## Allowed Files

Always allowed:

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F07-T01-mobile-reader-controls-occlusion-polish.md`

Allowed only for the focused Reader controls fix:

- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

## Tests First

Before any production change:

- Add a focused Reader widget test that shows visible controls use an opaque control surface.
- Run the focused test and confirm it fails because the current surface alpha is below full opacity.

## Implementation Steps

- [x] Step 1: Add the failing widget test for opaque Reader controls.
- [x] Step 2: Run the focused test and confirm the red result.
- [x] Step 3: Make Reader control surfaces opaque.
- [x] Step 4: Run focused Reader tests, full Flutter tests, and analyze.
- [x] Step 5: Re-open the sample EPUB in the emulator and verify underlying text no longer bleeds through the controls.
- [ ] Step 6: Commit and push only allowed tracked files. Do not commit local screenshots unless explicitly requested.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- Reader top and bottom controls are not translucent over chapter text.
- Existing controls still show title, chapter title, previous/next buttons, progress label, and font size slider.
- Reader text remains visible and scrollable when controls are hidden.
- No lookup, paragraph translation, import, sync, or payload behavior changes.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Fixing the visual issue requires changing files outside Allowed Files.
- The issue turns out to be caused by emulator rendering or screenshot tooling rather than app UI.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Emulator/device status.
- Visual findings.
- Whether any Allowed Files boundary was crossed.
- Blockers.
- Recommended next task card.
