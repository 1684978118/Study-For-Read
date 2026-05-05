# M4-F01-T02 Provider Abstraction

## Task ID

`M4-F01-T02`

## Title

Create provider abstraction for lookup, translation, and annotation.

## Goal

Create testable provider interfaces and a local fallback implementation without adding real external provider credentials.

## Scope

This task only does:

- Add provider interfaces.
- Add result models for lookup, paragraph translation, and annotation.
- Add a local fallback provider for deterministic tests.
- Add unit tests for provider routing behavior.

This task does not:

- Add HTTP clients for Baidu, DeepL, or other real providers.
- Add API endpoints.
- Store translation events.
- Add secrets or `.env` values.

## Allowed Files

- `server/src/main/java/com/studyforread/server/study/provider/StudyProvider.java`
- `server/src/main/java/com/studyforread/server/study/provider/LookupProviderResult.java`
- `server/src/main/java/com/studyforread/server/study/provider/ParagraphTranslationResult.java`
- `server/src/main/java/com/studyforread/server/study/provider/AnnotationTokenResult.java`
- `server/src/main/java/com/studyforread/server/study/provider/AnnotationResult.java`
- `server/src/main/java/com/studyforread/server/study/provider/LocalFallbackStudyProvider.java`
- `server/src/main/java/com/studyforread/server/study/provider/StudyProviderRouter.java`
- `server/src/test/java/com/studyforread/server/study/provider/StudyProviderRouterTest.java`

## Forbidden Files

- `server/src/main/resources/application.yml`
- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/study/*Controller.java`
- `server/src/main/java/com/studyforread/server/study/*Service.java`
- `server/src/main/java/com/studyforread/server/vocabulary/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/ARCHITECTURE.md`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/study/provider/StudyProviderRouterTest.java`

Test behavior:

- Router can return a lookup result from the local fallback provider.
- Router can return a paragraph translation result from the local fallback provider.
- Router can return annotation tokens from the local fallback provider.
- No provider stores source text internally after method return.
- Provider result includes provider name.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudyProviderRouterTest test
```

Expected red result:

- Test fails because provider classes do not exist.

## Implementation Steps

- [ ] Step 1: Write `StudyProviderRouterTest`.
- [ ] Step 2: Run red test and confirm missing provider classes.
- [ ] Step 3: Create `StudyProvider` interface with methods for lookup, translate paragraph, and annotate.
- [ ] Step 4: Create immutable result models.
- [ ] Step 5: Create `LocalFallbackStudyProvider` with deterministic placeholder behavior for tests only.
- [ ] Step 6: Create `StudyProviderRouter` that delegates to configured provider list, initially local fallback only.
- [ ] Step 7: Do not add real provider API keys or outbound HTTP.
- [ ] Step 8: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudyProviderRouterTest test
```

## Acceptance Criteria

- Provider tests pass.
- No real secrets are added.
- No endpoint is created.
- No raw text is persisted by providers.

## Stop Conditions

- A real provider dependency is required.
- Implementing this requires modifying config or migrations.
- Any file outside Allowed Files must be modified.
- Any implementation adds secrets or real API keys.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

