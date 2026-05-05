# M8-F01-T02 Web Reader Auth Gate

## Task ID

`M8-F01-T02`

## Title

Add web reader auth client and signed-in gate.

## Goal

Allow the Nuxt web reader to register, sign in, store tokens through an abstraction, restore current user, and keep signed-out users away from app pages.

## Scope

This task only does:

- Add API envelope parsing.
- Add auth DTOs and client.
- Add token store abstraction.
- Add auth Pinia store.
- Add auth middleware.
- Add Sign In and Register pages.
- Add tests with fake HTTP and fake token store.

This task does not:

- Add book import.
- Add IndexedDB stores.
- Add reader UI.
- Add social login or forgot password.

## Allowed Files

- `apps/web-reader/app.vue`
- `apps/web-reader/nuxt.config.ts`
- `apps/web-reader/middleware/auth.global.ts`
- `apps/web-reader/pages/sign-in.vue`
- `apps/web-reader/pages/register.vue`
- `apps/web-reader/pages/library.vue`
- `apps/web-reader/composables/useApiClient.ts`
- `apps/web-reader/composables/useAuthTokenStore.ts`
- `apps/web-reader/stores/auth.ts`
- `apps/web-reader/types/api.ts`
- `apps/web-reader/types/auth.ts`
- `apps/web-reader/tests/auth/auth-client.test.ts`
- `apps/web-reader/tests/auth/auth-store.test.ts`
- `apps/web-reader/tests/auth/auth-pages.test.ts`

## Forbidden Files

- `apps/web-reader/package.json`
- `apps/web-reader/pages/reader/**`
- `apps/web-reader/stores/library.ts`
- `apps/web-reader/stores/reader.ts`
- `apps/web-reader/db/**`
- `apps/mobile/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`
- `apps/web-reader/package.json`
- `apps/web-reader/nuxt.config.ts`

## Tests First

Create:

- `apps/web-reader/tests/auth/auth-client.test.ts`
- `apps/web-reader/tests/auth/auth-store.test.ts`
- `apps/web-reader/tests/auth/auth-pages.test.ts`

Test behavior:

- Login request sends email and password to `/api/v1/auth/login`.
- Register request sends email, password, display name, `sourceLang=ja`, and `targetLang=zh-CN`.
- Successful login parses user, access token, and refresh token from API envelope.
- Error envelope maps `AUTH_INVALID_CREDENTIALS` to a stable web error.
- Tokens are stored only through token store abstraction.
- Restoring a session calls `/api/v1/auth/me` when an access token exists.
- Sign out clears access and refresh tokens.
- Signed-out users navigating to `/library` are redirected to `/sign-in`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/auth
```

Expected red result:

- Tests fail because auth store, middleware, or pages do not exist.

## Implementation Steps

- [ ] Step 1: Write auth client, auth store, and auth page tests.
- [ ] Step 2: Run red tests and confirm missing auth behavior.
- [ ] Step 3: Create API envelope and API error types.
- [ ] Step 4: Create auth user and session types.
- [ ] Step 5: Create `useApiClient` with base URL configuration.
- [ ] Step 6: Create `useAuthTokenStore` abstraction backed by browser storage in client runtime.
- [ ] Step 7: Create Pinia `auth` store for login, register, restore, refresh, and sign out.
- [ ] Step 8: Create auth middleware that redirects signed-out users to `/sign-in`.
- [ ] Step 9: Create Sign In, Register, and Library placeholder pages.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/auth
npm run typecheck
```

## Acceptance Criteria

- Auth tests pass.
- Signed-out users cannot open app pages.
- Tokens are accessed through one abstraction.
- Tests use fake HTTP and do not require a live backend.
- No IndexedDB or reader behavior is added.

## Stop Conditions

- Nuxt skeleton task is incomplete.
- API contract and auth page flow conflict.
- Tests require live backend.
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

