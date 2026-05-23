# M12-F14-T09 Mobile Reader Single Paragraph Pagination

## Summary

Make furigana pagination behave more like a novel reader: long single paragraphs should fill the page by visible lines instead of being split after only a few lines, while genuinely short content should stay top-aligned and naturally leave blank space.

## Key Changes

- Replace overly conservative furigana height estimation with actual `TextPainter` line metrics plus compact ruby allowance.
- Keep `RubyText` rendering and keep the paragraph translation `+` as an overlay.
- Do not vertically center, stretch, or fabricate content for short single-paragraph pages.

## Test Plan

- Add a long single-paragraph furigana pagination test that proves the first page contains more than a tiny prefix.
- Add a short single-paragraph top-alignment test.
- Keep lookup, paragraph translation, and EPUB image regressions green.
