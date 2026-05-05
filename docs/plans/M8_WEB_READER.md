# M8 Web Reader Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, the web reader specs, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build the Nuxt web reader so a signed-in user can import TXT or EPUB in the browser, read locally, use lookup and paragraph translation, save vocabulary, review cards, view stats, and sync learning data without uploading original books.

## Scope

This milestone does:

- Create `apps/web-reader` Nuxt app.
- Add web auth gate and API client.
- Add IndexedDB stores for browser-local books, chapters, progress, learning data, stats, and pending sync events.
- Add browser TXT and EPUB parser foundations.
- Add browser-local import flow and library page.
- Add reader page with local progress.
- Add lookup, paragraph translation, vocabulary save, review, stats, and sync worker.
- Add privacy regression tests proving no original book content or translated text is synced.

This milestone does not:

- Build web admin.
- Build cloud bookshelf.
- Upload original files or parsed chapters to the backend.
- Add full-book translation.
- Add payment.
- Add social or public discovery features.

## Required Prior Milestones

M1 through M5 define the backend APIs used by the web reader.

M6 and M7 define mobile patterns that the web reader should mirror, but web code must not copy mobile implementation files directly.

Web task tests must use fake HTTP and fake IndexedDB unless a task card explicitly asks for live backend verification.

## Task Order

1. `M8-F01-T01-web-reader-nuxt-skeleton.md`
2. `M8-F01-T02-web-reader-auth-gate.md`
3. `M8-F02-T01-web-reader-indexeddb-foundation.md`
4. `M8-F03-T01-web-reader-file-storage-fingerprint.md`
5. `M8-F03-T02-web-reader-txt-parser.md`
6. `M8-F03-T03-web-reader-epub-parser.md`
7. `M8-F04-T01-web-reader-import-library.md`
8. `M8-F04-T02-web-reader-basic-reader.md`
9. `M8-F05-T01-web-reader-study-vocabulary-flow.md`
10. `M8-F06-T01-web-reader-review-stats-sync.md`
11. `M8-F07-T01-web-reader-privacy-regression.md`

## Milestone Acceptance

Milestone 8 is complete when:

- `apps/web-reader` exists and web tests plus typecheck run.
- Signed-out users see auth screens before reader pages.
- Browser-imported TXT and EPUB files are parsed locally.
- Parsed chapters are stored in IndexedDB only.
- Library and Reader work from browser-local data.
- Lookup and paragraph translation use backend APIs without full chapter or full book upload.
- Vocabulary save and review work from local data and sync through allowed APIs.
- Stats display local counters and sync through `/api/v1/stats/daily`.
- Sync worker never reads `web_chapters.content` or `web_translation_cache.translatedText`.
- Privacy regression tests pass.

