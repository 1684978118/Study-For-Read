# M12 Mobile Tomato-Style Reader

> For AI workers: this milestone upgrades the mobile Reader from acceptance-polished scrolling text into a real mobile novel-reader experience inspired by Fanqie Novel style interaction patterns. Keep implementation test-first and split large behavior into small task cards.

## Goal

Build a phone-first Reader with real pagination, persistent reading preferences, a Fanqie-style bottom control bar, chapter directory, night mode, app-local brightness, page-turn modes, and reading layout controls.

## Confirmed Product Requirements

- Tapping Reader blank space shows overlay controls.
- Controls follow the Fanqie-style structure:
  - Bottom progress row: `上一章`, progress slider, `下一章`.
  - Bottom action row: `目录`, `夜间`, `设置`.
- `目录` is a real chapter directory sourced from local chapters.
- Tapping a directory item jumps to that chapter.
- `夜间` toggles dark reading mode; tapping again restores the previous background.
- Reading preferences must persist locally and apply after leaving and reopening Reader.
- Preferences are global Reader preferences, not per-book, unless a later task explicitly changes that.
- Background presets only; no custom background picker in this milestone.
- Text color control is removed. Text color is automatically derived from the selected background/night mode.
- Background presets:
  - 纸白
  - 米色
  - 护眼绿
  - 淡蓝
  - 深灰
  - 纯黑
- Settings panel includes:
  - 亮度
  - 护眼模式
  - 字号
  - 背景
  - 翻页
  - 其他
- `亮度` must really affect the app Reader page only. It must not modify global system brightness.
- `护眼模式` must visibly affect the Reader page with a warmer/softer eye-protection presentation.
- `字号` must really change Reader text size.
- `翻页` modes must be real Reader behavior, not decorative state:
  - `平移` as the default.
  - `覆盖`.
  - `上下`.
  - `无动画`.
  - `仿真` as a real transitional mode with a page-turn feel; full paper-curl rendering may be a later enhancement if it requires custom drawing beyond this milestone.
- `其他` includes:
  - 行距
  - 段距
  - 音量键翻页
- `音量键翻页`:
  - Defaults off.
  - Only works in Reader.
  - Volume up means previous page or previous chapter.
  - Volume down means next page or next chapter.
  - In `上下` mode, volume keys scroll one screen; at top/bottom they cross chapter boundaries.
- Existing local-first privacy boundaries remain unchanged.

## Explicit Non-Goals

- No comments UI.
- No comment settings.
- No comment bubbles.
- No listen/read-aloud feature.
- No download, share, or platform menu features from the reference screenshots.
- No backend upload of original books, chapters, selected text, paragraphs, translations, file paths, or images.
- No cloud bookshelf or remote book storage.
- No payment, ads, recommendation feed, or provider-management UI.

## Task Order

1. `M12-F01-T01-mobile-tomato-reader-requirements-card.md`
2. `M12-F02-T01-mobile-reader-preferences-persistence.md`
3. `M12-F03-T01-mobile-reader-bottom-controls-directory.md`
4. `M12-F04-T01-mobile-reader-settings-panel.md`
5. `M12-F05-T01-mobile-reader-app-brightness.md`
6. `M12-F06-T01-mobile-reader-pagination-engine.md`
7. `M12-F07-T01-mobile-reader-page-turn-modes.md`
8. `M12-F08-T01-mobile-reader-volume-key-paging.md`
9. `M12-F09-T01-mobile-reader-emulator-acceptance.md`
10. `M12-F10-T01-mobile-reader-seeded-emulator-acceptance.md`
11. `M12-F11-T01-mobile-reader-visual-polish-from-emulator.md`
12. `M12-F12-T01-mobile-acceptance-reader-exit.md`
13. `M12-F13-T01-mobile-reader-pagination-overflow.md`

Add or split task cards if an implementation step becomes too large for one safe TDD cycle.

## Acceptance Method

Each implementation task must include:

- Allowed files.
- Forbidden files.
- Red tests first.
- Focused verification commands.
- Full Flutter tests and analyze after production changes.
- Android emulator acceptance notes when UI, brightness, native Android, or key handling changes.

## Milestone Acceptance

M12 can pause when:

- Reader opens local TXT/EPUB books with a Fanqie-style control overlay.
- Directory lists real chapters and chapter jump works.
- Night mode, background presets, font size, line spacing, paragraph spacing, page-turn mode, and volume-key toggle persist across Reader reopen.
- App-local brightness changes visibly in Reader without changing global system brightness.
- Text chapters can be read with real pagination and at least default `平移` page turning.
- `覆盖`, `上下`, `无动画`, and `仿真` modes each have observable behavior.
- Existing lookup and paragraph translation remain usable or are explicitly covered by compatibility tests.
- Full Flutter tests and analyze pass.
