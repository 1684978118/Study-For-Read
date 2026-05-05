# M4-F03-T01 Translation Compliance Regression

## Task ID

`M4-F03-T01`

## Title

Add translation compliance regression tests.

## Goal

Protect the rule that lookup, translation, and annotation do not persist raw source text or translated paragraphs.

## Scope

This task only does:

- Add compliance tests across `translation_events` and study APIs.
- Verify raw text columns are absent.
- Verify endpoints log hash and length only.
- Verify full-book translation is not available.

This task does not:

- Add new production endpoints.
- Add real translation providers.
- Add billing.
- Add mobile code.

## Allowed Files

- `server/src/test/java/com/studyforread/server/study/TranslationComplianceRegressionTest.java`
- If and only if tests expose a compliance failure, these files may be modified:
  - `server/src/main/java/com/studyforread/server/study/StudyController.java`
  - `server/src/main/java/com/studyforread/server/study/StudyService.java`
  - `server/src/main/java/com/studyforread/server/study/dto/LookupRequest.java`
  - `server/src/main/java/com/studyforread/server/study/dto/TranslateParagraphRequest.java`
  - `server/src/main/java/com/studyforread/server/study/dto/AnnotateRequest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/study/TranslationEvent.java`
- `server/src/main/java/com/studyforread/server/study/TranslationEventRepository.java`
- `server/src/main/java/com/studyforread/server/study/provider/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- All M4 task cards.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/study/TranslationComplianceRegressionTest.java`

Test behavior:

- `translation_events` has no columns named `source_text`, `raw_text`, `translated_text`, `paragraph_text`, `chapter_content`, or `book_content`.
- Lookup logs only `source_text_hash`, `source_text_length`, request type, provider, success, and error code.
- Paragraph translation logs only `source_text_hash`, `source_text_length`, request type, provider, success, and error code.
- Annotation logs only `source_text_hash`, `source_text_length`, request type, provider, success, and error code.
- No route exists for `/api/v1/study/translate-book`.
- No route exists for `/api/v1/study/translate-chapter` in first release.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TranslationComplianceRegressionTest test
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual compliance gap.

## Implementation Steps

- [ ] Step 1: Write `TranslationComplianceRegressionTest`.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to raw text persistence or forbidden full-book routes, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M4 study tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TranslationComplianceRegressionTest test
.\mvnw.cmd -Dtest=TranslationEventRepositoryTest,StudyProviderRouterTest,LookupEndpointTest,TranslateParagraphEndpointTest,AnnotateEndpointTest,TranslationComplianceRegressionTest test
```

## Acceptance Criteria

- Compliance regression test passes.
- All M4 tests pass.
- No raw text or translated text is persisted.
- Full-book and full-chapter translation routes do not exist.

## Stop Conditions

- M4 endpoint tasks are incomplete.
- Compliance failure requires migration changes.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

