# M11 Mobile Acceptance Improvements

> For AI workers: this milestone is for post-feature mobile acceptance polish. Keep every task small, test-first, and limited to one visible acceptance problem.

## Goal

Bring the completed mobile app from feature-complete to acceptance-ready on emulator and real devices.

## Scope

This milestone does:

- Improve mobile screen polish found during emulator acceptance.
- Add focused widget tests for visual or interaction issues that can regress.
- Keep fixes local-first and privacy-preserving.
- Record each improvement as a task card before code changes.

This milestone does not:

- Add new backend capabilities.
- Add cloud book storage.
- Upload original files, full chapters, selected text, paragraph text, or translated text.
- Add payment, quota, subscription, or provider-management UI.
- Replace existing app architecture or navigation.

## Task Order

1. `M11-F01-T01-mobile-settings-acceptance-polish.md`
2. `M11-F02-T01-mobile-reader-inline-translate-hotspot.md`
3. `M11-F03-T01-mobile-chinese-ui-copy.md`
4. `M11-F04-T01-mobile-emulator-chinese-visual-acceptance.md`

Add later task cards only after the next emulator acceptance pass finds a concrete issue.

## Acceptance Method

Each task must include:

- Allowed files.
- Forbidden files.
- Tests first.
- Verification commands.
- Manual emulator acceptance notes when the issue is visual.

## Milestone Acceptance

M11 can pause when:

- Auth, Library, Reader, Vocabulary, Stats, and Settings all look usable on a phone viewport.
- Main flows can be exercised on an Android emulator without obvious clipped text, missing exits, dead-end navigation, or raw debug presentation.
- Full Flutter tests and analyze pass after each accepted improvement.
