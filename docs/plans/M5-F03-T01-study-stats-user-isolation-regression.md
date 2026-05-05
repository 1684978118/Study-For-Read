# M5-F03-T01 Study Stats User Isolation Regression

## Task ID

`M5-F03-T01`

## Title

Add study stats boundary regression tests.

## Goal

Protect the statistics boundary so synced learning counts stay user-owned, non-negative, and free of raw reading or translation content.

## Scope

This task only does:

- Add regression tests across stats persistence and APIs.
- Verify daily stats and summary are isolated per user.
- Verify stats storage does not contain raw content fields.
- Verify counter validation remains strict.

This task does not:

- Add new production endpoints.
- Add mobile code.
- Add admin dashboards.
- Add automatic calls from reading, vocabulary, or translation endpoints.

## Allowed Files

- `server/src/test/java/com/studyforread/server/stats/StudyStatsBoundaryRegressionTest.java`
- If and only if tests expose a boundary failure, these files may be modified:
  - `server/src/main/java/com/studyforread/server/stats/StudyStatsController.java`
  - `server/src/main/java/com/studyforread/server/stats/StudyStatsService.java`
  - `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`
  - `server/src/main/java/com/studyforread/server/stats/dto/AddDailyStatsRequest.java`
  - `server/src/main/java/com/studyforread/server/stats/dto/DailyStatsResponse.java`
  - `server/src/main/java/com/studyforread/server/stats/dto/StudySummaryResponse.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/reading/**`
- `server/src/main/java/com/studyforread/server/study/**`
- `server/src/main/java/com/studyforread/server/vocabulary/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- All M5 study stats task cards.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/stats/StudyStatsBoundaryRegressionTest.java`

Test behavior:

- `study_daily_stats` table has no columns named `content`, `chapter_content`, `original_file`, `file_path`, `source_text`, `raw_text`, `translated_text`, or `paragraph_text`.
- User A cannot increment User B's daily stats because the endpoint never accepts `userId` from the request body.
- User A summary excludes User B rows.
- Counter fields reject negative values through API validation.
- Counter fields reject negative values through database constraints.
- Daily and summary responses do not include raw content fields.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudyStatsBoundaryRegressionTest test
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual stats boundary gap.

## Implementation Steps

- [ ] Step 1: Write `StudyStatsBoundaryRegressionTest`.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to stats boundary leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M5 stats tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudyStatsBoundaryRegressionTest test
.\mvnw.cmd -Dtest=StudyDailyStatRepositoryTest,AddDailyStatsEndpointTest,StudySummaryEndpointTest,StudyStatsBoundaryRegressionTest test
```

## Acceptance Criteria

- Boundary regression test passes.
- All M5 study stats tests pass.
- Stats rows are current-user owned.
- Stats counters are non-negative.
- Stats APIs do not accept request-owned `userId`.
- Stats persistence and responses do not store or expose raw content.

## Stop Conditions

- M5 endpoint tasks are incomplete.
- Boundary failure requires migration changes.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

