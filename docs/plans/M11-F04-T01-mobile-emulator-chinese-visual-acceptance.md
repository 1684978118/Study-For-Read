# M11-F04-T01 Mobile Emulator Chinese Visual Acceptance

## Task ID

`M11-F04-T01`

## Title

Run Android emulator visual acceptance for Chinese mobile UI.

## Goal

Validate the Chinese mobile UI on an Android emulator and fix only concrete acceptance issues that are visible on a phone viewport.

## Scope

This task only does:

- Start or connect to an Android emulator.
- Install/run the current mobile debug build.
- Capture screenshots for Auth, Library, Reader, Vocabulary, Stats, Settings, and any visible learning sheet/panel that can be reached locally.
- Fix Chinese text clipping, unreadable spacing, missing exits, dead-end navigation, or obvious debug-like presentation found during this pass.
- Add or update focused widget tests before any production UI fix.

This task does not:

- Add backend APIs, live backend dependencies, cloud storage, or new sync behavior.
- Change auth token storage, database schema, import parsing, sync payloads, or API clients.
- Translate imported book/chapter/user/API content.
- Create production screenshots in tracked source files.
- Modify server, web-reader, web-admin, infra, deployment, or old project paths.

## Allowed Files

Always allowed:

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F04-T01-mobile-emulator-chinese-visual-acceptance.md`

Allowed only if a concrete visual issue is found and covered by a failing test first:

- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/lib/src/app/study_for_read_app.dart`
- `apps/mobile/lib/src/features/auth/presentation/auth_form_shell.dart`
- `apps/mobile/lib/src/features/auth/presentation/sign_in_screen.dart`
- `apps/mobile/lib/src/features/auth/presentation/register_screen.dart`
- `apps/mobile/lib/src/features/library/presentation/library_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_bottom_sheet.dart`
- `apps/mobile/lib/src/features/study/presentation/inline_paragraph_translation.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_card_tile.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/anki_export_screen.dart`
- `apps/mobile/lib/src/features/settings/presentation/settings_screen.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_screen.dart`
- Matching focused tests under `apps/mobile/test/src/**`
- `apps/mobile/test/widget_test.dart`

Local untracked acceptance artifacts:

- `artifacts/m11-f04-mobile-emulator-acceptance/**`

## Forbidden Files

- `apps/mobile/lib/src/features/**/data/**`
- `apps/mobile/lib/src/features/**/domain/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F03-T01-mobile-chinese-ui-copy.md`

## Tests First

If no production UI issue is found:

- No new production test is required.
- Record the emulator blocker or screenshot result in the completion report.

If a production UI issue is found:

- Add a focused widget test in the nearest existing test file.
- Run that focused test before implementation.
- Expected red result must identify the visible acceptance problem, such as overflow, missing label, inaccessible control, or wrong copy.

## Implementation Steps

- [x] Step 1: Create this task card and add it to the M11 task order.
- [x] Step 2: Confirm current git status and leave existing untracked `artifacts/` alone.
- [x] Step 3: Locate Flutter/Android emulator tooling.
- [x] Step 4: Start an Android emulator if none is connected.
- [x] Step 5: Install or run the debug mobile app on the emulator.
- [x] Step 6: Capture screenshots into `artifacts/m11-f04-mobile-emulator-acceptance/`.
- [x] Step 7: Inspect Chinese UI screens for clipping, dead ends, overlap, unreadable spacing, or debug placeholders.
- [x] Step 8: If a concrete issue is found, write the failing focused widget test.
- [x] Step 9: Implement the smallest UI-only fix.
- [x] Step 10: Run the focused test, full Flutter test suite, and analyze.
- [ ] Step 11: Commit and push only tracked task-card and code/test files. Do not commit screenshots unless explicitly requested.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat devices
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

If an emulator is available:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat run -d <emulator-id>
```

## Acceptance Criteria

- Emulator status is recorded.
- Screenshots are captured when emulator access works.
- Chinese Auth, Library, Reader, Vocabulary, Stats, and Settings screens are visually checked.
- Any concrete visual issue fixed in this task has a focused failing test first.
- No raw book content, chapter content, paragraph text, translated text, original path, token, password, or secret is newly exposed.
- Full Flutter tests and analyze pass if production or test code changes are made.

## Stop Conditions

- No Android emulator can be started or connected in this environment.
- A fix requires files outside Allowed Files.
- A requested action would bulk-delete files or directories.
- A visual issue depends on backend/live account state not available in local acceptance.

## Completion Report Format

Reply with:

- Modified files.
- Emulator/device status.
- Screenshot artifact paths, if captured.
- Visual findings.
- Red test result, if any production issue was fixed.
- Verification commands.
- Verification results.
- Whether any Allowed Files boundary was crossed.
- Blockers.
- Recommended next task card.
