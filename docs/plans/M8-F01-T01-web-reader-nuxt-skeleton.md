# M8-F01-T01 Web Reader Nuxt Skeleton

## Task ID

`M8-F01-T01`

## Title

Create Nuxt web reader project skeleton.

## Goal

Create the first Nuxt app under `apps/web-reader` with baseline dependencies, tests, typecheck, and lint commands working.

## Scope

This task only does:

- Create the Nuxt project skeleton.
- Add approved first-release dependencies.
- Add baseline test setup.
- Verify test and typecheck commands.

This task does not:

- Add reader UI.
- Add authentication behavior.
- Add IndexedDB schema.
- Add parser logic.
- Modify backend, mobile, admin, or infra files.

## Allowed Files

- `apps/web-reader/**`

## Forbidden Files

- `apps/mobile/**`
- `apps/web-admin/**`
- `server/**`
- `infra/**`
- `docs/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file outside `apps/web-reader/**`

## Read First

- `AGENTS.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`

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

- [ ] Step 1: Confirm `apps/web-reader/package.json` does not already exist. If it exists, stop and report that the app skeleton already exists.
- [ ] Step 2: Create the Nuxt app in `apps/web-reader`.
- [ ] Step 3: Add runtime dependencies: `@pinia/nuxt`, `pinia`, `dexie`, `ofetch`, `zod`, `jszip`, and `fast-xml-parser`.
- [ ] Step 4: Add dev test dependencies for Vitest and Nuxt test utilities.
- [ ] Step 5: Add scripts: `test`, `typecheck`, and `dev`.
- [ ] Step 6: Keep generated files inside `apps/web-reader`.
- [ ] Step 7: Run `npm run test`.
- [ ] Step 8: Run `npm run typecheck`.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test
npm run typecheck
```

## Acceptance Criteria

- `apps/web-reader/package.json` exists.
- Nuxt app files exist under `apps/web-reader`.
- Approved dependencies are present.
- `npm run test` passes.
- `npm run typecheck` passes.
- No files outside `apps/web-reader/**` are modified.

## Stop Conditions

- Node.js or npm is missing.
- `apps/web-reader` already contains a different web project.
- Dependency download fails.
- Any command would modify files outside `apps/web-reader/**`.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

