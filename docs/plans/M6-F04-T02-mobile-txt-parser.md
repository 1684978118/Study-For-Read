# M6-F04-T02 Mobile TXT Parser

## Task ID

`M6-F04-T02`

## Title

Implement local TXT book parser.

## Goal

Parse UTF-8 TXT files into normalized book metadata, chapters, and paragraphs for local reading.

## Scope

This task only does:

- Add shared parsed book models.
- Add TXT parser.
- Add parser tests for UTF-8, UTF-8 BOM, chapter detection, paragraph splitting, and fallback behavior.

This task does not:

- Parse EPUB.
- Copy files.
- Insert database rows.
- Add UI.
- Upload text to backend.

## Allowed Files

- `apps/mobile/lib/src/features/library/data/book_parse_result.dart`
- `apps/mobile/lib/src/features/library/data/txt_book_parser.dart`
- `apps/mobile/test/src/features/library/txt_book_parser_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/library/data/epub_book_parser.dart`
- `apps/mobile/lib/src/core/database/**`
- `apps/mobile/lib/src/features/library/presentation/**`
- `apps/mobile/lib/src/features/reader/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`

## Tests First

Create:

- `apps/mobile/test/src/features/library/txt_book_parser_test.dart`

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
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/txt_book_parser_test.dart
```

Expected red result:

- Test fails because TXT parser and parsed book models do not exist.

## Implementation Steps

- [ ] Step 1: Write TXT parser tests.
- [ ] Step 2: Run red test and confirm missing class failures.
- [ ] Step 3: Create `ParsedBook`, `ParsedChapter`, and typed parse failure classes in `book_parse_result.dart`.
- [ ] Step 4: Create `TxtBookParser.parseFile`.
- [ ] Step 5: Decode UTF-8 and UTF-8 BOM.
- [ ] Step 6: Reject invalid UTF-8 and empty content with typed failures.
- [ ] Step 7: Split chapters using the heading rules from tests.
- [ ] Step 8: Split paragraphs by blank-line groups and normalize CRLF to LF.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/txt_book_parser_test.dart
flutter analyze
```

## Acceptance Criteria

- TXT parser tests pass.
- Parser output matches `MOBILE_LOCAL_DATA.md`.
- Unsupported encoding does not produce garbled text.
- Parser does not call backend APIs.
- Parser does not write database rows.

## Stop Conditions

- Product requires Shift-JIS support inside this task.
- Parser needs dependencies not already in `pubspec.yaml`.
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
