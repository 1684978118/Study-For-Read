# M6 Mobile Foundation Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, `docs/specs/UI_FLOWS.md`, `docs/specs/MOBILE_UI_STYLE.md`, the mobile specs, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build the Flutter mobile foundation for login, local book import, local chapter storage, bookshelf display, and basic offline reading.

## Scope

This milestone does:

- Create the Flutter app under `apps/mobile`.
- Add mobile routing, theme, and sign-in gate.
- Add auth API client and secure token storage.
- Add SQLite local database for books, chapters, reading positions, and pending sync events.
- Add local book file copy and SHA-256 fingerprint calculation.
- Add TXT and EPUB parser foundations.
- Add import orchestration.
- Add library screen and basic reader screen.
- Reader must be a standalone full-screen route, not a bottom-navigation tab.
- Add offline reading regression tests.

This milestone does not:

- Implement lookup bottom sheet.
- Implement paragraph translation UI.
- Implement vocabulary review UI.
- Implement web reader or web admin.
- Upload original book files or chapter content.
- Build a cloud bookshelf.

## Required Prior Milestones

M1 should be complete before real auth integration testing:

- Auth API contract exists.
- Login, register, refresh, and current-user endpoints exist or are mocked in mobile tests.

M2 should be complete before live reading sync testing:

- Reading book metadata and progress endpoints exist.

Mobile task tests must use fake HTTP clients unless the task card explicitly asks for live backend verification.

## Task Order

1. `M6-F01-T01-mobile-flutter-project-skeleton.md`
2. `M6-F01-T02-mobile-routing-theme-auth-gate.md`
3. `M6-F02-T01-mobile-auth-client-session.md`
4. `M6-F03-T01-mobile-local-database-foundation.md`
5. `M6-F04-T01-mobile-book-storage-fingerprint.md`
6. `M6-F04-T02-mobile-txt-parser.md`
7. `M6-F04-T03-mobile-epub-parser.md`
8. `M6-F05-T01-mobile-book-import-orchestrator.md`
9. `M6-F06-T01-mobile-library-screen-import-flow.md`
10. `M6-F06-T02-mobile-reader-basic-page.md`
11. `M6-F07-T01-mobile-offline-reading-regression.md`

## Milestone Acceptance

Milestone 6 is complete when:

- `apps/mobile` exists and `flutter test` runs.
- Signed-out users see auth screens before app tabs.
- Signed-in bottom navigation uses Library, Vocabulary, Stats, and Settings only.
- Tokens are stored in secure storage, not SQLite.
- Imported TXT and EPUB books are copied into app-private local storage.
- Book fingerprints are lowercase SHA-256 hex.
- Parsed chapters are stored locally.
- Library shows local imported books.
- Reader opens a local chapter full-screen, hides bottom app navigation, and saves local reading position.
- Reading works offline for already imported books.
- No sync payload or API request includes original file content or chapter content.
