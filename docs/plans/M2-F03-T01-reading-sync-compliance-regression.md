# M2-F03-T01 Reading Sync Compliance Regression

## Task ID

`M2-F03-T01`

## Title

Add compliance regression tests for reading sync.

## Goal

Protect the core rule that the backend never accepts, stores, or returns original book content.

## Scope

This task only does:

- Add compliance tests across reading sync APIs.
- Verify database schema has no original-content columns.
- Verify API responses do not include original-content fields.
- Verify suspicious request fields are rejected.

This task does not:

- Add new production endpoints.
- Change reading business behavior unless tests reveal an actual compliance gap.
- Add mobile code.
- Add translation code.

## Allowed Files

- `server/src/test/java/com/studyforread/server/reading/ReadingSyncComplianceTest.java`
- If and only if the test exposes a compliance failure, these files may be modified:
  - `server/src/main/java/com/studyforread/server/reading/ReadingController.java`
  - `server/src/main/java/com/studyforread/server/reading/ReadingService.java`
  - `server/src/main/java/com/studyforread/server/reading/dto/BookMetadataRequest.java`
  - `server/src/main/java/com/studyforread/server/reading/dto/ReadingProgressRequest.java`
  - `server/src/main/java/com/studyforread/server/reading/dto/BookResponse.java`
  - `server/src/main/java/com/studyforread/server/reading/dto/BookListResponse.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- All M2 reading task cards.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/reading/ReadingSyncComplianceTest.java`

Test behavior:

- `user_books` table has no columns named `content`, `chapter_content`, `original_file`, or `file_path`.
- `user_books.book_fingerprint` is `char(64)`.
- `user_books` has check constraints for file type and non-negative progress fields.
- `PUT /api/v1/reading/books/{bookFingerprint}` rejects JSON containing `content`.
- `PUT /api/v1/reading/books/{bookFingerprint}` rejects JSON containing `chapterContent`.
- `PUT /api/v1/reading/books/{bookFingerprint}` rejects JSON containing `originalFile`.
- `PUT /api/v1/reading/books/{bookFingerprint}` rejects JSON containing `filePath`.
- `GET /api/v1/reading/books` response JSON does not contain those field names.
- `PATCH /api/v1/reading/books/{bookFingerprint}/progress` response JSON does not contain those field names.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ReadingSyncComplianceTest test
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual compliance gap.

## Implementation Steps

- [ ] Step 1: Write `ReadingSyncComplianceTest`.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to forbidden fields being accepted or returned, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M2 reading tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ReadingSyncComplianceTest test
.\mvnw.cmd -Dtest=UserBookRepositoryTest,UpsertBookMetadataEndpointTest,UpdateReadingProgressEndpointTest,ListReadingBooksEndpointTest,ReadingSyncComplianceTest test
```

## Acceptance Criteria

- Compliance test passes.
- All M2 reading tests pass.
- No schema column stores original content.
- No reading sync response returns original content fields.
- Suspicious request fields are rejected.

## Stop Conditions

- M2 endpoint tasks are incomplete.
- Compliance failure requires migration changes.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
