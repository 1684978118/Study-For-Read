# M8-F03-T03 Web Reader EPUB Parser

## Task ID

`M8-F03-T03`

## Title

Implement browser EPUB parser foundation.

## Goal

Parse a simple EPUB browser file into normalized metadata, spine-ordered chapters, and readable text.

## Scope

This task only does:

- Add EPUB parser.
- Add parser tests using generated in-memory EPUB fixtures.
- Extract title, author, spine order, chapter titles, text, and paragraphs.

This task does not:

- Render EPUB CSS.
- Load remote EPUB resources.
- Extract images.
- Add UI.
- Store IndexedDB rows.
- Upload text to backend.

## Allowed Files

- `apps/web-reader/parsers/epubParser.ts`
- `apps/web-reader/parsers/parsedBook.ts`
- `apps/web-reader/tests/parsers/epub-parser.test.ts`

## Forbidden Files

- `apps/web-reader/parsers/txtParser.ts`
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
- `apps/web-reader/parsers/parsedBook.ts`
- `apps/web-reader/package.json`

## Tests First

Create:

- `apps/web-reader/tests/parsers/epub-parser.test.ts`

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
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/parsers/epub-parser.test.ts
```

Expected red result:

- Test fails because EPUB parser does not exist.

## Implementation Steps

- [ ] Step 1: Write EPUB parser tests with generated in-memory zip fixtures.
- [ ] Step 2: Run red test and confirm missing parser failure.
- [ ] Step 3: Create `parseEpubFile`.
- [ ] Step 4: Read `META-INF/container.xml` to find the OPF package path.
- [ ] Step 5: Parse OPF metadata for title and author.
- [ ] Step 6: Resolve manifest hrefs relative to the OPF directory.
- [ ] Step 7: Read spine item order and parse matching XHTML files.
- [ ] Step 8: Strip XHTML tags and normalize whitespace into paragraphs.
- [ ] Step 9: Return typed failures for missing container, missing package, empty spine, or unreadable XHTML.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/parsers/epub-parser.test.ts
npm run typecheck
```

## Acceptance Criteria

- EPUB parser tests pass.
- Parser respects EPUB spine order.
- Parser output matches `ParsedBook` and `ParsedChapter`.
- Parser ignores unsupported visual resources.
- Parser does not call backend APIs or write IndexedDB rows.

## Stop Conditions

- `jszip` or `fast-xml-parser` dependency is missing.
- EPUB fixture generation requires persistent files outside Allowed Files.
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

