# M11-F03-T01 Mobile Chinese UI Copy

## Task ID

`M11-F03-T01`

## Title

Translate visible mobile UI copy and acceptance prompts into Chinese.

## Goal

Make the mobile app acceptance build readable for Chinese users by changing visible screen titles, buttons, empty states, status labels, tooltips, and first-release guidance copy from English to Chinese.

## Scope

This task only does:

- Add a focused mobile Chinese UI regression test.
- Translate visible mobile UI strings in Auth, bottom navigation, Library, Reader, Lookup, paragraph translation status, Vocabulary, Anki export, Stats, and Settings.
- Update existing widget tests so they assert Chinese user-facing copy.
- Preserve all routing, local-first storage, sync payload, auth token, import, lookup, translation, vocabulary, review, export, and stats behavior.

This task does not:

- Add a localization framework or ARB files.
- Add language switching or persisted settings.
- Change backend APIs, database schema, sync worker behavior, or payload fields.
- Translate book/chapter/user content that comes from imported files or API data.
- Modify mobile design layout beyond text length adjustments needed to avoid clipping.
- Modify web-reader, web-admin, server, infra, deployment docs, or old project paths.

## Allowed Files

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F03-T01-mobile-chinese-ui-copy.md`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/lib/src/features/auth/presentation/auth_form_shell.dart`
- `apps/mobile/lib/src/features/auth/presentation/sign_in_screen.dart`
- `apps/mobile/lib/src/features/auth/presentation/register_screen.dart`
- `apps/mobile/lib/src/features/library/presentation/library_screen.dart`
- `apps/mobile/lib/src/features/library/presentation/library_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_controller.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_bottom_sheet.dart`
- `apps/mobile/lib/src/features/study/presentation/paragraph_translation_controller.dart`
- `apps/mobile/lib/src/features/study/presentation/inline_paragraph_translation.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_controller.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_card_tile.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/anki_export_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/save_vocabulary_controller.dart`
- `apps/mobile/lib/src/features/settings/presentation/settings_screen.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_controller.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_screen.dart`
- `apps/mobile/test/src/app/app_router_test.dart`
- `apps/mobile/test/src/features/auth/*_test.dart`
- `apps/mobile/test/src/features/library/library_screen_test.dart`
- `apps/mobile/test/src/features/reader/*_test.dart`
- `apps/mobile/test/src/features/study/*_test.dart`
- `apps/mobile/test/src/features/vocabulary/*_test.dart`
- `apps/mobile/test/src/features/settings/settings_screen_test.dart`
- `apps/mobile/test/src/features/stats/*_test.dart`
- `apps/mobile/test/src/regression/mobile_chinese_ui_copy_regression_test.dart`
- `apps/mobile/test/src/regression/mobile_learning_loop_regression_test.dart`
- `apps/mobile/test/widget_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/auth/data/**`
- `apps/mobile/lib/src/features/library/data/**`
- `apps/mobile/lib/src/features/library/domain/**`
- `apps/mobile/lib/src/features/reader/data/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/vocabulary/data/**`
- `apps/mobile/lib/src/features/vocabulary/domain/**`
- `apps/mobile/lib/src/features/stats/data/**`
- `apps/mobile/lib/src/features/stats/domain/**`
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
- Current mobile presentation files listed in Allowed Files

## Tests First

Create:

- `apps/mobile/test/src/regression/mobile_chinese_ui_copy_regression_test.dart`

Test behavior:

- Signed-out app starts with Chinese sign-in copy and does not show `Sign In`.
- Signed-in bottom navigation shows `书库`, `词卡`, `统计`, `设置`.
- Empty Library shows Chinese import and local-offline copy, and does not show `Import TXT or EPUB`.
- Settings shows Chinese privacy/export/session guidance.
- Vocabulary empty state, Stats headings, and Reader fallback use Chinese copy.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/regression/mobile_chinese_ui_copy_regression_test.dart
```

Expected red result:

- Tests fail because current visible UI still contains English copy such as `Sign In`, `Library`, `Import TXT or EPUB`, `Settings`, `Vocabulary`, and `Stats`.

## Implementation Steps

- [ ] Step 1: Add the Chinese UI regression test.
- [ ] Step 2: Run the focused regression test and confirm the red failure is English copy.
- [ ] Step 3: Translate Auth and bottom navigation copy.
- [ ] Step 4: Translate Library, Reader, Lookup, and paragraph translation status copy.
- [ ] Step 5: Translate Vocabulary, Anki export, Stats, and Settings copy.
- [ ] Step 6: Update existing widget tests from English assertions to Chinese assertions.
- [ ] Step 7: Run the focused regression test and relevant widget tests.
- [ ] Step 8: Run full Flutter tests and analyze.
- [ ] Step 9: Commit and push the task card plus implementation.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/regression/mobile_chinese_ui_copy_regression_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- Main mobile screens and prompts are Chinese-first.
- No major visible English placeholders remain in Auth, navigation, Library, Reader, Lookup, Vocabulary, Anki export, Stats, or Settings.
- Dynamic imported book titles, chapter titles, lexeme text, definitions, and API error messages are not force-translated.
- No raw book content, chapter content, paragraph text, translated text, original paths, token, password, or secret is newly exposed.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Translation requires a real localization framework or persisted language switch.
- Implementation requires modifying files outside Allowed Files.
- Tests reveal a behavior change outside visible copy.
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
