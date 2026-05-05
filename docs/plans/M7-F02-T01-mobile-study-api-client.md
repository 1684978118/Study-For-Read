# M7-F02-T01 Mobile Study API Client

## Task ID

`M7-F02-T01`

## Title

Implement mobile study API client.

## Goal

Add fake-testable mobile API calls for lookup, paragraph translation, and annotation.

## Scope

This task only does:

- Add study DTOs matching `API_CONTRACT.md`.
- Add `StudyApiClient`.
- Add unit tests with fake HTTP.
- Add response parsing for lexeme lookup, paragraph translation, and annotation tokens.

This task does not:

- Add Reader UI.
- Store vocabulary cards.
- Store translation cache.
- Add sync worker.

## Allowed Files

- `apps/mobile/lib/src/features/study/domain/lookup_result.dart`
- `apps/mobile/lib/src/features/study/domain/translation_result.dart`
- `apps/mobile/lib/src/features/study/domain/annotation_token.dart`
- `apps/mobile/lib/src/features/study/data/study_api_client.dart`
- `apps/mobile/lib/src/core/network/api_client.dart`
- `apps/mobile/test/src/features/study/study_api_client_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/study/presentation/**`
- `apps/mobile/lib/src/features/reader/presentation/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/pubspec.yaml`
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
- `apps/mobile/lib/src/core/network/api_client.dart`
- `apps/mobile/lib/src/core/network/api_envelope.dart`
- `apps/mobile/lib/src/core/network/api_error.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/study/study_api_client_test.dart`

Test behavior:

- Lookup sends `POST /api/v1/study/lookup` with `text`, `sourceLang`, `targetLang`, and optional `context`.
- Lookup parses public lexeme result fields.
- Paragraph translation sends `POST /api/v1/study/translate-paragraph` with one string `text`, not an array.
- Paragraph translation parses `translatedText`, `provider`, `cached`, and `message`.
- Annotation sends `POST /api/v1/study/annotate`.
- Unsupported language pair maps `TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR` to a stable mobile error.
- Provider unavailable maps `TRANSLATION_PROVIDER_UNAVAILABLE` to a stable mobile error.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/study_api_client_test.dart
```

Expected red result:

- Test fails because `StudyApiClient` or DTOs do not exist.

## Implementation Steps

- [ ] Step 1: Write `study_api_client_test.dart`.
- [ ] Step 2: Run red test and confirm missing class failures.
- [ ] Step 3: Create `LookupResult`, `TranslationResult`, and `AnnotationToken` domain models.
- [ ] Step 4: Create `StudyApiClient.lookup`.
- [ ] Step 5: Create `StudyApiClient.translateParagraph`.
- [ ] Step 6: Create `StudyApiClient.annotate`.
- [ ] Step 7: Reuse existing API envelope and error parsing.
- [ ] Step 8: Ensure translation request accepts one selected paragraph string only.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/study_api_client_test.dart
flutter analyze
```

## Acceptance Criteria

- Study API client tests pass.
- DTOs match `API_CONTRACT.md`.
- Tests use fake HTTP and do not require a live backend.
- Client does not store raw paragraph text.
- No UI is added in this task.

## Stop Conditions

- M6 auth network client is incomplete.
- API envelope parsing is missing and cannot be changed within Allowed Files.
- Any file outside Allowed Files must be modified.
- Any implementation sends full chapters or full books.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
