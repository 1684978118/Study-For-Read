# M11-F06-T01 Mobile Reader Text Hitbox Polish

## Task ID

`M11-F06-T01`

## Title

Polish mobile Reader paragraph indentation and blank-space tap behavior.

## Goal

Fix the emulator acceptance issues where Reader paragraphs have no visible first-line indent and tapping ordinary blank space beside text opens lookup instead of showing the reading controls.

## Scope

This task only does:

- Add a visible one-character first-line indent for text paragraphs in the mobile Reader.
- Keep lookup and paragraph translation requests based on the original paragraph text, not the displayed indent.
- Restrict lookup tap handling to actual rendered text instead of the full paragraph row.
- Let blank reading space continue to toggle the Reader controls.
- Add focused widget tests for indentation and blank-space tap behavior.

This task does not:

- Change EPUB/TXT parsing or stored chapter content.
- Change lookup, translation, vocabulary, sync, or backend payload contracts.
- Add a new reader settings UI.
- Redesign the Reader controls.
- Modify web-reader, web-admin, server, infra, or old project paths.

## Allowed Files

Always allowed:

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F06-T01-mobile-reader-text-hitbox-polish.md`

Allowed only for the focused Reader fix:

- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/test/src/features/reader/reader_lookup_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`
- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`

## Forbidden Files

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
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/test/src/features/reader/reader_lookup_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

## Tests First

Before any production change:

- Add a Reader widget test showing text paragraphs display with a first-line full-width indent.
- Add a Reader widget test showing a tap in blank space beside a short paragraph toggles controls instead of opening lookup.
- Run the focused tests and confirm they fail for the expected reason.

## Implementation Steps

- [x] Step 1: Add failing widget tests for paragraph indent and blank-space tap behavior.
- [x] Step 2: Run the focused tests and confirm the red result.
- [x] Step 3: Render text paragraphs with a display-only full-width indent.
- [x] Step 4: Replace the full-row lookup gesture with text-only hit testing.
- [x] Step 5: Confirm paragraph translation `+` still works and lookup sends original paragraph context.
- [x] Step 6: Run focused Reader tests, full Flutter tests, and analyze.
- [x] Step 7: Re-open the sample EPUB in the emulator and capture acceptance screenshots if useful.
- [ ] Step 8: Commit and push only allowed tracked files. Do not commit local screenshots unless explicitly requested.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_lookup_test.dart test/src/features/reader/reader_screen_test.dart test/src/features/reader/reader_paragraph_translation_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- Text paragraphs visually start with a one-character full-width indent.
- The lookup bottom sheet opens when tapping rendered text.
- Tapping ordinary blank space to the side of a short paragraph shows the top and bottom Reader controls, not lookup.
- The paragraph translation `+` remains tappable.
- Lookup and paragraph translation still use the original paragraph content without the display-only indent.
- No chapter content, selected text, translated text, original file path, tokens, passwords, or secrets are newly exposed.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Fixing this requires changing parser, database, backend, sync, or files outside Allowed Files.
- The text-only hitbox cannot coexist with paragraph translation without a larger Reader redesign.
- Emulator is unavailable for the manual visual pass.

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
