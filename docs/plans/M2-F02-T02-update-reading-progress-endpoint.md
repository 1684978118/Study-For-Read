# M2-F02-T02 Update Reading Progress Endpoint

## Task ID

`M2-F02-T02`

## Title

Implement reading progress update endpoint.

## Goal

Allow an authenticated user to update progress for their own synced book.

## Scope

This task only does:

- Add progress request and response DTOs.
- Add reading service progress update behavior.
- Add `PATCH /api/v1/reading/books/{bookFingerprint}/progress`.
- Add endpoint tests for valid update, missing book, invalid progress, and cross-user isolation.

This task does not:

- Add metadata upsert.
- Add list endpoint.
- Store original book content.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/reading/ReadingController.java`
- `server/src/main/java/com/studyforread/server/reading/ReadingService.java`
- `server/src/main/java/com/studyforread/server/reading/dto/ReadingProgressRequest.java`
- `server/src/main/java/com/studyforread/server/reading/dto/ReadingProgressResponse.java`
- `server/src/test/java/com/studyforread/server/reading/UpdateReadingProgressEndpointTest.java`

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
- `server/src/main/java/com/studyforread/server/reading/UserBookRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/reading/UpdateReadingProgressEndpointTest.java`

Test behavior:

- Authenticated user can update progress for their own book.
- Non-64-character or non-hex `bookFingerprint` returns `BOOK_PROGRESS_INVALID`.
- Negative chapter, paragraph, or offset returns `BOOK_PROGRESS_INVALID`.
- Updating a missing book returns `NOT_FOUND`.
- User A cannot update User B's book with the same fingerprint.
- Request body does not accept original text fields.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UpdateReadingProgressEndpointTest test
```

Expected red result:

- Test fails because progress endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `UpdateReadingProgressEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `ReadingProgressRequest` with `currentChapterIndex`, `currentParagraphIndex`, `currentCharOffset`, and `lastReadAt`.
- [ ] Step 4: Validate indexes and offset are not negative.
- [ ] Step 5: Validate `bookFingerprint` path variable as 64-character lowercase SHA-256 hex.
- [ ] Step 6: Create `ReadingProgressResponse`.
- [ ] Step 7: Add `ReadingService.updateProgress`.
- [ ] Step 8: Add `ReadingController.updateProgress`.
- [ ] Step 9: Ensure lookup uses current user id plus `bookFingerprint`.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UpdateReadingProgressEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/reading/books/{bookFingerprint}/progress`.
- Endpoint requires user auth.
- `bookFingerprint` validation matches API contract.
- Progress updates only the current user's matching book.
- Invalid progress returns `BOOK_PROGRESS_INVALID`.
- Missing current-user book returns `NOT_FOUND`.
- No original text is accepted or returned.

## Stop Conditions

- Metadata upsert task is incomplete.
- Current-user extraction from auth is unavailable.
- Any file outside Allowed Files must be modified.
- Implementing this requires reading or storing local book content.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
