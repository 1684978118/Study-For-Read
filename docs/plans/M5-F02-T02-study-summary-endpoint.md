# M5-F02-T02 Study Summary Endpoint

## Task ID

`M5-F02-T02`

## Title

Implement study summary endpoint.

## Goal

Allow an authenticated user to retrieve total study statistics across all of their daily stats rows.

## Scope

This task only does:

- Add summary response DTO.
- Add service behavior for current-user aggregate totals.
- Add `GET /api/v1/stats/summary`.
- Add endpoint tests for auth, zero state, aggregation, and user isolation.

This task does not:

- Add date-range filtering.
- Add charts or heatmap data.
- Add admin summary APIs.
- Add mobile UI.
- Store or expose raw content.

## Allowed Files

- `server/src/main/java/com/studyforread/server/stats/StudyStatsController.java`
- `server/src/main/java/com/studyforread/server/stats/StudyStatsService.java`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`
- `server/src/main/java/com/studyforread/server/stats/dto/StudySummaryResponse.java`
- `server/src/test/java/com/studyforread/server/stats/StudySummaryEndpointTest.java`

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
- `server/src/main/java/com/studyforread/server/stats/StudyStatsController.java`
- `server/src/main/java/com/studyforread/server/stats/StudyStatsService.java`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/stats/StudySummaryEndpointTest.java`

Test behavior:

- Unauthenticated request returns `UNAUTHORIZED`.
- Authenticated user with no stats receives zeros for every counter.
- Authenticated user with multiple daily rows receives summed totals.
- User A summary excludes User B rows.
- Response does not include `statDate`, `userId`, `content`, `chapterContent`, `originalFile`, `filePath`, `sourceText`, `rawText`, `translatedText`, or `paragraphText`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudySummaryEndpointTest test
```

Expected red result:

- Test fails because summary endpoint or response DTO does not exist.

## Implementation Steps

- [ ] Step 1: Write `StudySummaryEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `StudySummaryResponse` with `readingMinutes`, `lookupCount`, `paragraphTranslationCount`, `cardsCreated`, and `cardsReviewed`.
- [ ] Step 4: Add repository aggregate query or service aggregation for one current user.
- [ ] Step 5: Return zero for every counter when the user has no rows.
- [ ] Step 6: Implement `StudyStatsService.getSummary` using only current-user rows.
- [ ] Step 7: Add `StudyStatsController.getSummary` at `GET /api/v1/stats/summary`.
- [ ] Step 8: Ensure response DTO has no user id, date, book metadata, or raw content fields.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudySummaryEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/stats/summary`.
- Endpoint requires user auth.
- New users receive zero totals.
- Totals are summed only from current-user rows.
- Response contains only aggregate counter fields.

## Stop Conditions

- Daily stats endpoint task is incomplete and controller/service patterns do not exist.
- Adding this endpoint requires modifying files outside Allowed Files.
- Any implementation reads another user's stats.
- Any implementation exposes raw book content, raw lookup text, or translated paragraph text.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

