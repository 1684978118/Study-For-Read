# M1-F02-T01 API Envelope And Error Codes

## Task ID

`M1-F02-T01`

## Title

Create the unified API response envelope and error code model.

## Goal

Provide reusable response objects that match `docs/specs/API_CONTRACT.md`.

## Scope

This task only does:

- Add `ApiResponse`.
- Add `ApiError`.
- Add `ErrorCode`.
- Add unit tests for success and error response shapes.

This task does not:

- Add controllers.
- Add global exception handling.
- Add auth endpoints.
- Add database code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/api/ApiResponse.java`
- `server/src/main/java/com/studyforread/server/api/ApiError.java`
- `server/src/main/java/com/studyforread/server/api/ErrorCode.java`
- `server/src/test/java/com/studyforread/server/api/ApiResponseTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/StudyForReadServerApplication.java`
- `server/src/main/resources/**`
- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/api/ApiResponseTest.java`

Test behavior:

- `ApiResponse.ok(data)` sets `success=true`, `data=data`, `error=null`.
- `ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Authentication required")` sets `success=false`, `data=null`, and error code/message.
- `ErrorCode` includes at least: `VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `INTERNAL_ERROR`, `AUTH_EMAIL_ALREADY_EXISTS`, `AUTH_INVALID_CREDENTIALS`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ApiResponseTest test
```

Expected red result:

- Test fails because `ApiResponse`, `ApiError`, or `ErrorCode` does not exist.

## Implementation Steps

- [ ] Step 1: Write `ApiResponseTest`.
- [ ] Step 2: Run the red test and confirm missing class failure.
- [ ] Step 3: Create immutable `ApiError` with `code` and `message`.
- [ ] Step 4: Create `ErrorCode` enum with exact string names from API contract.
- [ ] Step 5: Create generic `ApiResponse<T>` with fields `success`, `data`, and `error`.
- [ ] Step 6: Add static factory methods `ok(T data)` and `fail(ErrorCode code, String message)`.
- [ ] Step 7: Run the verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ApiResponseTest test
```

## Acceptance Criteria

- Tests pass.
- Response field names match API contract exactly: `success`, `data`, `error`.
- Error field names match API contract exactly: `code`, `message`.
- No controller code is added.

## Stop Conditions

- Test cannot compile for reasons unrelated to missing response classes.
- A new dependency is needed.
- Any file outside Allowed Files must be modified.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

