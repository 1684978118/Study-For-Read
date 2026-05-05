# M7-F05-T01 Mobile Stats Tracker Screen

## Task ID

`M7-F05-T01`

## Title

Implement mobile stats tracker and screen.

## Goal

Track local learning counters and show today, last 7 days, and all-time summaries.

## Scope

This task only does:

- Add stats tracker helper for reading minutes and learning event counters.
- Add Stats screen controller.
- Update Stats screen with simple summaries.
- Add tests for aggregation and display.

This task does not:

- Add complex charts.
- Add heatmap.
- Add server sync execution.
- Add admin stats.

## Allowed Files

- `apps/mobile/lib/src/features/stats/domain/study_stats_summary.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/lib/src/features/stats/data/study_stats_tracker.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_controller.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/test/src/features/stats/study_stats_tracker_test.dart`
- `apps/mobile/test/src/features/stats/stats_controller_test.dart`
- `apps/mobile/test/src/features/stats/stats_screen_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/study/**`
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
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/lib/src/features/stats/presentation/stats_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/stats/study_stats_tracker_test.dart`
- `apps/mobile/test/src/features/stats/stats_controller_test.dart`
- `apps/mobile/test/src/features/stats/stats_screen_test.dart`

Test behavior:

- Stats tracker increments reading minutes for the current local date.
- Stats tracker ignores negative or zero elapsed reading sessions.
- Controller returns today summary.
- Controller returns last 7 days summary.
- Controller returns all-time summary.
- Stats screen shows Reading minutes, Lookups, Paragraph translations, Cards created, and Cards reviewed.
- Stats screen uses local data only and does not require network.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/stats/study_stats_tracker_test.dart test/src/features/stats/stats_controller_test.dart test/src/features/stats/stats_screen_test.dart
```

Expected red result:

- Tests fail because stats tracker or controller does not exist.

## Implementation Steps

- [ ] Step 1: Write stats tracker, controller, and screen tests.
- [ ] Step 2: Run red tests and confirm missing stats behavior.
- [ ] Step 3: Create `StudyStatsSummary`.
- [ ] Step 4: Add repository summary methods for today, last 7 days, and all time.
- [ ] Step 5: Create `StudyStatsTracker` for reading session minute increments.
- [ ] Step 6: Hook Reader controller reading session end into `StudyStatsTracker`.
- [ ] Step 7: Create `StatsController`.
- [ ] Step 8: Update `StatsScreen` with simple summary sections.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/stats/study_stats_tracker_test.dart test/src/features/stats/stats_controller_test.dart test/src/features/stats/stats_screen_test.dart
flutter analyze
```

## Acceptance Criteria

- Stats tests pass.
- Stats screen displays the five first-release counters.
- Stats are local-first and work offline.
- No complex chart or heatmap is added.
- No server sync execution is added.

## Stop Conditions

- Local study stats repository is incomplete.
- Reader controller cannot expose reading session end without modifying files outside Allowed Files.
- Any file outside Allowed Files must be modified.
- Any implementation requires live backend for stats display.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
