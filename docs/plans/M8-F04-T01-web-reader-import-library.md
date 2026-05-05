# M8-F04-T01 Web Reader Import Library

## Task ID

`M8-F04-T01`

## Title

Implement web reader import flow and library page.

## Goal

Allow a signed-in web user to choose a local TXT or EPUB file, parse it in the browser, store chapters in IndexedDB, and see the book in Library.

## Scope

This task only does:

- Add browser import service.
- Add Library store.
- Add Library page and import control.
- Store local book metadata, chapters, initial reading position, and pending metadata sync event.
- Add component and service tests.

This task does not:

- Add Reader page.
- Call live backend sync.
- Add lookup or translation.
- Upload original file or chapter content.

## Allowed Files

- `apps/web-reader/services/bookImportService.ts`
- `apps/web-reader/stores/library.ts`
- `apps/web-reader/pages/library.vue`
- `apps/web-reader/components/library/BookImportButton.vue`
- `apps/web-reader/components/library/BookList.vue`
- `apps/web-reader/repositories/bookRepository.ts`
- `apps/web-reader/repositories/chapterRepository.ts`
- `apps/web-reader/repositories/readingPositionRepository.ts`
- `apps/web-reader/repositories/pendingSyncRepository.ts`
- `apps/web-reader/tests/import/book-import-service.test.ts`
- `apps/web-reader/tests/library/library-page.test.ts`

## Forbidden Files

- `apps/web-reader/pages/reader/**`
- `apps/web-reader/components/reader/**`
- `apps/web-reader/services/syncWorker.ts`
- `apps/web-reader/stores/reader.ts`
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
- `apps/web-reader/parsers/txtParser.ts`
- `apps/web-reader/parsers/epubParser.ts`
- `apps/web-reader/repositories/bookRepository.ts`
- `apps/web-reader/pages/library.vue`

## Tests First

Create:

- `apps/web-reader/tests/import/book-import-service.test.ts`
- `apps/web-reader/tests/library/library-page.test.ts`

Test behavior:

- Importing a TXT file stores one `web_books` row, parsed `web_chapters` rows, and one `web_reading_positions` row.
- Importing an EPUB file uses the EPUB parser.
- Re-importing the same owner and fingerprint updates metadata without duplicating the book.
- Pending `book_metadata` sync event contains fingerprint, title, author, file type, language pair, and chapter count.
- Pending sync payload does not contain chapter content, original file name, file bytes, or translated text.
- Library empty state explains that books stay in this browser.
- Imported list item shows title, author when present, file type, and sync status.
- Clicking a book routes to `/reader/{localBookId}`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/import/book-import-service.test.ts tests/library/library-page.test.ts
```

Expected red result:

- Tests fail because import service or Library UI behavior does not exist.

## Implementation Steps

- [ ] Step 1: Write import service and Library page tests.
- [ ] Step 2: Run red tests and confirm missing import behavior.
- [ ] Step 3: Create `bookImportService` that accepts browser `File` and current user id.
- [ ] Step 4: Calculate file fingerprint and choose TXT or EPUB parser by file type.
- [ ] Step 5: Insert or update `web_books` for owner and fingerprint.
- [ ] Step 6: Replace chapters for that book in IndexedDB.
- [ ] Step 7: Create initial reading position at chapter 0, paragraph 0, char offset 0 when missing.
- [ ] Step 8: Enqueue `book_metadata` pending sync event with metadata only.
- [ ] Step 9: Create Library store that lists current user's books.
- [ ] Step 10: Create import button and book list components.
- [ ] Step 11: Update Library page with empty, loading, list, and error states.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm run test -- tests/import/book-import-service.test.ts tests/library/library-page.test.ts
npm run typecheck
```

## Acceptance Criteria

- Import and Library tests pass.
- Browser stores parsed chapters in IndexedDB.
- Library shows local imported books.
- Original file and chapter content are not included in sync payloads.
- No Reader page or live sync worker is added.

## Stop Conditions

- IndexedDB foundation is incomplete.
- TXT or EPUB parser task is incomplete.
- File input tests cannot use fake browser `File`.
- Any file outside Allowed Files must be modified.
- Any implementation uploads or logs book content.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

