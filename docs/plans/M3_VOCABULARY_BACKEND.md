# M3 Vocabulary Backend Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build the backend vocabulary foundation with a strict split between public lexemes and user-specific word card review state.

## Scope

This milestone does:

- Create `lexemes` persistence.
- Create `user_word_cards` persistence.
- Create user vocabulary card API.
- List due cards.
- Review cards with the first simple spaced repetition rule.
- Add regression tests proving public lexeme data and private user learning state remain separated.

This milestone does not:

- Implement translation providers.
- Implement public lexeme admin UI.
- Implement admin APIs.
- Implement mobile UI.
- Implement import/export.
- Share private sentence cards publicly.

## Required Prior Milestones

M1 must be complete:

- User auth exists.
- Current-user identity is available in authenticated endpoints.

M2 is useful but not strictly required:

- `sourceBookFingerprint` can reference a locally imported book fingerprint, but vocabulary cards must still work without requiring `user_books`.

## Task Order

1. `M3-F01-T01-lexemes-persistence.md`
2. `M3-F01-T02-user-word-cards-persistence.md`
3. `M3-F02-T01-create-vocabulary-card-endpoint.md`
4. `M3-F02-T02-list-due-vocabulary-cards-endpoint.md`
5. `M3-F02-T03-review-vocabulary-card-endpoint.md`
6. `M3-F03-T01-vocabulary-boundary-regression.md`

## Milestone Acceptance

Milestone 3 is complete when:

- Public lexemes are reusable and unique by language pair, normalized surface, and entry type.
- User word cards store only user-specific review state.
- One user cannot see or review another user's cards.
- Private sentence cards are never exposed as public lexemes.
- First-release review intervals work.
- No endpoint stores original book content.

