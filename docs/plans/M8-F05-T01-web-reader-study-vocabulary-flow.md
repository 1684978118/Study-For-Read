# M8-F05-T01 Web Reader Study Vocabulary Flow

## Task ID

`M8-F05-T01`

## Title

Implement web reader lookup, paragraph translation, and save vocabulary flow.

## Goal

Let web users look up selected text, translate one paragraph, save lexeme cards, and save private sentence cards while keeping chapter content browser-local.

## Scope

This task only does:

- Add study API client.
- Add vocabulary API client.
- Add lookup popover.
- Add paragraph translation panel.
- Add local lexeme cache, word card, translation cache, and stats updates.
- Add tests with fake HTTP.

This task does not:

- Add review screen.
- Add sync worker execution.
- Add full-book translation.
- Add server-side book upload.

## Allowed Files

- `apps/web-reader/services/studyApiClient.ts`
- `apps/web-reader/services/vocabularyApiClient.ts`
- `apps/web-reader/stores/study.ts`
- `apps/web-reader/stores/vocabulary.ts`
- `apps/web-reader/components/study/LookupPopover.vue`
- `apps/web-reader/components/study/ParagraphTranslationPanel.vue`
- `apps/web-reader/components/reader/ReaderText.vue`
- `apps/web-reader/pages/reader/[bookId].vue`
- `apps/web-reader/repositories/learningRepository.ts`
- `apps/web-reader/repositories/statsRepository.ts`
- `apps/web-reader/repositories/pendingSyncRepository.ts`
- `apps/web-reader/tests/study/study-api-client.test.ts`
- `apps/web-reader/tests/study/reader-study-flow.test.ts`
- `apps/web-reader/tests/vocabulary/save-vocabulary-flow.test.ts`

## Forbidden Files

- `apps/web-reader/components/vocabulary/VocabularyReview*.vue`
- `apps/web-reader/services/syncWorker.ts`
- `apps/web-reader/pages/vocabulary.vue`
- `apps/web-reader/package.json`
- `apps/mobile/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`
- `apps/web-reader/pages/reader/[bookId].vue`
- `apps/web-reader/repositories/learningRepository.ts`
- `apps/web-reader/repositories/statsRepository.ts`

## Tests First

Create:

- `apps/web-reader/tests/study/study-api-client.test.ts`
- `apps/web-reader/tests/study/reader-study-flow.test.ts`
- `apps/web-reader/tests/vocabulary/save-vocabulary-flow.test.ts`

Test behavior:

- Lookup sends `POST /api/v1/study/lookup` with selected text and optional paragraph context.
- Paragraph translation sends `POST /api/v1/study/translate-paragraph` with one string paragraph only.
- Successful lookup caches public lexeme and increments lookup count.
- Successful paragraph translation caches translation locally and increments paragraph translation count.
- Saving a public lexeme creates or syncs a lexeme card.
- Saving a translated paragraph creates a private sentence card, not a public lexeme.
- Pending card sync payload excludes chapter content, paragraph text, original file name, and translated text.
- Full chapter and full book translation controls are absent.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/study tests/vocabulary/save-vocabulary-flow.test.ts
```

Expected red result:

- Tests fail because study client, study store, or save vocabulary flow does not exist.

## Implementation Steps

- [ ] Step 1: Write study API, reader study flow, and save vocabulary tests.
- [ ] Step 2: Run red tests and confirm missing study behavior.
- [ ] Step 3: Create study and vocabulary API clients matching `API_CONTRACT.md`.
- [ ] Step 4: Create study store for lookup and paragraph translation states.
- [ ] Step 5: Create vocabulary store save actions for public lexeme and private sentence cards.
- [ ] Step 6: Add lookup popover to Reader selected text interaction.
- [ ] Step 7: Add paragraph translation panel for one selected paragraph.
- [ ] Step 8: Cache lexeme and translation results locally.
- [ ] Step 9: Increment local stats for lookup, translation, and created cards.
- [ ] Step 10: Enqueue `word_card_create` when offline or when API create fails recoverably.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/study tests/vocabulary/save-vocabulary-flow.test.ts
npm run typecheck
```

## Acceptance Criteria

- Study and save vocabulary tests pass.
- Lookup and paragraph translation use backend APIs with selected text only.
- Translation cache stays browser-local.
- Private sentences do not become public lexemes.
- No sync payload includes raw chapter or paragraph content.
- No review UI is created in this task.

## Stop Conditions

- Basic Reader task is incomplete.
- IndexedDB learning repository is incomplete.
- Tests require live backend.
- Any implementation sends full chapters or full books.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

