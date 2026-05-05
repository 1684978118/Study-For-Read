# M8-F04-T02 Web Reader Basic Reader

## Task ID

`M8-F04-T02`

## Title

Implement basic web reader page.

## Goal

Open a browser-local book, display one chapter, navigate chapters, adjust font size and theme, and save browser-local reading position.

## Scope

This task only does:

- Add Reader store.
- Add Reader route page.
- Add reader text and controls components.
- Save local reading position and enqueue progress sync event.
- Add tests.

This task does not:

- Add lookup.
- Add paragraph translation.
- Add vocabulary save.
- Add sync worker execution.

## Allowed Files

- `apps/web-reader/pages/reader/[bookId].vue`
- `apps/web-reader/stores/reader.ts`
- `apps/web-reader/components/reader/ReaderText.vue`
- `apps/web-reader/components/reader/ReaderControls.vue`
- `apps/web-reader/components/reader/ReaderHeader.vue`
- `apps/web-reader/repositories/bookRepository.ts`
- `apps/web-reader/repositories/chapterRepository.ts`
- `apps/web-reader/repositories/readingPositionRepository.ts`
- `apps/web-reader/repositories/pendingSyncRepository.ts`
- `apps/web-reader/tests/reader/reader-store.test.ts`
- `apps/web-reader/tests/reader/reader-page.test.ts`

## Forbidden Files

- `apps/web-reader/components/study/**`
- `apps/web-reader/components/vocabulary/**`
- `apps/web-reader/services/studyApiClient.ts`
- `apps/web-reader/services/syncWorker.ts`
- `apps/web-reader/package.json`
- `apps/mobile/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`
- `docs/specs/UI_FLOWS.md`
- `apps/web-reader/repositories/bookRepository.ts`
- `apps/web-reader/repositories/chapterRepository.ts`
- `apps/web-reader/repositories/readingPositionRepository.ts`

## Tests First

Create:

- `apps/web-reader/tests/reader/reader-store.test.ts`
- `apps/web-reader/tests/reader/reader-page.test.ts`

Test behavior:

- Opening Reader with a valid local book id loads saved chapter index.
- Reader displays book title, chapter title, and chapter text.
- Next chapter updates visible chapter and saves progress.
- Previous chapter updates visible chapter and saves progress.
- Reader disables previous on first chapter and next on last chapter.
- Font size control changes text size within configured min and max.
- Missing local book id shows a not-found state.
- Progress sync event contains book fingerprint and position only, not chapter content.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/reader/reader-store.test.ts tests/reader/reader-page.test.ts
```

Expected red result:

- Tests fail because Reader store or page behavior does not exist.

## Implementation Steps

- [ ] Step 1: Write Reader store and page tests.
- [ ] Step 2: Run red tests and confirm missing Reader behavior.
- [ ] Step 3: Create Reader store that loads book, chapters, and position.
- [ ] Step 4: Create Reader header, text, and controls components.
- [ ] Step 5: Create route page `/reader/[bookId]`.
- [ ] Step 6: Implement previous and next chapter commands.
- [ ] Step 7: Save local reading position with `progressSyncStatus=dirty`.
- [ ] Step 8: Enqueue `reading_progress` sync event with position only.
- [ ] Step 9: Add not-found and empty-chapter states.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/reader/reader-store.test.ts tests/reader/reader-page.test.ts
npm run typecheck
```

## Acceptance Criteria

- Reader tests pass.
- Reader opens browser-local book by local book id.
- Reader displays local chapter text.
- Chapter navigation works.
- Reading position saves locally.
- Sync payload excludes chapter content.
- No lookup, translation, vocabulary, or live sync worker is added.

## Stop Conditions

- Library import task is incomplete.
- Chapter repository cannot load chapter by index.
- UI requires files outside Allowed Files.
- Any implementation sends chapter content to sync payload.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

