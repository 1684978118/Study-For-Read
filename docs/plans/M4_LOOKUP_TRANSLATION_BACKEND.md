# M4 Lookup Translation Backend Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build backend lookup, paragraph translation, and annotation APIs while ensuring translation logs never become a raw-text corpus.

## Scope

This milestone does:

- Create `translation_events` persistence.
- Add a provider abstraction for lookup, translation, and annotation.
- Implement `POST /api/v1/study/lookup`.
- Implement `POST /api/v1/study/translate-paragraph`.
- Implement `POST /api/v1/study/annotate`.
- Add compliance regression tests proving raw source text and translated paragraphs are not persisted.

This milestone does not:

- Integrate paid billing.
- Implement full-book translation.
- Store raw paragraphs as reusable cache.
- Add mobile UI.
- Add web UI.
- Add admin provider configuration UI.

## Required Prior Milestones

M1 must be complete:

- User auth exists.
- Current-user identity is available.
- API envelope and error codes exist.

M3 should be complete:

- Public `lexemes` exist for first-pass lookup.

## Task Order

1. `M4-F01-T01-translation-events-persistence.md`
2. `M4-F01-T02-provider-abstraction.md`
3. `M4-F02-T01-lookup-endpoint.md`
4. `M4-F02-T02-translate-paragraph-endpoint.md`
5. `M4-F02-T03-annotate-endpoint.md`
6. `M4-F03-T01-translation-compliance-regression.md`

## Milestone Acceptance

Milestone 4 is complete when:

- Lookup first checks public lexemes.
- Paragraph translation goes through backend provider abstraction.
- Annotation endpoint returns token structures for reading UI.
- Translation event logs store only hash, length, provider, request type, success state, and error code.
- No migration contains raw text or translated text columns for translation events.
- No endpoint performs full-book translation.

