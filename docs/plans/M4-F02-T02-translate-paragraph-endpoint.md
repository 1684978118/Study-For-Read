# M4-F02-T02 Translate Paragraph Endpoint

## Task ID

`M4-F02-T02`

## Title

Implement paragraph translation endpoint.

## Goal

Allow an authenticated user to translate one selected paragraph through the backend provider abstraction without storing raw paragraph text.

## Scope

This task only does:

- Add paragraph translation request and response DTOs.
- Add study service paragraph translation behavior.
- Add `POST /api/v1/study/translate-paragraph`.
- Log a minimal `paragraph_translation` translation event.
- Add endpoint tests for success, provider unavailable, text length limit, auth required, and no raw paragraph persistence.

This task does not:

- Add full-book translation.
- Add translation cache storing raw text.
- Add payment or quota.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/study/StudyController.java`
- `server/src/main/java/com/studyforread/server/study/StudyService.java`
- `server/src/main/java/com/studyforread/server/study/dto/TranslateParagraphRequest.java`
- `server/src/main/java/com/studyforread/server/study/dto/TranslateParagraphResponse.java`
- `server/src/test/java/com/studyforread/server/study/TranslateParagraphEndpointTest.java`

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
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/study/TranslationEventRepository.java`
- `server/src/main/java/com/studyforread/server/study/provider/StudyProviderRouter.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/study/TranslateParagraphEndpointTest.java`

Test behavior:

- Authenticated user can translate one paragraph and receives translated text and provider.
- Empty text returns `VALIDATION_ERROR`.
- Text above configured limit returns `TRANSLATION_TEXT_TOO_LONG`.
- Unsupported language pair returns `TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR`.
- Provider failure returns `TRANSLATION_PROVIDER_UNAVAILABLE`.
- Translation event stores hash and length only.
- No table or response includes raw paragraph in persisted event data.
- Endpoint does not accept arrays of paragraphs or full book content.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TranslateParagraphEndpointTest test
```

Expected red result:

- Test fails because paragraph translation endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `TranslateParagraphEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `TranslateParagraphRequest` with `text`, `sourceLang`, and `targetLang`.
- [ ] Step 4: Create `TranslateParagraphResponse` matching API contract.
- [ ] Step 5: Add a small constant text length limit inside `StudyService` for first release if no configuration exists.
- [ ] Step 6: Reject array/full-book style payloads by accepting only one string field named `text`.
- [ ] Step 7: Call provider router for paragraph translation.
- [ ] Step 8: Write `translation_events` row with `request_type=paragraph_translation`, hash, length, provider, success, and error code only.
- [ ] Step 9: Add `StudyController.translateParagraph`.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TranslateParagraphEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/study/translate-paragraph`.
- Endpoint requires user auth.
- Only one paragraph string is accepted.
- Raw paragraph and translated paragraph are not persisted in `translation_events`.
- Full-book translation is not implemented.

## Stop Conditions

- Translation event persistence is incomplete.
- Provider abstraction is incomplete.
- Adding configuration requires modifying files outside Allowed Files.
- Any implementation stores raw paragraph or translated paragraph.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

