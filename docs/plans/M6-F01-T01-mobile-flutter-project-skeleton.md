# M6-F01-T01 Mobile Flutter Project Skeleton

## Task ID

`M6-F01-T01`

## Title

Create Flutter mobile project skeleton.

## Goal

Create the first Flutter app under `apps/mobile` with baseline dependencies, analysis, and test commands working.

## Scope

This task only does:

- Create the Flutter app skeleton.
- Add approved first-release dependencies.
- Verify `flutter test` and `flutter analyze`.

This task does not:

- Add feature UI.
- Add API calls.
- Add local database schema.
- Add file import logic.
- Modify backend, web, or infra files.

## Allowed Files

- `apps/mobile/**`

## Forbidden Files

- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- `docs/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file outside `apps/mobile/**`

## Read First

- `AGENTS.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`

## Tests First

This skeleton task cannot write a red Flutter test before the Flutter project exists.

Before implementation, run:

```powershell
flutter --version
```

Expected result:

- Flutter is installed and reports a usable SDK.

If Flutter is missing, stop and report the blocker.

## Implementation Steps

- [ ] Step 1: Confirm `apps/mobile/pubspec.yaml` does not already exist. If it exists, stop and report that the app skeleton already exists.
- [ ] Step 2: Create the Flutter project in `apps/mobile` using package name `study_for_read_mobile` and org `com.studyforread`.
- [ ] Step 3: Add runtime dependencies: `go_router`, `flutter_riverpod`, `dio`, `flutter_secure_storage`, `sqflite`, `path_provider`, `path`, `file_picker`, `crypto`, `archive`, and `xml`.
- [ ] Step 4: Add test dependency `sqflite_common_ffi`.
- [ ] Step 5: Keep generated Android and iOS folders inside `apps/mobile`.
- [ ] Step 6: Run `flutter test`.
- [ ] Step 7: Run `flutter analyze`.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test
flutter analyze
```

## Acceptance Criteria

- `apps/mobile/pubspec.yaml` exists.
- `apps/mobile/lib/main.dart` exists.
- Android and iOS Flutter project files exist under `apps/mobile`.
- Approved dependencies are present in `pubspec.yaml`.
- `flutter test` passes.
- `flutter analyze` passes.

## Stop Conditions

- Flutter SDK is missing.
- `apps/mobile` already contains a different Flutter project.
- Dependency download fails.
- Any command would modify files outside `apps/mobile/**`.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
