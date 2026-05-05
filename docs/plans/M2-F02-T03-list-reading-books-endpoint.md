# M2-F02-T03 List Reading Books Endpoint

## Task ID

`M2-F02-T03`

## Title

Implement reading books list endpoint.

## Goal

Allow an authenticated user to list only their synced book metadata and progress.

## Scope

This task only does:

- Add list response DTO.
- Add reading service list behavior.
- Add `GET /api/v1/reading/books`.
- Add endpoint tests for empty list, sorted list, and user isolation.

This task does not:

- Add metadata upsert.
- Add progress update.
- Store or return original book content.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/reading/ReadingController.java`
- `server/src/main/java/com/studyforread/server/reading/ReadingService.java`
- `server/src/main/java/com/studyforread/server/reading/dto/BookListResponse.java`
- `server/src/test/java/com/studyforread/server/reading/ListReadingBooksEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/reading/UserBook.java`
- `server/src/main/java/com/studyforread/server/reading/UserBookRepository.java`
- `server/src/main/java/com/studyforread/server/auth/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/reading/ReadingController.java`
- `server/src/main/java/com/studyforread/server/reading/ReadingService.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/reading/ListReadingBooksEndpointTest.java`

Test behavior:

- Authenticated user with no synced books receives `items: []`.
- Authenticated user sees only their own books.
- Books are ordered by `lastReadAt` descending, with nulls last.
- Response does not include `content`, `chapterContent`, `originalFile`, or `filePath`.
- Unauthenticated request returns `UNAUTHORIZED`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ListReadingBooksEndpointTest test
```

Expected red result:

- Test fails because list endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `ListReadingBooksEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `BookListResponse` with `items`.
- [ ] Step 4: Reuse `BookResponse` from metadata upsert task.
- [ ] Step 5: Add `ReadingService.listBooks`.
- [ ] Step 6: Add `ReadingController.listBooks`.
- [ ] Step 7: Ensure repository query filters by current user id.
- [ ] Step 8: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ListReadingBooksEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/reading/books`.
- Endpoint requires user auth.
- Response shape matches API contract.
- User isolation is tested.
- Original content fields never appear in response.

## Stop Conditions

- Prior reading service/controller files do not exist.
- Repository ordering method is missing and cannot be changed within this task.
- Any file outside Allowed Files must be modified.
- Implementing this requires returning original book content.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

