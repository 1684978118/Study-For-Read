# M7-F01-T01 Mobile Learning Local Data

## Task ID

`M7-F01-T01`

## Title

Extend mobile SQLite for learning data.

## Goal

Add local persistence for lexeme cache, user word cards, translation cache, and daily stats.

## Scope

This task only does:

- Add mobile database migration for learning tables.
- Add domain models and repositories for learning data.
- Extend pending sync event validation for vocabulary and stats event types.
- Add SQLite repository tests.

This task does not:

- Add API clients.
- Add Reader UI changes.
- Add Vocabulary UI.
- Add sync worker.

## Allowed Files

- `apps/mobile/lib/src/core/database/mobile_database.dart`
- `apps/mobile/lib/src/core/database/mobile_database_migrations.dart`
- `apps/mobile/lib/src/features/study/domain/local_lexeme.dart`
- `apps/mobile/lib/src/features/study/domain/local_translation_cache_entry.dart`
- `apps/mobile/lib/src/features/study/data/local_lexeme_repository.dart`
- `apps/mobile/lib/src/features/study/data/local_translation_cache_repository.dart`
- `apps/mobile/lib/src/features/vocabulary/domain/local_word_card.dart`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/stats/domain/local_study_daily_stat.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/lib/src/features/sync/domain/pending_sync_event.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/test/src/features/study/local_lexeme_repository_test.dart`
- `apps/mobile/test/src/features/study/local_translation_cache_repository_test.dart`
- `apps/mobile/test/src/features/vocabulary/local_word_card_repository_test.dart`
- `apps/mobile/test/src/features/stats/local_study_stats_repository_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/study/presentation/**`
- `apps/mobile/lib/src/features/vocabulary/presentation/**`
- `apps/mobile/lib/src/features/reader/presentation/**`
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
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `docs/specs/API_CONTRACT.md`
- `apps/mobile/lib/src/core/database/mobile_database.dart`
- `apps/mobile/lib/src/core/database/mobile_database_migrations.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/study/local_lexeme_repository_test.dart`
- `apps/mobile/test/src/features/study/local_translation_cache_repository_test.dart`
- `apps/mobile/test/src/features/vocabulary/local_word_card_repository_test.dart`
- `apps/mobile/test/src/features/stats/local_study_stats_repository_test.dart`

Test behavior:

- `local_lexeme_cache` upserts public lexeme snapshots and stores no review fields.
- `local_word_cards` enforces `lexeme_id` for `card_type=lexeme`.
- `local_word_cards` enforces `private_surface` and `private_definition` for `card_type=private_sentence`.
- Duplicate owner and lexeme id is rejected.
- `local_translation_cache` stores translated text locally but pending sync validation rejects translation cache fields.
- `local_study_daily_stats` increments non-negative counters per owner and date.
- Pending sync events allow `word_card_create`, `word_card_review`, and `daily_stats`.
- Pending sync payload validation rejects raw content and translation cache fields.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/local_lexeme_repository_test.dart test/src/features/study/local_translation_cache_repository_test.dart test/src/features/vocabulary/local_word_card_repository_test.dart test/src/features/stats/local_study_stats_repository_test.dart
```

Expected red result:

- Tests fail because learning repositories or migration do not exist.

## Implementation Steps

- [ ] Step 1: Write learning local data repository tests.
- [ ] Step 2: Run red tests and confirm missing table or class failures.
- [ ] Step 3: Add migration version 2 with `local_lexeme_cache`, `local_word_cards`, `local_translation_cache`, and `local_study_daily_stats`.
- [ ] Step 4: Keep chapter content only in `local_chapters`; do not add chapter content to sync tables.
- [ ] Step 5: Create domain models matching `MOBILE_LOCAL_DATA.md`.
- [ ] Step 6: Create `LocalLexemeRepository` with upsert and lookup by id.
- [ ] Step 7: Create `LocalWordCardRepository` with upsert, list due, list all, list private sentence cards, and update review state.
- [ ] Step 8: Create `LocalTranslationCacheRepository` with lookup by owner, language pair, and source text hash.
- [ ] Step 9: Create `LocalStudyStatsRepository` with increment and summary methods.
- [ ] Step 10: Extend pending sync event type validation for word card and daily stats events.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/local_lexeme_repository_test.dart test/src/features/study/local_translation_cache_repository_test.dart test/src/features/vocabulary/local_word_card_repository_test.dart test/src/features/stats/local_study_stats_repository_test.dart
flutter analyze
```

## Acceptance Criteria

- Learning local data tests pass.
- Schema matches `MOBILE_LOCAL_DATA.md`.
- Public lexeme cache and private word-card state remain separate.
- Translation cache is local-only.
- Pending sync payload validation rejects raw content.
- No UI or API client is created in this task.

## Stop Conditions

- M6 local database task is incomplete.
- Schema requires changing `MOBILE_LOCAL_DATA.md`.
- Any file outside Allowed Files must be modified.
- Any implementation stores tokens or raw sync content in SQLite tables where forbidden.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

