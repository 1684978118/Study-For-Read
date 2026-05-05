# M9-F06-T01 Web Admin Nuxt Skeleton

## Task ID

`M9-F06-T01`

## Title

Create Nuxt web admin project skeleton.

## Goal

Create the first Nuxt admin app under `apps/web-admin` with baseline dependencies, tests, typecheck, and lint commands working.

## Scope

This task only does:

- Create the Nuxt app skeleton.
- Add approved admin dependencies.
- Add baseline test setup.
- Verify test and typecheck commands.

This task does not:

- Add admin auth behavior.
- Add dashboard UI.
- Add lexeme management UI.
- Modify backend, mobile, web reader, or infra files.

## Allowed Files

- `apps/web-admin/**`

## Forbidden Files

- `apps/mobile/**`
- `apps/web-reader/**`
- `server/**`
- `infra/**`
- `docs/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file outside `apps/web-admin/**`

## Read First

- `AGENTS.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/WEB_ADMIN.md`
- `docs/specs/API_CONTRACT.md`

## Tests First

This skeleton task cannot write a red Nuxt test before the Nuxt project exists.

Before implementation, run:

```powershell
node --version
npm --version
```

Expected result:

- Node.js and npm are installed and usable.

If Node.js or npm is missing, stop and report the blocker.

## Implementation Steps

- [ ] Step 1: Confirm `apps/web-admin/package.json` does not already exist. If it exists, stop and report that the admin app skeleton already exists.
- [ ] Step 2: Create the Nuxt app in `apps/web-admin`.
- [ ] Step 3: Add runtime dependencies: `@pinia/nuxt`, `pinia`, `ofetch`, and `zod`.
- [ ] Step 4: Add dev test dependencies for Vitest and Nuxt test utilities.
- [ ] Step 5: Add scripts: `test`, `typecheck`, and `dev`.
- [ ] Step 6: Keep generated files inside `apps/web-admin`.
- [ ] Step 7: Run `npm run test`.
- [ ] Step 8: Run `npm run typecheck`.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test
npm run typecheck
```

## Acceptance Criteria

- `apps/web-admin/package.json` exists.
- Nuxt app files exist under `apps/web-admin`.
- Approved dependencies are present.
- `npm run test` passes.
- `npm run typecheck` passes.
- No files outside `apps/web-admin/**` are modified.

## Stop Conditions

- Node.js or npm is missing.
- `apps/web-admin` already contains a different web project.
- Dependency download fails.
- Any command would modify files outside `apps/web-admin/**`.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

