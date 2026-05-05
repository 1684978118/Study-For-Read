# M6-F02-T01 Mobile Auth Client Session

## Task ID

`M6-F02-T01`

## Title

Implement mobile auth client and session storage.

## Goal

Allow the mobile app to call auth APIs, store tokens securely, restore current user session, and sign out locally.

## Scope

This task only does:

- Add API envelope parsing for mobile.
- Add auth DTOs matching `API_CONTRACT.md`.
- Add `Dio` auth client.
- Add secure token store abstraction.
- Add auth session repository.
- Wire Sign In and Register placeholder screens to repository calls.
- Add unit and widget tests with fake HTTP and fake secure storage.

This task does not:

- Require a live backend.
- Add reading sync.
- Add local book database.
- Add social login.
- Add forgot password.

## Allowed Files

- `apps/mobile/lib/src/core/network/api_client.dart`
- `apps/mobile/lib/src/core/network/api_envelope.dart`
- `apps/mobile/lib/src/core/network/api_error.dart`
- `apps/mobile/lib/src/features/auth/domain/app_user.dart`
- `apps/mobile/lib/src/features/auth/domain/auth_session.dart`
- `apps/mobile/lib/src/features/auth/data/auth_api_client.dart`
- `apps/mobile/lib/src/features/auth/data/auth_token_store.dart`
- `apps/mobile/lib/src/features/auth/data/auth_session_repository.dart`
- `apps/mobile/lib/src/features/auth/presentation/sign_in_screen.dart`
- `apps/mobile/lib/src/features/auth/presentation/register_screen.dart`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/test/src/features/auth/auth_api_client_test.dart`
- `apps/mobile/test/src/features/auth/auth_session_repository_test.dart`
- `apps/mobile/test/src/features/auth/auth_screen_test.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/reader/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/lib/src/features/auth/presentation/sign_in_screen.dart`
- `apps/mobile/lib/src/features/auth/presentation/register_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/auth/auth_api_client_test.dart`
- `apps/mobile/test/src/features/auth/auth_session_repository_test.dart`
- `apps/mobile/test/src/features/auth/auth_screen_test.dart`

Test behavior:

- Login request sends email and password to `/api/v1/auth/login`.
- Register request sends email, password, display name, `sourceLang=ja`, and `targetLang=zh-CN`.
- Successful login parses user, access token, and refresh token from the API envelope.
- Error envelope maps `AUTH_INVALID_CREDENTIALS` to a stable mobile error.
- Tokens are written only through `AuthTokenStore`, not SQLite.
- Restoring a session calls `/api/v1/auth/me` when an access token exists.
- Sign out clears access and refresh tokens.
- Sign In screen shows inline error on invalid credentials.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/auth
```

Expected red result:

- Tests fail because auth client and session repository do not exist.

## Implementation Steps

- [ ] Step 1: Write auth API client, repository, and screen tests.
- [ ] Step 2: Run red tests and confirm missing class failures.
- [ ] Step 3: Create `ApiEnvelope` and `ApiError` matching backend response shape.
- [ ] Step 4: Create `AppUser` with `id`, `email`, `displayName`, `sourceLang`, `targetLang`, and `status`.
- [ ] Step 5: Create `AuthSession` with `user`, `accessToken`, and `refreshToken`.
- [ ] Step 6: Create `AuthApiClient` methods for register, login, refresh, and me.
- [ ] Step 7: Create `AuthTokenStore` backed by Flutter secure storage, with fake implementation in tests.
- [ ] Step 8: Create `AuthSessionRepository` for login, register, restore, refresh, and sign out.
- [ ] Step 9: Update Sign In and Register screens to call repository and show inline errors.
- [ ] Step 10: Update router auth state so a restored session can enter Library.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/auth
flutter analyze
```

## Acceptance Criteria

- Auth DTOs match `API_CONTRACT.md`.
- Tokens are stored through secure storage abstraction.
- No tokens are stored in SQLite.
- Tests use fake HTTP and do not require the backend server.
- Sign In and Register keep the user out of app tabs until authenticated.

## Stop Conditions

- M6-F01-T02 is incomplete.
- Auth API contract and screen flow conflict.
- A live backend is required to pass tests.
- Any file outside Allowed Files must be modified.
- Any implementation logs passwords or tokens.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
