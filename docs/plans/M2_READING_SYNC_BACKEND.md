# M2 Reading Sync Backend Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build backend reading-sync APIs that store only local book metadata and progress, never original book content.

## Scope

This milestone does:

- Create `user_books` persistence.
- Create or update synced book metadata by fingerprint.
- Update reading progress.
- List synced book metadata for the current user.
- Add compliance tests proving APIs reject or ignore original book content fields.

This milestone does not:

- Parse TXT or EPUB.
- Store original book files.
- Store chapter content.
- Implement mobile local database.
- Implement vocabulary.
- Implement translation.
- Implement stats.
- Implement admin APIs.

## Required Prior Milestones

M1 must be complete:

- Spring Boot project exists.
- Database migrations run.
- User auth exists.
- Tests can authenticate as a user.
- `ApiResponse` and `ErrorCode` exist.

## Task Order

1. `M2-F01-T01-user-books-persistence.md`
2. `M2-F02-T01-upsert-book-metadata-endpoint.md`
3. `M2-F02-T02-update-reading-progress-endpoint.md`
4. `M2-F02-T03-list-reading-books-endpoint.md`
5. `M2-F03-T01-reading-sync-compliance-regression.md`

## Milestone Acceptance

Milestone 2 is complete when:

- `user_books` table exists with no content columns.
- A signed-in user can upsert book metadata by fingerprint.
- A signed-in user can update reading progress.
- A signed-in user can list their synced books.
- User A cannot access or modify User B's book record.
- Requests containing original book content are rejected or ignored according to task card rules.
- No endpoint returns original book text.

