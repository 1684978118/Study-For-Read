# M7-F02-T03 Mobile Paragraph Translation Flow

## Task ID

`M7-F02-T03`

## Title

Add reader paragraph translation flow.

## Goal

Allow the user to translate one paragraph by tapping the subtle paragraph-end `+`, insert the translation below the original paragraph, and cache it locally without uploading chapters or full books.

## Scope

This task only does:

- Add subtle paragraph-end `+` translation hotspot in Reader.
- Add paragraph translation controller.
- Add inline translated paragraph UI states.
- Add local translation cache read/write.
- Increment paragraph translation stats locally.

This task does not:

- Add save private sentence card behavior.
- Add full-book translation.
- Add offline translation provider.
- Add paragraph action menu.
- Add translated-paragraph copy/save/collapse buttons.
- Add backend sync worker.

## Allowed Files

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/study/presentation/inline_paragraph_translation.dart`
- `apps/mobile/lib/src/features/study/presentation/paragraph_translation_controller.dart`
- `apps/mobile/lib/src/features/study/domain/paragraph_selection.dart`
- `apps/mobile/lib/src/features/study/data/study_api_client.dart`
- `apps/mobile/lib/src/features/study/data/local_translation_cache_repository.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/test/src/features/study/paragraph_translation_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/study/presentation/lookup_bottom_sheet.dart`
- `apps/mobile/lib/src/features/study/presentation/paragraph_translation_sheet.dart`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/study/data/study_api_client.dart`
- `apps/mobile/lib/src/features/study/data/local_translation_cache_repository.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/study/paragraph_translation_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_paragraph_translation_test.dart`

Test behavior:

- Controller translates exactly one selected paragraph.
- Cached translation is returned without a second API call for the same owner, language pair, and source text hash.
- Successful online translation writes `local_translation_cache`.
- Successful online translation increments today's `paragraph_translation_count`.
- Offline with cached result shows cached translation.
- Offline without cached result shows offline unavailable state.
- Translation request does not include full chapter text or arrays of paragraphs.
- Reader shows a very subtle `+` after each paragraph.
- Tapping the `+` calls translation directly without showing a menu.
- Translated paragraph is inserted directly below the original paragraph.
- No copy, save, or collapse buttons are shown under translated paragraphs.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/paragraph_translation_controller_test.dart test/src/features/reader/reader_paragraph_translation_test.dart
```

Expected red result:

- Tests fail because paragraph translation controller or inline Reader behavior does not exist.

## Implementation Steps

- [ ] Step 1: Write paragraph translation controller and Reader widget tests.
- [ ] Step 2: Run red tests and confirm missing controller or UI failures.
- [ ] Step 3: Create `ParagraphSelection` with selected paragraph text and optional location metadata.
- [ ] Step 4: Create `ParagraphTranslationController` with loading, cached, success, offline, and error states.
- [ ] Step 5: Hash selected paragraph locally before cache lookup.
- [ ] Step 6: Call `StudyApiClient.translateParagraph` only when no cache exists and network is available.
- [ ] Step 7: Store successful result in `LocalTranslationCacheRepository`.
- [ ] Step 8: Increment local `paragraph_translation_count` on successful online translation.
- [ ] Step 9: Create inline translated paragraph UI matching `MOBILE_UI_STYLE.md`.
- [ ] Step 10: Wire Reader paragraph-end `+` hotspot to call translation directly.
- [ ] Step 11: Keep the `+` symbol unchanged in default, loading, success, cached, offline, and error states.
- [ ] Step 12: Ensure no paragraph menu or translated-paragraph action buttons are rendered.
- [ ] Step 13: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/paragraph_translation_controller_test.dart test/src/features/reader/reader_paragraph_translation_test.dart
flutter analyze
```

## Acceptance Criteria

- Paragraph translation tests pass.
- Only one selected paragraph is sent to the backend.
- Cached translations are local-only.
- Translation stats increment locally.
- Translation is shown inline under the original paragraph.
- The paragraph-end `+` remains visually subtle and stays `+` in every state.
- No private sentence card creation happens in this task.
- No sync payload includes translated text.

## Stop Conditions

- Study API client is incomplete.
- Translation cache repository is incomplete.
- Reader text widget cannot expose paragraph selection without modifying files outside Allowed Files.
- Any implementation sends full chapters, full books, or arrays of paragraphs.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
