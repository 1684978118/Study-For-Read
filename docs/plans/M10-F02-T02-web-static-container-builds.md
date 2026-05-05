# M10-F02-T02 Web Static Container Builds

## Task ID

`M10-F02-T02`

## Title

Add Web Reader and Web Admin static build packaging.

## Goal

Build Web Reader and Web Admin as static assets that can be served by Nginx in the first deployment.

## Scope

This task only does:

- Add web deployment documentation.
- Add build scripts or config needed for static output.
- Add `.dockerignore` files if needed.
- Add verification commands for static builds.

This task does not:

- Add Nginx routing.
- Add Docker Compose.
- Add backend code.
- Add SSR Node runtime containers.

## Allowed Files

- `apps/web-reader/README_DEPLOYMENT.md`
- `apps/web-reader/.dockerignore`
- `apps/web-reader/nuxt.config.ts`
- `apps/web-reader/package.json`
- `apps/web-admin/README_DEPLOYMENT.md`
- `apps/web-admin/.dockerignore`
- `apps/web-admin/nuxt.config.ts`
- `apps/web-admin/package.json`
- `docs/plans/M10-F02-T02-web-static-container-builds.md`

## Forbidden Files

- `apps/web-reader/pages/**`
- `apps/web-reader/components/**`
- `apps/web-reader/stores/**`
- `apps/web-admin/pages/**`
- `apps/web-admin/components/**`
- `apps/web-admin/stores/**`
- `server/**`
- `infra/docker-compose.yml`
- `infra/nginx/**`
- `.env`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `apps/web-reader/package.json`
- `apps/web-reader/nuxt.config.ts`
- `apps/web-admin/package.json`
- `apps/web-admin/nuxt.config.ts`

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "apps\web-reader\package.json"
Test-Path "apps\web-admin\package.json"
```

Expected result:

- Both web app package files exist.

If either app is missing, stop and report the relevant prior milestone is incomplete.

## Implementation Steps

- [ ] Step 1: Confirm Web Reader and Web Admin package scripts.
- [ ] Step 2: Configure Web Reader for first-release static output if needed.
- [ ] Step 3: Configure Web Admin for first-release static output if needed.
- [ ] Step 4: Ensure public API base URLs are read from runtime-safe public config.
- [ ] Step 5: Add or update `.dockerignore` files to exclude node modules, local env files, test output, and secrets.
- [ ] Step 6: Add deployment READMEs for both web apps.
- [ ] Step 7: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run build
npm run typecheck
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run build
npm run typecheck
```

## Acceptance Criteria

- Web Reader static build succeeds.
- Web Admin static build succeeds.
- Public API base URLs remain configurable.
- Web build artifacts do not include real secrets.
- No page or business logic is changed.

## Stop Conditions

- M8 or M9 web app skeleton is incomplete.
- Static output requires changing app routing behavior outside Allowed Files.
- Build requires live backend.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

