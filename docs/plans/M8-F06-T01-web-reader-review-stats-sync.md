# M8-F06-T01 Web Reader Review Stats Sync

## Task ID

`M8-F06-T01`

## Title

Implement web reader vocabulary review, stats page, and sync worker.

## Goal

Let web users review vocabulary cards offline, see simple stats, and sync metadata, progress, card changes, reviews, and daily counters.

## Scope

This task only does:

- Add Vocabulary page with Due, All, and Private Sentences tabs.
- Add review scheduler and review actions.
- Add Stats page with Today, Last 7 Days, and All Time summaries.
- Add reading sync API client and stats API client.
- Add sync worker for allowed pending event types.
- Add tests with fake HTTP and fake IndexedDB.

This task does not:

- Add background browser service worker scheduling.
- Add complex charts.
- Add admin screens.
- Upload original file, chapter content, paragraph text, or translated text.

## Allowed Files

- `apps/web-reader/pages/vocabulary.vue`
- `apps/web-reader/pages/stats.vue`
- `apps/web-reader/stores/vocabulary.ts`
- `apps/web-reader/stores/stats.ts`
- `apps/web-reader/services/reviewScheduler.ts`
- `apps/web-reader/services/readingSyncApiClient.ts`
- `apps/web-reader/services/statsApiClient.ts`
- `apps/web-reader/services/syncWorker.ts`
- `apps/web-reader/components/vocabulary/VocabularyCardTile.vue`
- `apps/web-reader/components/vocabulary/VocabularyTabs.vue`
- `apps/web-reader/components/stats/StatsSummary.vue`
- `apps/web-reader/repositories/bookRepository.ts`
- `apps/web-reader/repositories/readingPositionRepository.ts`
- `apps/web-reader/repositories/learningRepository.ts`
- `apps/web-reader/repositories/statsRepository.ts`
- `apps/web-reader/repositories/pendingSyncRepository.ts`
- `apps/web-reader/tests/vocabulary/vocabulary-review.test.ts`
- `apps/web-reader/tests/stats/stats-page.test.ts`
- `apps/web-reader/tests/sync/web-reader-sync-worker.test.ts`

## Forbidden Files

- `apps/web-reader/repositories/chapterRepository.ts`
- `apps/web-reader/repositories/translationCacheRepository.ts`
- `apps/web-reader/components/study/**`
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
- `apps/web-reader/repositories/learningRepository.ts`
- `apps/web-reader/repositories/statsRepository.ts`
- `apps/web-reader/repositories/pendingSyncRepository.ts`

## Tests First

Create:

- `apps/web-reader/tests/vocabulary/vocabulary-review.test.ts`
- `apps/web-reader/tests/stats/stats-page.test.ts`
- `apps/web-reader/tests/sync/web-reader-sync-worker.test.ts`

Test behavior:

- Vocabulary page has Due, All, and Private Sentences tabs.
- Unknown review schedules next review tomorrow.
- Known first review schedules next review in 3 days.
- Known repeated reviews schedule 7, 15, then 30 days.
- Review updates local state immediately and enqueues `word_card_review`.
- Review increments today's `cardsReviewed`.
- Stats page shows Reading minutes, Lookups, Paragraph translations, Cards created, and Cards reviewed.
- Sync worker sends book metadata without original file name or chapter content.
- Sync worker sends reading progress with position only.
- Sync worker sends card create and review events without private chapter context beyond allowed card fields.
- Sync worker sends daily stats through `/api/v1/stats/daily`.
- Sync worker never reads `web_chapters.content` or `web_translation_cache.translatedText`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/vocabulary/vocabulary-review.test.ts tests/stats/stats-page.test.ts tests/sync/web-reader-sync-worker.test.ts
```

Expected red result:

- Tests fail because review, stats, or sync worker behavior does not exist.

## Implementation Steps

- [ ] Step 1: Write vocabulary review, stats page, and sync worker tests.
- [ ] Step 2: Run red tests and confirm missing behavior.
- [ ] Step 3: Create review scheduler with PRD interval rules.
- [ ] Step 4: Add Vocabulary page tabs and card tiles.
- [ ] Step 5: Add review actions that update local card state and enqueue `word_card_review`.
- [ ] Step 6: Add Stats store and Stats page summaries.
- [ ] Step 7: Create reading sync API client for book metadata and progress.
- [ ] Step 8: Create stats API client for daily counters.
- [ ] Step 9: Create sync worker for `book_metadata`, `reading_progress`, `word_card_create`, `word_card_review`, and `daily_stats`.
- [ ] Step 10: Mark successful events `done`; mark recoverable failures `failed` with incremented attempt count.
- [ ] Step 11: Ensure sync worker never reads chapter content or translated text stores.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/vocabulary/vocabulary-review.test.ts tests/stats/stats-page.test.ts tests/sync/web-reader-sync-worker.test.ts
npm run typecheck
```

## Acceptance Criteria

- Review, stats, and sync tests pass.
- Review works from browser-local data.
- Stats page works from browser-local data.
- Sync sends only metadata, progress, card state, review state, and counter data.
- Sync never sends original file, chapter content, paragraph text, or translated text.

## Stop Conditions

- Study vocabulary flow is incomplete.
- Pending sync repository is incomplete.
- Sync requires reading chapter or translation cache content.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

