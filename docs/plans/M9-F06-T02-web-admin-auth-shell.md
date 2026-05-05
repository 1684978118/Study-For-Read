# M9-F06-T02 Web Admin Auth Shell

## Task ID

`M9-F06-T02`

## Title

Add web admin auth shell.

## Goal

Allow admins to sign in, store admin token through an abstraction, restore current admin, and protect admin pages.

## Scope

This task only does:

- Add admin API envelope parsing.
- Add admin auth client and token store abstraction.
- Add admin Pinia auth store.
- Add auth middleware.
- Add sign-in page and app shell placeholders.
- Add tests with fake HTTP and fake token store.

This task does not:

- Add dashboard data.
- Add user list.
- Add lexeme management.
- Add role management.

## Allowed Files

- `apps/web-admin/app.vue`
- `apps/web-admin/nuxt.config.ts`
- `apps/web-admin/middleware/admin-auth.global.ts`
- `apps/web-admin/pages/admin/sign-in.vue`
- `apps/web-admin/pages/admin/index.vue`
- `apps/web-admin/components/layout/AdminShell.vue`
- `apps/web-admin/composables/useAdminApiClient.ts`
- `apps/web-admin/composables/useAdminTokenStore.ts`
- `apps/web-admin/stores/adminAuth.ts`
- `apps/web-admin/types/api.ts`
- `apps/web-admin/types/adminAuth.ts`
- `apps/web-admin/tests/auth/admin-auth-client.test.ts`
- `apps/web-admin/tests/auth/admin-auth-store.test.ts`
- `apps/web-admin/tests/auth/admin-auth-pages.test.ts`

## Forbidden Files

- `apps/web-admin/package.json`
- `apps/web-admin/pages/admin/users.vue`
- `apps/web-admin/pages/admin/stats.vue`
- `apps/web-admin/pages/admin/audit-logs.vue`
- `apps/web-admin/pages/admin/lexemes/**`
- `apps/mobile/**`
- `apps/web-reader/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/WEB_ADMIN.md`
- `apps/web-admin/package.json`
- `apps/web-admin/nuxt.config.ts`

## Tests First

Create:

- `apps/web-admin/tests/auth/admin-auth-client.test.ts`
- `apps/web-admin/tests/auth/admin-auth-store.test.ts`
- `apps/web-admin/tests/auth/admin-auth-pages.test.ts`

Test behavior:

- Admin login request sends username and password to `/api/v1/admin/auth/login`.
- Successful login parses admin profile and access token.
- Invalid credentials map `ADMIN_INVALID_CREDENTIALS` to stable admin UI error.
- Disabled admin maps `ADMIN_DISABLED` to stable admin UI error.
- Token is stored only through admin token store abstraction.
- Restoring session calls `/api/v1/admin/auth/me` when token exists.
- Signed-out admin navigating to `/admin` is redirected to `/admin/sign-in`.
- User auth token is not accepted by admin auth store tests.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/auth
```

Expected red result:

- Tests fail because admin auth store, middleware, or pages do not exist.

## Implementation Steps

- [ ] Step 1: Write admin auth client, store, and page tests.
- [ ] Step 2: Run red tests and confirm missing auth behavior.
- [ ] Step 3: Create API envelope and API error types.
- [ ] Step 4: Create admin profile and session types.
- [ ] Step 5: Create `useAdminApiClient`.
- [ ] Step 6: Create `useAdminTokenStore`.
- [ ] Step 7: Create Pinia `adminAuth` store for login, restore, and sign out.
- [ ] Step 8: Create auth middleware that redirects signed-out admins to `/admin/sign-in`.
- [ ] Step 9: Create Sign In page and admin shell placeholder.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/auth
npm run typecheck
```

## Acceptance Criteria

- Admin auth tests pass.
- Signed-out admins cannot open admin pages.
- Admin token storage uses one abstraction.
- Tests use fake HTTP and do not require a live backend.
- No dashboard or lexeme management behavior is added.

## Stop Conditions

- Web admin skeleton task is incomplete.
- Admin auth API contract and page flow conflict.
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

