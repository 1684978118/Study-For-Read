# M8-F07-T01 Web Reader Privacy Regression

## Task ID

`M8-F07-T01`

## Title

Add web reader privacy and local-first regression tests.

## Goal

Protect the complete Web Reader boundary: browser-local books remain local, and sync payloads never contain original content or translation cache content.

## Scope

This task only does:

- Add regression tests across import, reader, lookup, translation, vocabulary save, review, stats, and sync.
- Fix only privacy or local-first boundary failures found by those tests.

This task does not:

- Add new product features.
- Add live backend integration.
- Add mobile, admin, backend, or infra code.

## Allowed Files

- `apps/web-reader/tests/regression/web-reader-privacy-regression.test.ts`
- If and only if tests expose a boundary failure, these files may be modified:
  - `apps/web-reader/services/bookImportService.ts`
  - `apps/web-reader/services/syncWorker.ts`
  - `apps/web-reader/services/studyApiClient.ts`
  - `apps/web-reader/services/vocabularyApiClient.ts`
  - `apps/web-reader/stores/reader.ts`
  - `apps/web-reader/stores/study.ts`
  - `apps/web-reader/stores/vocabulary.ts`
  - `apps/web-reader/stores/stats.ts`
  - `apps/web-reader/repositories/bookRepository.ts`
  - `apps/web-reader/repositories/readingPositionRepository.ts`
  - `apps/web-reader/repositories/learningRepository.ts`
  - `apps/web-reader/repositories/statsRepository.ts`
  - `apps/web-reader/repositories/pendingSyncRepository.ts`

## Forbidden Files

- `apps/web-reader/package.json`
- `apps/web-reader/repositories/chapterRepository.ts`
- `apps/web-reader/parsers/**`
- `apps/mobile/**`
- `apps/web-admin/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`
- All M8 web reader task cards.

## Tests First

Create:

- `apps/web-reader/tests/regression/web-reader-privacy-regression.test.ts`

Test behavior:

- A signed-in test user imports a local TXT fixture in browser tests and sees it in Library.
- Reader opens the imported book from IndexedDB and saves local progress.
- Lookup sends only selected text, not full chapter text.
- Paragraph translation sends only one selected paragraph, not an array and not a full chapter.
- Saving lookup result creates a lexeme card.
- Saving translated paragraph creates a private sentence card, not a public lexeme.
- Reviewing a card updates local state and pending sync event.
- Stats counters update locally.
- Sync worker payloads contain no original file name, file bytes, chapter content, full paragraph text, or translated text.
- Test uses fake HTTP and fake IndexedDB, not a live backend.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/regression/web-reader-privacy-regression.test.ts
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual privacy or local-first boundary gap.

## Implementation Steps

- [ ] Step 1: Write web reader privacy regression test.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to privacy or local-first leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M8 web reader tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/regression/web-reader-privacy-regression.test.ts
npm run test
npm run typecheck
```

## Acceptance Criteria

- Privacy regression test passes.
- All web reader tests pass.
- Imported books and parsed chapters remain browser-local.
- Lookup, translation, vocabulary, review, stats, and sync work together with fake HTTP.
- Sync payloads never contain original file content, chapter content, paragraph text, or translated text.
- No mobile, admin, backend, infra, or old project files are modified.

## Stop Conditions

- Any prior M8 task is incomplete.
- Failure requires changing parser or schema files outside Allowed Files.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

