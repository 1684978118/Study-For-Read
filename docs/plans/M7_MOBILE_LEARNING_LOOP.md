# M7 Mobile Learning Loop Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, `docs/specs/UI_FLOWS.md`, `docs/specs/MOBILE_UI_STYLE.md`, the mobile specs, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build the mobile learning loop on top of local reading: lookup, paragraph translation, vocabulary saving, offline review, stats tracking, and queued sync.

## Scope

This milestone does:

- Extend mobile SQLite data for lexeme cache, word cards, translation cache, and daily stats.
- Add mobile API clients for study, vocabulary, reading sync, and stats sync.
- Add lookup bottom sheet in Reader.
- Add inline paragraph translation flow in Reader.
- Add save-to-vocabulary behavior.
- Add Vocabulary screen due, all, and private sentence tabs.
- Add Anki-compatible vocabulary export.
- Add simple spaced repetition review behavior.
- Add mobile stats tracking and basic Stats screen.
- Add sync worker for metadata, progress, word cards, reviews, and stats.
- Add end-to-end learning loop regression tests with fake HTTP.

This milestone does not:

- Add offline paragraph translation.
- Add full-book translation.
- Add furigana rendering beyond basic annotation tokens.
- Add AnkiWeb login or automatic Anki sync.
- Add paid quota or subscription UI.
- Add web reader or web admin.
- Upload original book files, full chapters, or translation cache content.

## Required Prior Milestones

M6 must be complete:

- Flutter app shell exists.
- Auth session exists.
- Local database exists.
- Local import and reader work offline.

M2, M3, M4, and M5 backend task plans define API contracts. Mobile tests must use fake HTTP unless a task card explicitly asks for live backend verification.

## Task Order

1. `M7-F01-T01-mobile-learning-local-data.md`
2. `M7-F02-T01-mobile-study-api-client.md`
3. `M7-F02-T02-mobile-reader-lookup-bottom-sheet.md`
4. `M7-F02-T03-mobile-paragraph-translation-flow.md`
5. `M7-F03-T01-mobile-vocabulary-api-client.md`
6. `M7-F03-T02-mobile-save-vocabulary-flow.md`
7. `M7-F04-T01-mobile-vocabulary-screen.md`
8. `M7-F04-T02-mobile-review-scheduler.md`
9. `M7-F04-T03-mobile-anki-export.md`
10. `M7-F05-T01-mobile-stats-tracker-screen.md`
11. `M7-F06-T01-mobile-learning-sync-worker.md`
12. `M7-F07-T01-mobile-learning-loop-regression.md`

## Milestone Acceptance

Milestone 7 is complete when:

- Reader can look up a selected word or phrase online and show a bottom sheet result.
- Reader can translate one paragraph by tapping the subtle paragraph-end `+`, then inserts the translation below the original paragraph.
- User can save a public lexeme card from lookup.
- Vocabulary screen shows due, all, and private sentence cards from local data.
- Vocabulary can export an Anki-compatible UTF-8 `.txt` file locally.
- Offline review updates local card state and queues sync.
- Stats screen shows today, last 7 days, and all-time counters.
- Sync worker sends metadata, progress, card creation, review, and daily stats without raw book/chapter content.
- Full learning-loop regression test passes with fake HTTP and no live backend.
