# M5 Study Stats Backend Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build backend study statistics persistence and APIs so mobile and future web clients can sync reading minutes, lookup counts, paragraph translation counts, created cards, and reviewed cards.

## Scope

This milestone does:

- Create `study_daily_stats` persistence.
- Implement `POST /api/v1/stats/daily` as an authenticated incremental counter endpoint.
- Implement `GET /api/v1/stats/summary` for current-user totals.
- Add regression tests for user isolation, non-negative counters, and no raw-content storage.

This milestone does not:

- Build mobile statistics UI.
- Build heatmap UI.
- Build admin statistics dashboards.
- Store book content, chapter content, lookup raw text, or translated paragraphs.
- Add paid quotas or billing.

## Required Prior Milestones

M1 must be complete:

- User auth exists.
- Current-user identity is available.
- API envelope and error codes exist.

M2, M3, and M4 can produce stats events later, but this milestone does not require their endpoint implementations to call stats automatically.

## Task Order

1. `M5-F01-T01-study-daily-stats-persistence.md`
2. `M5-F02-T01-add-daily-stats-endpoint.md`
3. `M5-F02-T02-study-summary-endpoint.md`
4. `M5-F03-T01-study-stats-user-isolation-regression.md`

## Milestone Acceptance

Milestone 5 is complete when:

- `study_daily_stats` exists with UUID primary key, user foreign key, unique `user_id + stat_date`, non-negative counters, `created_at`, and `updated_at`.
- `POST /api/v1/stats/daily` creates or increments current-user daily counters.
- `GET /api/v1/stats/summary` returns current-user totals and zero totals for a new user.
- Stats APIs require user authentication.
- User A cannot read or modify User B's stats.
- No stats table, DTO, or response stores or exposes raw book text, raw lookup text, or raw translated paragraph text.

