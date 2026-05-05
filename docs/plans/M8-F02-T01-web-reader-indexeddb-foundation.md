# M8-F02-T01 Web Reader IndexedDB Foundation

## Task ID

`M8-F02-T01`

## Title

Create web reader IndexedDB foundation.

## Goal

Add browser-local Dexie stores and repository functions for books, chapters, reading positions, learning cache, stats, and pending sync events.

## Scope

This task only does:

- Add Dexie database schema.
- Add domain types for web-local data.
- Add repositories needed by import, reader, vocabulary, stats, and sync tasks.
- Add tests with fake IndexedDB.

This task does not:

- Add parser logic.
- Add UI.
- Add API clients.
- Add sync worker execution.

## Allowed Files

- `apps/web-reader/db/webReaderDb.ts`
- `apps/web-reader/db/webReaderSchema.ts`
- `apps/web-reader/types/localData.ts`
- `apps/web-reader/repositories/bookRepository.ts`
- `apps/web-reader/repositories/chapterRepository.ts`
- `apps/web-reader/repositories/readingPositionRepository.ts`
- `apps/web-reader/repositories/learningRepository.ts`
- `apps/web-reader/repositories/statsRepository.ts`
- `apps/web-reader/repositories/pendingSyncRepository.ts`
- `apps/web-reader/tests/db/web-reader-db.test.ts`
- `apps/web-reader/tests/repositories/book-repository.test.ts`
- `apps/web-reader/tests/repositories/learning-repository.test.ts`
- `apps/web-reader/tests/repositories/pending-sync-repository.test.ts`

## Forbidden Files

- `apps/web-reader/pages/**`
- `apps/web-reader/components/**`
- `apps/web-reader/parsers/**`
- `apps/web-reader/stores/**`
- `apps/web-reader/package.json`
- `apps/mobile/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`
- `docs/specs/API_CONTRACT.md`
- `apps/web-reader/package.json`

## Tests First

Create:

- `apps/web-reader/tests/db/web-reader-db.test.ts`
- `apps/web-reader/tests/repositories/book-repository.test.ts`
- `apps/web-reader/tests/repositories/learning-repository.test.ts`
- `apps/web-reader/tests/repositories/pending-sync-repository.test.ts`

Test behavior:

- Dexie schema includes `web_books`, `web_chapters`, `web_reading_positions`, `web_lexeme_cache`, `web_word_cards`, `web_translation_cache`, `web_study_daily_stats`, and `web_pending_sync_events`.
- Book repository enforces owner and fingerprint uniqueness at repository boundary.
- Chapter repository stores content locally and never exposes chapters through pending sync repository.
- Reading position fields reject negative values.
- Learning repository keeps public lexeme cache separate from private sentence cards.
- Stats repository increments non-negative counters by owner and date.
- Pending sync repository accepts only allowed event types.
- Pending sync payload validation rejects raw content and translation cache fields.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/db tests/repositories
```

Expected red result:

- Tests fail because Dexie database and repositories do not exist.

## Implementation Steps

- [ ] Step 1: Write Dexie schema and repository tests.
- [ ] Step 2: Run red tests and confirm missing module failures.
- [ ] Step 3: Create `localData.ts` types matching `WEB_READER_LOCAL_DATA.md`.
- [ ] Step 4: Create `webReaderSchema.ts` with deterministic schema version 1.
- [ ] Step 5: Create `webReaderDb.ts` using Dexie.
- [ ] Step 6: Create book, chapter, reading position, learning, stats, and pending sync repositories.
- [ ] Step 7: Add repository validation for non-negative counters and positions.
- [ ] Step 8: Add pending sync payload forbidden-field validation.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/db tests/repositories
npm run typecheck
```

## Acceptance Criteria

- IndexedDB tests pass.
- Schema matches `WEB_READER_LOCAL_DATA.md`.
- Sync payload validation rejects raw content fields.
- No UI, parser, or API client is added.

## Stop Conditions

- Dexie dependency is missing.
- Fake IndexedDB test setup is unavailable and requires package changes outside Allowed Files.
- Schema requires changing `WEB_READER_LOCAL_DATA.md`.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

