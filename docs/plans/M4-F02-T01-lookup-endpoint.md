# M4-F02-T01 Lookup Endpoint

## Task ID

`M4-F02-T01`

## Title

Implement public lexeme first lookup endpoint.

## Goal

Allow an authenticated user to look up a word, phrase, or idiom, preferring public lexemes before provider fallback.

## Scope

This task only does:

- Add lookup request and response DTOs.
- Add study service lookup behavior.
- Add `POST /api/v1/study/lookup`.
- Log a minimal `word_lookup` translation event.
- Add endpoint tests for lexeme hit, provider fallback, unsupported language, auth required, and no raw context persistence.

This task does not:

- Add paragraph translation endpoint.
- Add annotation endpoint.
- Create public lexemes from provider results.
- Create user word cards.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/study/StudyController.java`
- `server/src/main/java/com/studyforread/server/study/StudyService.java`
- `server/src/main/java/com/studyforread/server/study/dto/LookupRequest.java`
- `server/src/main/java/com/studyforread/server/study/dto/LookupResponse.java`
- `server/src/main/java/com/studyforread/server/study/dto/LexemeLookupResponse.java`
- `server/src/test/java/com/studyforread/server/study/LookupEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/main/java/com/studyforread/server/study/provider/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/main/java/com/studyforread/server/study/TranslationEventRepository.java`
- `server/src/main/java/com/studyforread/server/study/provider/StudyProviderRouter.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/study/LookupEndpointTest.java`

Test behavior:

- Existing active public lexeme returns `provider=public_lexeme`.
- If no lexeme exists, service uses provider router fallback.
- Unsupported language pair returns `TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR`.
- Unauthenticated request returns `UNAUTHORIZED`.
- `context` is not stored in `translation_events`; only hash and length are stored.
- Empty text returns `VALIDATION_ERROR`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=LookupEndpointTest test
```

Expected red result:

- Test fails because lookup endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `LookupEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `LookupRequest` with `text`, `sourceLang`, `targetLang`, and optional `context`.
- [ ] Step 4: Create lookup response DTOs matching API contract.
- [ ] Step 5: Add `StudyService.lookup`.
- [ ] Step 6: Normalize lookup text using `lower(trim(text))` for public lexeme lookup.
- [ ] Step 7: If active lexeme exists, return it with provider `public_lexeme`.
- [ ] Step 8: If no lexeme exists, call provider router.
- [ ] Step 9: Write `translation_events` row with `request_type=word_lookup`, `source_text_hash`, `source_text_length`, provider, success, and error code only.
- [ ] Step 10: Add `StudyController.lookup` at `POST /api/v1/study/lookup`.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=LookupEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/study/lookup`.
- Endpoint requires user auth.
- Public lexeme hit is preferred.
- Raw text and context are not persisted.
- No vocabulary card is created.

## Stop Conditions

- M3 lexeme persistence is incomplete.
- Translation event persistence is incomplete.
- Provider abstraction is incomplete.
- Any file outside Allowed Files must be modified.
- Any implementation stores raw lookup text or context.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

