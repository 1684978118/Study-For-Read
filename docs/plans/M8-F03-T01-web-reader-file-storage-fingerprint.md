# M8-F03-T01 Web Reader File Storage Fingerprint

## Task ID

`M8-F03-T01`

## Title

Add browser file type detection and fingerprinting.

## Goal

Read browser-selected TXT or EPUB files, validate their type, and calculate stable SHA-256 fingerprints without uploading file content.

## Scope

This task only does:

- Add browser file type detection.
- Add SHA-256 fingerprint service for browser `File` objects.
- Add tests using in-memory `File` instances.

This task does not:

- Parse chapters.
- Store IndexedDB rows.
- Add file input UI.
- Call backend APIs.

## Allowed Files

- `apps/web-reader/utils/bookFileType.ts`
- `apps/web-reader/utils/bookFingerprint.ts`
- `apps/web-reader/types/import.ts`
- `apps/web-reader/tests/import/book-file-type.test.ts`
- `apps/web-reader/tests/import/book-fingerprint.test.ts`

## Forbidden Files

- `apps/web-reader/parsers/**`
- `apps/web-reader/repositories/**`
- `apps/web-reader/pages/**`
- `apps/web-reader/components/**`
- `apps/web-reader/package.json`
- `apps/mobile/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/WEB_READER_LOCAL_DATA.md`
- `docs/specs/UI_FLOWS.md`

## Tests First

Create:

- `apps/web-reader/tests/import/book-file-type.test.ts`
- `apps/web-reader/tests/import/book-fingerprint.test.ts`

Test behavior:

- `.txt` maps to `txt`.
- `.epub` maps to `epub`.
- Unsupported extension returns a typed import failure.
- Fingerprint for known bytes equals expected lowercase SHA-256 hex.
- Fingerprint service returns fingerprint and file metadata only.
- Fingerprint service does not return file text, file bytes, or object URLs.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/import/book-file-type.test.ts tests/import/book-fingerprint.test.ts
```

Expected red result:

- Tests fail because file type and fingerprint utilities do not exist.

## Implementation Steps

- [ ] Step 1: Write file type and fingerprint tests.
- [ ] Step 2: Run red tests and confirm missing module failures.
- [ ] Step 3: Create import types for `txt`, `epub`, and typed failures.
- [ ] Step 4: Create `detectBookFileType`.
- [ ] Step 5: Create `calculateBookFingerprint` using browser crypto APIs or test-compatible equivalent.
- [ ] Step 6: Return lowercase SHA-256 hex and metadata only.
- [ ] Step 7: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/import/book-file-type.test.ts tests/import/book-fingerprint.test.ts
npm run typecheck
```

## Acceptance Criteria

- File type and fingerprint tests pass.
- Only TXT and EPUB are accepted.
- Fingerprint is deterministic lowercase SHA-256 hex.
- No parser, IndexedDB write, UI, or backend call is added.

## Stop Conditions

- Browser `File` test support is unavailable.
- Fingerprint implementation requires adding a dependency.
- Any file outside Allowed Files must be modified.
- Any implementation uploads or logs file content.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

