# M1-F04-T02 Login Refresh And Me Endpoints

## Task ID

`M1-F04-T02`

## Title

Implement login, token refresh, and current user endpoints.

## Goal

Complete the first user authentication API set from `API_CONTRACT.md`.

## Scope

This task only does:

- Add `POST /api/v1/auth/login`.
- Add `POST /api/v1/auth/refresh`.
- Add `GET /api/v1/auth/me`.
- Add tests for valid login, invalid login, refresh, and current user.

This task does not:

- Add password reset.
- Add social login.
- Add admin login.
- Add reading sync.
- Add mobile UI.

## Allowed Files

- `server/src/main/java/com/studyforread/server/auth/AuthController.java`
- `server/src/main/java/com/studyforread/server/auth/AuthService.java`
- `server/src/main/java/com/studyforread/server/auth/TokenService.java`
- `server/src/main/java/com/studyforread/server/auth/dto/LoginRequest.java`
- `server/src/main/java/com/studyforread/server/auth/dto/RefreshRequest.java`
- `server/src/main/java/com/studyforread/server/auth/dto/TokenRefreshResponse.java`
- `server/src/main/java/com/studyforread/server/config/SecurityConfig.java`
- `server/src/test/java/com/studyforread/server/auth/LoginRefreshMeEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`
- `server/src/main/java/com/studyforread/server/user/UserAccountRepository.java`
- `server/src/main/java/com/studyforread/server/api/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/auth/AuthController.java`
- `server/src/main/java/com/studyforread/server/auth/AuthService.java`
- `server/src/main/java/com/studyforread/server/auth/TokenService.java`
- `server/src/main/java/com/studyforread/server/config/SecurityConfig.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/auth/LoginRefreshMeEndpointTest.java`

Test behavior:

- Existing registered user can login and receives user, access token, and refresh token.
- Wrong password returns `AUTH_INVALID_CREDENTIALS`.
- Valid refresh token returns new access and refresh tokens.
- Invalid refresh token returns `AUTH_REFRESH_TOKEN_INVALID`.
- Raw refresh token is never stored; lookup uses SHA-256 hex hash.
- `GET /api/v1/auth/me` with valid access token returns current user.
- `GET /api/v1/auth/me` without token returns `UNAUTHORIZED`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=LoginRefreshMeEndpointTest test
```

Expected red result:

- Test fails because login, refresh, or me endpoints do not exist.

## Implementation Steps

- [ ] Step 1: Write `LoginRefreshMeEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing or unauthorized behavior is incomplete.
- [ ] Step 3: Add `LoginRequest` with email and password validation.
- [ ] Step 4: Add `RefreshRequest` with refresh token validation.
- [ ] Step 5: Add `TokenRefreshResponse` with `accessToken` and `refreshToken`.
- [ ] Step 6: Add `AuthService.login`.
- [ ] Step 7: Add `AuthService.refresh`.
- [ ] Step 8: Ensure refresh lookup hashes the presented token to SHA-256 hex before repository lookup.
- [ ] Step 9: Add current-user token parsing in `TokenService`.
- [ ] Step 10: Add controller methods for `/login`, `/refresh`, and `/me`.
- [ ] Step 11: Update `SecurityConfig` to allow login and refresh but require auth for `/me`.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=LoginRefreshMeEndpointTest test
.\mvnw.cmd test
```

## Acceptance Criteria

- Login, refresh, and me endpoints match API contract.
- Invalid login does not reveal whether email exists.
- Refresh token is revocable by data model, even if revocation endpoint is not implemented yet.
- Raw refresh tokens are never persisted.
- `/me` requires authentication.
- All auth tests pass.
- No non-auth feature is implemented.

## Stop Conditions

- Existing register task is incomplete.
- Token format from prior task cannot identify current user.
- Security setup requires new dependencies not in `pom.xml`.
- Any file outside Allowed Files must be modified.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
