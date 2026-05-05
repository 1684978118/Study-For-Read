# M7-F04-T02 Mobile Review Scheduler

## Task ID

`M7-F04-T02`

## Title

Implement offline vocabulary review scheduler.

## Goal

Allow users to review due cards offline, update local spaced repetition state, enqueue sync, and increment review stats.

## Scope

This task only does:

- Add review scheduler logic.
- Add review controller.
- Add Known and Unknown actions to Vocabulary screen card detail or inline row.
- Add pending `word_card_review` sync events.
- Increment `cards_reviewed` stats.

This task does not:

- Add advanced spaced repetition algorithms.
- Add server sync execution.
- Add card editing.
- Add new vocabulary creation.

## Allowed Files

- `apps/mobile/lib/src/features/vocabulary/domain/review_result.dart`
- `apps/mobile/lib/src/features/vocabulary/domain/review_scheduler.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/review_controller.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_card_tile.dart`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/test/src/features/vocabulary/review_scheduler_test.dart`
- `apps/mobile/test/src/features/vocabulary/review_controller_test.dart`
- `apps/mobile/test/src/features/vocabulary/vocabulary_review_screen_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/vocabulary/data/vocabulary_api_client.dart`
- `apps/mobile/lib/src/features/sync/data/sync_worker.dart`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/reader/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/vocabulary/review_scheduler_test.dart`
- `apps/mobile/test/src/features/vocabulary/review_controller_test.dart`
- `apps/mobile/test/src/features/vocabulary/vocabulary_review_screen_test.dart`

Test behavior:

- Unknown review schedules next review tomorrow.
- Known first review schedules next review in 3 days.
- Known repeated reviews schedule 7, 15, then 30 days.
- Review increments `review_count` and sets `last_reviewed_at`.
- Review updates local card immediately without network.
- Review enqueues `word_card_review` pending sync event.
- Review increments today's `cards_reviewed`.
- User cannot review another owner's local card through controller.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/review_scheduler_test.dart test/src/features/vocabulary/review_controller_test.dart test/src/features/vocabulary/vocabulary_review_screen_test.dart
```

Expected red result:

- Tests fail because review scheduler or review controller does not exist.

## Implementation Steps

- [ ] Step 1: Write scheduler, controller, and review screen tests.
- [ ] Step 2: Run red tests and confirm missing review behavior.
- [ ] Step 3: Create `ReviewScheduler` with PRD interval rules.
- [ ] Step 4: Create `ReviewResult` containing new status, review count, next review time, and reviewed time.
- [ ] Step 5: Create `ReviewController.reviewCard`.
- [ ] Step 6: Update local word card review state immediately.
- [ ] Step 7: Enqueue `word_card_review` event with card id, known flag, reviewed time, and local state fields only.
- [ ] Step 8: Increment local `cards_reviewed`.
- [ ] Step 9: Add Known and Unknown actions in Vocabulary UI.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/review_scheduler_test.dart test/src/features/vocabulary/review_controller_test.dart test/src/features/vocabulary/vocabulary_review_screen_test.dart
flutter analyze
```

## Acceptance Criteria

- Review tests pass.
- Review works offline.
- Review interval rules match PRD.
- Pending review sync event contains no raw book or chapter content.
- Cards-reviewed stats increment locally.
- No sync worker execution is added in this task.

## Stop Conditions

- Vocabulary screen task is incomplete.
- Local word card repository cannot update owner-scoped cards.
- Review behavior requires changing backend API client.
- Any implementation reviews another user's card.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
