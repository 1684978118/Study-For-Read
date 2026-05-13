# M11-F01-T01 Mobile Settings Acceptance Polish

## Task ID

`M11-F01-T01`

## Title

Polish the mobile Settings screen for acceptance testing.

## Goal

Make Settings look like a real first-release mobile settings page instead of a single Anki export link.

## Scope

This task only does:

- Add a focused Settings screen widget test.
- Show account/language, reading preference, sync/privacy status, Anki export, and sign-out sections.
- Keep the Anki export entry working.
- Keep sign out as a visible disabled first-release placeholder unless a real auth wiring task is added later.

This task does not:

- Persist settings.
- Add a settings controller.
- Add live backend calls.
- Implement actual sign-out token clearing.
- Add provider, quota, subscription, payment, or account deletion UI.
- Modify routing, auth storage, database, sync worker, or Anki export internals.

## Allowed Files

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F01-T01-mobile-settings-acceptance-polish.md`
- `apps/mobile/lib/src/features/settings/presentation/settings_screen.dart`
- `apps/mobile/test/src/features/settings/settings_screen_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/app/**`
- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/reader/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/vocabulary/**`, except the existing Anki export screen may still be imported.
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
- `apps/mobile/lib/src/features/settings/presentation/settings_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/settings/settings_screen_test.dart`

Test behavior:

- Settings shows the title, account/language section, reading preference section, sync/privacy section, Anki export entry, and sign-out placeholder.
- Settings keeps privacy copy explicit: local books stay on device and sync sends metadata only.
- Tapping Export to Anki opens the export screen.
- The sign-out placeholder is disabled and does not navigate.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/settings/settings_screen_test.dart
```

Expected red result:

- Tests fail because the current Settings screen only shows `Export to Anki`.

## Implementation Steps

- [ ] Step 1: Read the allowed Settings screen file and this task card.
- [ ] Step 2: Create the failing Settings widget test.
- [ ] Step 3: Run the focused test and confirm the failure is missing Settings acceptance content.
- [ ] Step 4: Update `SettingsScreen` with simple sectioned mobile layout.
- [ ] Step 5: Run the focused Settings test and confirm it passes.
- [ ] Step 6: Run full Flutter tests and analyze.
- [ ] Step 7: Commit and push the plan plus implementation.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/settings/settings_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- Settings is no longer a one-item page.
- The screen gives a first-release user enough orientation for language, reading preferences, sync/privacy, Anki export, and sign out.
- No raw book content, chapter content, paragraph text, translated text, paths, token, or secret is displayed.
- Anki export entry still opens `AnkiExportScreen`.
- Sign out is visible but clearly not wired in this task.

## Stop Conditions

- Implementation requires modifying files outside Allowed Files.
- A real sign-out flow requires auth/router changes.
- Settings persistence requires database or token-store changes.
- Tests fail for reasons unrelated to the current Settings acceptance gap.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Whether any Allowed Files boundary was crossed.
- Blockers.
- Recommended next task card.
