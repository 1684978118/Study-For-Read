# M7-F04-T03 Mobile Anki Export

## Task ID

`M7-F04-T03`

## Title

Add local Anki-compatible vocabulary export.

## Goal

Allow the user to export vocabulary cards to an Anki-compatible UTF-8 text file without uploading original books, chapters, or private source text to the backend.

## Scope

This task only does:

- Add a local Anki export service for vocabulary cards.
- Add export entry from Vocabulary or Settings.
- Generate a UTF-8 `.txt` file using Tab-separated fields.
- Add Anki file headers.
- Allow export options for all cards, due cards, or private sentence cards.
- Allow optional inclusion of examples and source metadata.

This task does not:

- Implement AnkiWeb login.
- Implement automatic Anki sync.
- Generate real audio files.
- Upload exported files to the backend.
- Export original book files or full chapters.
- Show a raw file-format preview in the app UI.

## Allowed Files

This task may create or modify only:

- `apps/mobile/lib/src/features/vocabulary/export/anki_export_service.dart`
- `apps/mobile/lib/src/features/vocabulary/export/anki_export_options.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/anki_export_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/settings/presentation/settings_screen.dart`
- `apps/mobile/test/src/features/vocabulary/anki_export_service_test.dart`
- `apps/mobile/test/src/features/vocabulary/anki_export_screen_test.dart`

## Forbidden Files

This task must not modify:

- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- `docs/specs/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `docs/plans/M7_MOBILE_LEARNING_LOOP.md`

## Tests First

Create or modify:

- `apps/mobile/test/src/features/vocabulary/anki_export_service_test.dart`
- `apps/mobile/test/src/features/vocabulary/anki_export_screen_test.dart`

Tests must cover:

- Export text starts with Anki headers.
- Export text uses Tab-separated fields.
- Export text is generated from local vocabulary data only.
- First field is stable card id.
- Optional example and source fields can be included or omitted.
- Audio field can contain `[sound:filename]` when local audio metadata exists.
- UI does not show raw file preview.

Run:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/anki_export_service_test.dart test/src/features/vocabulary/anki_export_screen_test.dart
```

Expected result:

- Tests fail because Anki export service and UI do not exist yet.

## Implementation Steps

- [ ] Step 1: Read all `Read First` files.
- [ ] Step 2: Write failing export service tests.
- [ ] Step 3: Write failing export screen tests.
- [ ] Step 4: Implement `AnkiExportOptions`.
- [ ] Step 5: Implement `AnkiExportService` with UTF-8 text content and Tab-separated fields.
- [ ] Step 6: Add file headers: `#separator:Tab`, `#html:true`, `#deck`, `#notetype`, and `#columns`.
- [ ] Step 7: Escape tabs and newlines inside fields so rows remain importable.
- [ ] Step 8: Add Vocabulary or Settings export entry.
- [ ] Step 9: Add export screen options and completion state without raw file preview.
- [ ] Step 10: Run verification commands.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/anki_export_service_test.dart test/src/features/vocabulary/anki_export_screen_test.dart
```

## Acceptance Criteria

- Anki export tests pass.
- Export output is UTF-8 `.txt` content.
- Export output uses Tab-separated fields.
- Export output contains Anki file headers.
- Export output first field is stable card id.
- Export UI offers options and completion state.
- Export UI does not show raw file preview.
- No export payload is uploaded to backend.
- No original book file or full chapter content is exported.

## Stop Conditions

- Implementing file sharing requires modifying files outside Allowed Files.
- Vocabulary local card model does not expose required fields.
- Export requires original chapter content.
- Any task attempts AnkiWeb login or automatic sync.
- Any command would delete files or directories.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

