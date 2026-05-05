# M2-F02-T01 Upsert Book Metadata Endpoint

## Task ID

`M2-F02-T01`

## Title

Implement synced book metadata upsert endpoint.

## Goal

Allow an authenticated user to create or update local book metadata by fingerprint without uploading original book content.

## Scope

This task only does:

- Add request and response DTOs for book metadata.
- Add reading service upsert behavior.
- Add `PUT /api/v1/reading/books/{bookFingerprint}`.
- Add endpoint tests for create, update, auth required, and forbidden content fields.

This task does not:

- Add progress update endpoint.
- Add list endpoint.
- Parse TXT or EPUB.
- Store chapter content.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/reading/ReadingController.java`
- `server/src/main/java/com/studyforread/server/reading/ReadingService.java`
- `server/src/main/java/com/studyforread/server/reading/dto/BookMetadataRequest.java`
- `server/src/main/java/com/studyforread/server/reading/dto/BookResponse.java`
- `server/src/test/java/com/studyforread/server/reading/UpsertBookMetadataEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/reading/UserBook.java`
- `server/src/main/java/com/studyforread/server/reading/UserBookRepository.java`
- `server/src/main/java/com/studyforread/server/auth/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/reading/UserBook.java`
- `server/src/main/java/com/studyforread/server/reading/UserBookRepository.java`
- `server/src/main/java/com/studyforread/server/auth/TokenService.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/reading/UpsertBookMetadataEndpointTest.java`

Test behavior:

- Authenticated user can `PUT /api/v1/reading/books/{bookFingerprint}` with metadata and gets `success=true`.
- Repeating the same request updates title or chapter count instead of creating a duplicate.
- Unauthenticated request returns `UNAUTHORIZED`.
- Non-64-character or non-hex `bookFingerprint` returns `BOOK_METADATA_INVALID`.
- `chapterCount < 1` returns `BOOK_METADATA_INVALID`.
- Unsupported `fileType` returns `BOOK_METADATA_INVALID`.
- Request containing a top-level `content`, `chapterContent`, `originalFile`, or `filePath` field returns `BOOK_METADATA_INVALID`.
- Response does not include original book text fields.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UpsertBookMetadataEndpointTest test
```

Expected red result:

- Test fails because reading endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `UpsertBookMetadataEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing or unauthorized behavior is incomplete.
- [ ] Step 3: Create `BookMetadataRequest` with `title`, `author`, `fileType`, `sourceLang`, `targetLang`, and `chapterCount`.
- [ ] Step 4: Ensure request validation rejects blank title, unsupported file type, and chapter count below 1.
- [ ] Step 5: Validate `bookFingerprint` path variable as 64-character lowercase SHA-256 hex.
- [ ] Step 6: Add explicit rejection for forbidden JSON fields: `content`, `chapterContent`, `originalFile`, `filePath`.
- [ ] Step 7: Create `BookResponse` matching API contract.
- [ ] Step 8: Add `ReadingService.upsertBookMetadata`.
- [ ] Step 9: Add `ReadingController.upsertBookMetadata`.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UpsertBookMetadataEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/reading/books/{bookFingerprint}`.
- Endpoint requires user auth.
- Same user and fingerprint updates one row.
- `bookFingerprint` validation matches API contract.
- Forbidden content fields are rejected with `BOOK_METADATA_INVALID`.
- Response never includes original book text.

## Stop Conditions

- Current-user extraction from auth is unavailable.
- Rejection of unknown JSON fields requires global config outside Allowed Files.
- Any file outside Allowed Files must be modified.
- Implementing this requires storing original book content.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
