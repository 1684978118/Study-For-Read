# M9-F02-T01 Admin Auth Endpoints

## Task ID

`M9-F02-T01`

## Title

Implement admin login and current-admin endpoints.

## Goal

Allow administrators to sign in with separate admin access tokens and retrieve their current admin profile.

## Scope

This task only does:

- Add admin auth DTOs.
- Add admin auth service.
- Add `POST /api/v1/admin/auth/login`.
- Add `GET /api/v1/admin/auth/me`.
- Add endpoint tests for login, disabled admin, invalid credentials, and user-token rejection.

This task does not:

- Add admin refresh tokens.
- Add admin web UI.
- Add user management endpoints.
- Add role management endpoints.

## Allowed Files

- `server/src/main/java/com/studyforread/server/admin/AdminAuthController.java`
- `server/src/main/java/com/studyforread/server/admin/AdminAuthService.java`
- `server/src/main/java/com/studyforread/server/admin/AdminPrincipal.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLoginRequest.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLoginResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminProfileResponse.java`
- `server/src/main/java/com/studyforread/server/security/AdminJwtService.java`
- `server/src/main/java/com/studyforread/server/security/AdminAuthenticationFilter.java`
- `server/src/main/java/com/studyforread/server/security/SecurityConfig.java`
- `server/src/test/java/com/studyforread/server/admin/AdminAuthEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/user/**`
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
- `docs/specs/WEB_ADMIN.md`
- `server/src/main/java/com/studyforread/server/admin/AdminUserRepository.java`
- Existing user auth controller and security configuration.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/admin/AdminAuthEndpointTest.java`

Test behavior:

- Active admin can login and receives admin profile plus access token.
- Invalid credentials return `ADMIN_INVALID_CREDENTIALS`.
- Disabled admin returns `ADMIN_DISABLED`.
- Password hash is never returned.
- `GET /api/v1/admin/auth/me` requires admin token.
- Normal user access token cannot call admin auth me and returns `ADMIN_REQUIRED`.
- Admin token does not authenticate as a normal user token.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminAuthEndpointTest test
```

Expected red result:

- Test fails because admin auth endpoint or admin security does not exist.

## Implementation Steps

- [ ] Step 1: Write `AdminAuthEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create admin auth DTOs matching `API_CONTRACT.md`.
- [ ] Step 4: Create `AdminPrincipal`.
- [ ] Step 5: Create `AdminJwtService` with admin-specific token claims.
- [ ] Step 6: Create admin authentication filter.
- [ ] Step 7: Update security config so `/api/v1/admin/**` requires admin authentication.
- [ ] Step 8: Implement admin login with password encoder and active-status check.
- [ ] Step 9: Implement current-admin endpoint.
- [ ] Step 10: Ensure password hashes and tokens are not logged or returned.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminAuthEndpointTest test
```

## Acceptance Criteria

- Admin auth endpoint tests pass.
- Admin and user tokens are separated.
- Disabled admins cannot log in.
- User tokens cannot access admin APIs.
- No admin refresh token flow is added.

## Stop Conditions

- Admin persistence is incomplete.
- Existing security config cannot support separate admin tokens without modifying files outside Allowed Files.
- Any implementation exposes password hashes or raw tokens.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

