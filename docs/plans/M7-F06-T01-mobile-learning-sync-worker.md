# M7-F06-T01 Mobile Learning Sync Worker

## Task ID

`M7-F06-T01`

## Title

Implement mobile learning sync worker.

## Goal

Process pending sync events for book metadata, reading progress, word card creation, word card reviews, and daily stats.

## Scope

This task only does:

- Add reading sync API client if not already present.
- Add stats API client.
- Add sync worker for pending events.
- Add retry and failure status handling.
- Add tests with fake HTTP and fake repositories.

This task does not:

- Add background OS scheduling.
- Add push notifications.
- Add conflict UI.
- Upload original files, chapter content, paragraph text, or translation cache content.

## Allowed Files

- `apps/mobile/lib/src/features/reading_sync/data/reading_sync_api_client.dart`
- `apps/mobile/lib/src/features/stats/data/stats_api_client.dart`
- `apps/mobile/lib/src/features/sync/data/learning_sync_worker.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
- `apps/mobile/lib/src/features/reader/data/local_reading_position_repository.dart`
- `apps/mobile/lib/src/features/vocabulary/data/vocabulary_api_client.dart`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/test/src/features/reading_sync/reading_sync_api_client_test.dart`
- `apps/mobile/test/src/features/stats/stats_api_client_test.dart`
- `apps/mobile/test/src/features/sync/learning_sync_worker_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/sync/presentation/**`
- `apps/mobile/lib/src/features/study/data/local_translation_cache_repository.dart`
- `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/lib/src/features/vocabulary/data/vocabulary_api_client.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/reading_sync/reading_sync_api_client_test.dart`
- `apps/mobile/test/src/features/stats/stats_api_client_test.dart`
- `apps/mobile/test/src/features/sync/learning_sync_worker_test.dart`

Test behavior:

- Reading sync client upserts book metadata to `/api/v1/reading/books/{bookFingerprint}` without `originalFile`, `filePath`, or chapter content.
- Reading sync client updates progress to `/api/v1/reading/books/{bookFingerprint}/progress`.
- Stats API client posts incremental counters to `/api/v1/stats/daily`.
- Sync worker marks an event `done` after successful API call.
- Sync worker increments `attempt_count` and stores `last_error_code` after recoverable failure.
- Sync worker creates online lexeme cards and updates `server_card_id` on local card.
- Sync worker reviews server-backed cards through vocabulary API.
- Sync worker skips translation cache and local chapter content.
- Sync worker processes only current owner's pending events.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/reading_sync/reading_sync_api_client_test.dart test/src/features/stats/stats_api_client_test.dart test/src/features/sync/learning_sync_worker_test.dart
```

Expected red result:

- Tests fail because sync clients or worker do not exist.

## Implementation Steps

- [ ] Step 1: Write reading sync API client, stats API client, and sync worker tests.
- [ ] Step 2: Run red tests and confirm missing client or worker failures.
- [ ] Step 3: Create `ReadingSyncApiClient.upsertBookMetadata`.
- [ ] Step 4: Create `ReadingSyncApiClient.updateReadingProgress`.
- [ ] Step 5: Create `StatsApiClient.addDailyStats`.
- [ ] Step 6: Create `LearningSyncWorker.syncPendingEventsForCurrentUser`.
- [ ] Step 7: Implement `book_metadata` event handling using metadata only.
- [ ] Step 8: Implement `reading_progress` event handling using position only.
- [ ] Step 9: Implement `word_card_create` event handling for lexeme and private sentence cards.
- [ ] Step 10: Implement `word_card_review` event handling only when `server_card_id` exists; keep event pending otherwise.
- [ ] Step 11: Implement `daily_stats` event handling with incremental counters.
- [ ] Step 12: Mark success as `done`; mark recoverable failure as `failed` with incremented attempt count.
- [ ] Step 13: Ensure sync worker never reads `local_chapters.content` or `local_translation_cache.translated_text`.
- [ ] Step 14: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/reading_sync/reading_sync_api_client_test.dart test/src/features/stats/stats_api_client_test.dart test/src/features/sync/learning_sync_worker_test.dart
flutter analyze
```

## Acceptance Criteria

- Sync worker tests pass.
- Sync sends only metadata, progress, card state, review state, and counter data.
- Sync never sends original file path, full chapter text, paragraph text, or translated text.
- Failed events keep enough status for retry.
- Tests use fake HTTP and do not require a live backend.

## Stop Conditions

- Pending sync event repository is incomplete.
- Vocabulary API client is incomplete.
- Stats local repository is incomplete.
- Sync requires modifying auth token handling outside Allowed Files.
- Any implementation reads local chapter content or translation cache for sync.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

