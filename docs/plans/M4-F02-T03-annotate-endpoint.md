# M4-F02-T03 Annotate Endpoint

## Task ID

`M4-F02-T03`

## Title

Implement basic annotation endpoint.

## Goal

Allow an authenticated user to request basic reading annotation tokens for one text snippet.

## Scope

This task only does:

- Add annotation request and response DTOs.
- Add study service annotation behavior.
- Add `POST /api/v1/study/annotate`.
- Log a minimal `annotation` translation event.
- Add endpoint tests for token shape, auth required, unsupported language, and no raw text persistence.

This task does not:

- Add full morphological analyzer integration.
- Add offline annotation.
- Add mobile ruby rendering.
- Add translation endpoint.

## Allowed Files

- `server/src/main/java/com/studyforread/server/study/StudyController.java`
- `server/src/main/java/com/studyforread/server/study/StudyService.java`
- `server/src/main/java/com/studyforread/server/study/dto/AnnotateRequest.java`
- `server/src/main/java/com/studyforread/server/study/dto/AnnotateResponse.java`
- `server/src/main/java/com/studyforread/server/study/dto/AnnotatedTokenResponse.java`
- `server/src/test/java/com/studyforread/server/study/AnnotateEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/resources/application.yml`
- `server/src/main/java/com/studyforread/server/study/provider/**`
- `server/src/main/java/com/studyforread/server/vocabulary/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/study/TranslationEventRepository.java`
- `server/src/main/java/com/studyforread/server/study/provider/StudyProviderRouter.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/study/AnnotateEndpointTest.java`

Test behavior:

- Authenticated user can annotate a short Japanese text and receives token objects.
- Empty text returns `VALIDATION_ERROR`.
- Unsupported source language returns `TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR`.
- Annotation event stores hash and length only.
- Response token fields are `text`, `reading`, `dictionaryForm`, and `partOfSpeech`.
- Unauthenticated request returns `UNAUTHORIZED`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AnnotateEndpointTest test
```

Expected red result:

- Test fails because annotation endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `AnnotateEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `AnnotateRequest` with `text` and `sourceLang`.
- [ ] Step 4: Create `AnnotatedTokenResponse`.
- [ ] Step 5: Create `AnnotateResponse` with `tokens`.
- [ ] Step 6: Add `StudyService.annotate`.
- [ ] Step 7: Call provider router for annotation.
- [ ] Step 8: Write `translation_events` row with `request_type=annotation`, hash, length, provider, success, and error code only.
- [ ] Step 9: Add `StudyController.annotate`.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AnnotateEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/study/annotate`.
- Endpoint requires user auth.
- Response shape matches API contract.
- Raw annotation text is not persisted.
- No advanced analyzer dependency is introduced.

## Stop Conditions

- Translation event persistence is incomplete.
- Provider abstraction is incomplete.
- Any file outside Allowed Files must be modified.
- Implementing this requires adding a third-party analyzer dependency.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

