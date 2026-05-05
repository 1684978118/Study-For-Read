# M5-F02-T01 Add Daily Stats Endpoint

## Task ID

`M5-F02-T01`

## Title

Implement daily stats increment endpoint.

## Goal

Allow an authenticated user to add daily study counters and receive the updated stored totals for that date.

## Scope

This task only does:

- Add stats request and response DTOs.
- Add stats service behavior for create-or-increment by current user and date.
- Add `POST /api/v1/stats/daily`.
- Add endpoint tests for auth, validation, increment semantics, and user isolation.

This task does not:

- Add summary endpoint.
- Add automatic stats updates from other endpoints.
- Add mobile UI.
- Add admin stats.
- Store raw book content, lookup text, or translated paragraph text.

## Allowed Files

- `server/src/main/java/com/studyforread/server/stats/StudyStatsController.java`
- `server/src/main/java/com/studyforread/server/stats/StudyStatsService.java`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`
- `server/src/main/java/com/studyforread/server/stats/dto/AddDailyStatsRequest.java`
- `server/src/main/java/com/studyforread/server/stats/dto/DailyStatsResponse.java`
- `server/src/test/java/com/studyforread/server/stats/AddDailyStatsEndpointTest.java`

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
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStat.java`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`
- Existing auth endpoint tests for how to create authenticated requests.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/stats/AddDailyStatsEndpointTest.java`

Test behavior:

- Unauthenticated request returns `UNAUTHORIZED`.
- First authenticated `POST /api/v1/stats/daily` creates a row and returns the same counter totals.
- Second authenticated request for the same `statDate` increments existing totals and returns updated totals.
- Same `statDate` for User A and User B produces separate rows.
- Missing `statDate` returns `VALIDATION_ERROR`.
- Negative counter values return `VALIDATION_ERROR`.
- A request whose increment would overflow an integer counter returns `VALIDATION_ERROR`.
- Response does not include `content`, `chapterContent`, `originalFile`, `filePath`, `sourceText`, `rawText`, `translatedText`, or `paragraphText`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AddDailyStatsEndpointTest test
```

Expected red result:

- Test fails because stats controller, service, or endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `AddDailyStatsEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `AddDailyStatsRequest` with `statDate`, `readingMinutes`, `lookupCount`, `paragraphTranslationCount`, `cardsCreated`, and `cardsReviewed`.
- [ ] Step 4: Add bean validation annotations so `statDate` is required and counters are zero or positive.
- [ ] Step 5: Create `DailyStatsResponse` matching API contract.
- [ ] Step 6: Add repository lookup method for current user id and `statDate` if it does not already exist.
- [ ] Step 7: Implement `StudyStatsService.addDailyStats` to find an existing row or create a new row for current user and date.
- [ ] Step 8: Increment counters and return stored totals after incrementing.
- [ ] Step 9: Guard integer overflow before saving.
- [ ] Step 10: Add `StudyStatsController.addDailyStats` at `POST /api/v1/stats/daily`.
- [ ] Step 11: Ensure request DTO has no fields for original book content, chapter content, lookup text, or translated paragraph text.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AddDailyStatsEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/stats/daily`.
- Endpoint requires user auth.
- Endpoint creates a daily row when missing.
- Endpoint increments an existing current-user daily row.
- Negative counters and overflow attempts are rejected.
- User stats are isolated by `user_id`.
- Response contains only stats fields, not raw content fields.

## Stop Conditions

- Study daily stats persistence is incomplete.
- Auth helper pattern is unclear after reading existing tests.
- Adding this endpoint requires modifying files outside Allowed Files.
- Any implementation overwrites another user's stats.
- Any implementation stores raw book content, raw lookup text, or translated paragraph text.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

