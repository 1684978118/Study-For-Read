# M10-F02-T01 Server Container Build

## Task ID

`M10-F02-T01`

## Title

Add Spring Boot server container build.

## Goal

Build the Spring Boot API as a production container image with safe runtime defaults.

## Scope

This task only does:

- Add server Dockerfile.
- Add server `.dockerignore`.
- Add container build documentation.
- Add verification command for building the image.

This task does not:

- Add Docker Compose.
- Add Nginx.
- Add PostgreSQL backup.
- Add web app container builds.

## Allowed Files

- `server/Dockerfile`
- `server/.dockerignore`
- `server/README_DEPLOYMENT.md`
- `docs/plans/M10-F02-T01-server-container-build.md`

## Forbidden Files

- `server/src/**`
- `server/pom.xml`
- `server/build.gradle`
- `infra/**`
- `apps/**`
- `.env`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `server/pom.xml` or existing server build file.

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone\server"
Test-Path "pom.xml"
Test-Path "mvnw.cmd"
```

Expected result:

- Server build tool files exist.

If server build files do not exist, stop and report that M1 implementation is incomplete.

## Implementation Steps

- [x] Step 1: Confirm server build tool and Java version.
- [x] Step 2: Create multi-stage `server/Dockerfile`.
- [x] Step 3: Configure runtime stage to use a non-root user when feasible.
- [x] Step 4: Set JVM memory defaults suitable for a 4GB server.
- [x] Step 5: Create `server/.dockerignore`.
- [x] Step 6: Add `server/README_DEPLOYMENT.md` with build and run examples using placeholder env vars.
- [x] Step 7: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
docker build -t study-for-read-api:local .\server
```

## Acceptance Criteria

- Server image builds.
- Dockerfile does not copy `.env`, test reports, local IDE files, or secrets.
- Runtime config reads environment variables.
- No source code behavior is changed.

## Stop Conditions

- M1 server project is incomplete.
- Docker is unavailable.
- Build requires modifying server source or dependency files.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
