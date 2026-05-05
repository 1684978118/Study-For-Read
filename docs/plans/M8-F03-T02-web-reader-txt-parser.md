# M8-F03-T02 Web Reader TXT Parser

## Task ID

`M8-F03-T02`

## Title

Implement browser TXT parser.

## Goal

Parse UTF-8 TXT browser files into normalized book metadata, chapters, and paragraphs for local web reading.

## Scope

This task only does:

- Add shared parsed book types.
- Add TXT parser for browser `File`.
- Add parser tests.

This task does not:

- Parse EPUB.
- Store IndexedDB rows.
- Add UI.
- Upload text to backend.

## Allowed Files

- `apps/web-reader/parsers/parsedBook.ts`
- `apps/web-reader/parsers/txtParser.ts`
- `apps/web-reader/tests/parsers/txt-parser.test.ts`

## Forbidden Files

- `apps/web-reader/parsers/epubParser.ts`
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

- `apps/web-reader/tests/parsers/txt-parser.test.ts`

Test behavior:

- UTF-8 TXT without BOM parses successfully.
- UTF-8 TXT with BOM removes the BOM from the first chapter text.
- Common headings such as `第1章`, `第一章`, `Chapter 1`, and `序章` split chapters.
- TXT without headings becomes one chapter.
- Blank-line groups become paragraphs.
- Empty or whitespace-only TXT returns a typed import failure.
- Invalid UTF-8 bytes return a typed import failure instead of garbled text.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/parsers/txt-parser.test.ts
```

Expected red result:

- Test fails because TXT parser and parsed book types do not exist.

## Implementation Steps

- [ ] Step 1: Write TXT parser tests.
- [ ] Step 2: Run red test and confirm missing module failures.
- [ ] Step 3: Create `ParsedBook`, `ParsedChapter`, and typed parse failure types.
- [ ] Step 4: Create `parseTxtFile`.
- [ ] Step 5: Decode UTF-8 and UTF-8 BOM.
- [ ] Step 6: Reject invalid UTF-8 and empty content with typed failures.
- [ ] Step 7: Split chapters using the heading rules from tests.
- [ ] Step 8: Split paragraphs by blank-line groups and normalize CRLF to LF.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/parsers/txt-parser.test.ts
npm run typecheck
```

## Acceptance Criteria

- TXT parser tests pass.
- Parser output matches `WEB_READER_LOCAL_DATA.md`.
- Unsupported encoding does not produce garbled text.
- Parser does not call backend APIs.
- Parser does not write IndexedDB rows.

## Stop Conditions

- Product requires Shift-JIS support inside this task.
- Parser needs dependencies not already in `package.json`.
- Any file outside Allowed Files must be modified.
- Any implementation logs full chapter content.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

