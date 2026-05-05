# M6-F04-T03 Mobile EPUB Parser

## Task ID

`M6-F04-T03`

## Title

Implement local EPUB parser foundation.

## Goal

Parse a simple EPUB file locally into normalized metadata, spine-ordered chapters, and readable text.

## Scope

This task only does:

- Add EPUB parser.
- Add parser tests using minimal generated EPUB fixtures.
- Extract title, author, spine order, chapter titles, text, and paragraphs.

This task does not:

- Render EPUB CSS.
- Load remote EPUB resources.
- Extract images.
- Add UI.
- Insert database rows.
- Upload text to backend.

## Allowed Files

- `apps/mobile/lib/src/features/library/data/epub_book_parser.dart`
- `apps/mobile/lib/src/features/library/data/book_parse_result.dart`
- `apps/mobile/test/src/features/library/epub_book_parser_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/library/data/txt_book_parser.dart`
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
- `apps/mobile/lib/src/features/library/data/book_parse_result.dart`
- `apps/mobile/pubspec.yaml`

## Tests First

Create:

- `apps/mobile/test/src/features/library/epub_book_parser_test.dart`

Test behavior:

- Minimal EPUB with `META-INF/container.xml`, OPF package file, manifest, spine, and XHTML chapter parses successfully.
- Title is read from package metadata when present.
- Author is read from package metadata when present.
- Chapters follow spine order, not zip file order.
- XHTML tags are stripped and visible text remains.
- Empty spine returns a typed import failure.
- Missing container file returns a typed import failure.
- Parser ignores images, CSS, scripts, and remote resources.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/epub_book_parser_test.dart
```

Expected red result:

- Test fails because EPUB parser does not exist.

## Implementation Steps

- [ ] Step 1: Write EPUB parser tests with generated zip fixtures.
- [ ] Step 2: Run red test and confirm missing parser failure.
- [ ] Step 3: Create `EpubBookParser.parseFile`.
- [ ] Step 4: Read `META-INF/container.xml` to find the OPF package path.
- [ ] Step 5: Parse OPF metadata for title and author.
- [ ] Step 6: Resolve manifest hrefs relative to the OPF directory.
- [ ] Step 7: Read spine item order and parse matching XHTML files.
- [ ] Step 8: Strip XHTML tags and normalize whitespace into paragraphs.
- [ ] Step 9: Return typed failures for missing container, missing package, empty spine, or unreadable XHTML.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/library/epub_book_parser_test.dart
flutter analyze
```

## Acceptance Criteria

- EPUB parser tests pass.
- Parser respects EPUB spine order.
- Parser output matches `ParsedBook` and `ParsedChapter`.
- Parser ignores unsupported visual resources.
- Parser does not call backend APIs or write database rows.

## Stop Conditions

- `archive` or `xml` dependency is missing.
- EPUB fixture generation requires writing persistent fixture files outside Allowed Files.
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

