# M1-F04-T01 Register Endpoint

## Task ID

`M1-F04-T01`

## Title

Implement user registration endpoint.

## Goal

Allow a new user to register with email and password and receive tokens.

## Scope

This task only does:

- Add registration request and response DTOs.
- Add password hashing.
- Add access token creation.
- Add refresh token creation.
- Add `POST /api/v1/auth/register`.
- Add tests for successful registration and duplicate email.

This task does not:

- Implement login.
- Implement refresh endpoint.
- Implement `/auth/me`.
- Implement admin auth.
- Implement reading sync.

## Allowed Files

- `server/src/main/java/com/studyforread/server/auth/AuthController.java`
- `server/src/main/java/com/studyforread/server/auth/AuthService.java`
- `server/src/main/java/com/studyforread/server/auth/dto/RegisterRequest.java`
- `server/src/main/java/com/studyforread/server/auth/dto/AuthResponse.java`
- `server/src/main/java/com/studyforread/server/auth/dto/UserProfileResponse.java`
- `server/src/main/java/com/studyforread/server/auth/TokenService.java`
- `server/src/main/java/com/studyforread/server/config/SecurityConfig.java`
- `server/src/test/java/com/studyforread/server/auth/RegisterEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`
- `server/src/main/java/com/studyforread/server/user/UserAccountRepository.java`
- `server/src/main/java/com/studyforread/server/auth/RefreshToken.java`
- `server/src/main/java/com/studyforread/server/auth/RefreshTokenRepository.java`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/api/ApiResponse.java`
- `server/src/main/java/com/studyforread/server/api/ErrorCode.java`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/auth/RegisterEndpointTest.java`

Test behavior:

- `POST /api/v1/auth/register` with new email returns HTTP 200 or 201, `success=true`, user email, access token, and refresh token.
- Duplicate email returns conflict status and error code `AUTH_EMAIL_ALREADY_EXISTS`.
- Response never contains `password` or `passwordHash`.
- Database stores only a 64-character SHA-256 hex hash of the refresh token, not the raw refresh token.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=RegisterEndpointTest test
```

Expected red result:

- Test fails because `/api/v1/auth/register` does not exist.

## Implementation Steps

- [ ] Step 1: Write `RegisterEndpointTest` using MockMvc or WebTestClient according to existing test style.
- [ ] Step 2: Run red test and confirm 404 or missing controller failure.
- [ ] Step 3: Add `RegisterRequest` with validation for email and password.
- [ ] Step 4: Add `UserProfileResponse` with `id`, `email`, `displayName`, `sourceLang`, `targetLang`, and `status`.
- [ ] Step 5: Add `AuthResponse` with `user`, `accessToken`, and `refreshToken`.
- [ ] Step 6: Add `TokenService` with minimal token creation needed for test. If JWT dependency is missing, use a signed opaque test-safe token only after documenting the limitation in the completion report.
- [ ] Step 7: Add `AuthService.register`.
- [ ] Step 8: When persisting refresh tokens, store only SHA-256 hex hash in `refresh_tokens.token_hash`.
- [ ] Step 9: Add `AuthController.register` at `POST /api/v1/auth/register`.
- [ ] Step 10: Add `SecurityConfig` allowing `/api/v1/auth/register`.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=RegisterEndpointTest test
```

## Acceptance Criteria

- Register endpoint matches API contract.
- Duplicate email returns `AUTH_EMAIL_ALREADY_EXISTS`.
- Password is hashed before storage.
- Refresh token is hashed before storage.
- Raw password is never returned.
- Test passes.
- Login is not implemented in this task.

## Stop Conditions

- JWT library is required but no dependency exists.
- Security configuration requires modifying files outside Allowed Files.
- Duplicate email cannot be tested because repository task is incomplete.
- Any file outside Allowed Files must be modified.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
