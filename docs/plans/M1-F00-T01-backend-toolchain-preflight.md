# M1-F00-T01 Backend Toolchain Preflight

## Task ID

`M1-F00-T01`

## Title

Verify local backend toolchain before creating the Spring Boot server project.

## Goal

Confirm this machine is ready to run the backend skeleton task with Java 25 LTS and Maven wrapper before any server code is created.

## Scope

This task only does:

- Confirm current directory is `D:\Codex\Study For Read Phone`.
- Confirm Git is available and the worktree state is known.
- Confirm active `java` is JDK 25.
- Confirm `JAVA_HOME`, if set, points to a JDK 25 installation.
- Confirm no `server` business code already exists.
- Report blockers clearly.

This task does not:

- Create the `server` project.
- Install or download JDK.
- Modify environment variables.
- Modify application code.
- Modify docs, specs, or task cards.

## Allowed Files

This task may create or modify no files.

## Forbidden Files

This task must not modify:

- `server/**`
- `apps/**`
- `infra/**`
- `docs/**`
- `AGENTS.md`
- `.gitignore`
- Any old project path under `D:\Codex\Study for Read`
- Any file in this repository

## Read First

- `AGENTS.md`
- `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`
- `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`
- `docs/plans/IMPLEMENTATION_START_GATE.md`
- `docs/plans/M1_BACKEND_FOUNDATION.md`
- `docs/specs/ARCHITECTURE.md`

## Tests First

This is an environment preflight task, so there is no application test to write.

Run:

```powershell
cd "D:\Codex\Study For Read Phone"
git status --short
$env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
$env:Path = (Join-Path $env:JAVA_HOME "bin") + ";" + $env:Path
java -version
$env:JAVA_HOME
where.exe java
Test-Path "D:\Codex\Study For Read Phone\server"
```

Expected result:

- `git status --short` runs successfully.
- `java -version` reports major version `25`.
- `$env:JAVA_HOME` points to a JDK 25 directory.
- `where.exe java` lists the intended JDK 25 `bin\java.exe` first.
- `Test-Path "D:\Codex\Study For Read Phone\server"` is `False`, or the existing `server` directory is empty and contains no business code.

## Implementation Steps

- [ ] Step 1: Read all `Read First` files.
- [ ] Step 2: Run `git status --short`.
- [ ] Step 3: Activate user-level JDK 25 for this PowerShell session by setting `$env:JAVA_HOME` from the user environment and prepending `$env:JAVA_HOME\bin` to `$env:Path`.
- [ ] Step 4: Run `java -version`.
- [ ] Step 5: Print `$env:JAVA_HOME`.
- [ ] Step 6: Run `where.exe java`.
- [ ] Step 7: Check whether `D:\Codex\Study For Read Phone\server` exists.
- [ ] Step 8: If active Java is not JDK 25 after activation, stop and report the exact active Java version and `JAVA_HOME`.
- [ ] Step 9: If JDK 25 is active and no conflicting `server` code exists, recommend `M1-F01-T01-server-project-skeleton.md`.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
git status --short
$env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
$env:Path = (Join-Path $env:JAVA_HOME "bin") + ";" + $env:Path
java -version
$env:JAVA_HOME
where.exe java
Test-Path "D:\Codex\Study For Read Phone\server"
```

## Acceptance Criteria

- Worktree state is reported.
- Active Java version is reported.
- `JAVA_HOME` is reported.
- Java executable path is reported.
- Existing `server` path state is reported.
- No files are modified.
- If Java 25 is unavailable, the task ends as blocked and does not proceed to coding.

## Stop Conditions

- Current directory is not `D:\Codex\Study For Read Phone`.
- Git is unavailable.
- Active Java is not JDK 25.
- `JAVA_HOME` points to Java 8, 11, 17, or 21.
- `server` already contains conflicting business code.
- Any command would create, modify, move, or delete files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files: `none`.
- Verification commands.
- Verification result.
- Blockers.
- Recommended next task card.
