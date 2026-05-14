# M12-F01-T01 Mobile Tomato Reader Requirements Card

## Task ID

`M12-F01-T01`

## Title

Record the Fanqie-style mobile Reader requirements and implementation boundaries.

## Goal

Capture the confirmed product requirements for upgrading the mobile Reader to a Fanqie Novel style reader before writing implementation code.

## Scope

This task only does:

- Add the M12 milestone plan.
- Record the confirmed Reader requirements from user review.
- Record the intended Fanqie-style interaction model:
  - paginated Reader engine,
  - overlay controls,
  - real chapter directory,
  - persistent reading preferences,
  - app-local brightness,
  - real page-turn modes,
  - settings panel,
  - volume-key page turning.
- Define task order for implementation cards.

This task does not:

- Modify Flutter production code.
- Modify tests.
- Add dependencies.
- Add Android native code.
- Change Reader UI behavior yet.
- Commit screenshots or local artifacts.

## Confirmed Requirements

The Reader should follow the Fanqie-style pattern:

- Tapping blank Reader space opens top/bottom overlay controls.
- Bottom controls show:
  - `上一章`,
  - progress slider,
  - `下一章`,
  - `目录`,
  - `夜间`,
  - `设置`.
- `目录` must be real:
  - lists local chapters,
  - highlights or indicates current chapter when feasible,
  - tapping a chapter jumps to it.
- `夜间`:
  - switches to dark reading presentation,
  - tapping again restores the previous background.
- `设置` opens a bottom panel with:
  - `亮度`,
  - `护眼模式`,
  - `字号`,
  - `背景`,
  - `翻页`,
  - `其他`.
- `亮度`:
  - must really affect the Reader page,
  - must be app-local,
  - must not change system global brightness.
- `护眼模式`:
  - must visibly soften/warm the Reader presentation.
- `字号`:
  - must really change text size.
- `背景`:
  - presets only,
  - no text color picker,
  - text color is derived automatically from the background.
- Background presets:
  - 纸白,
  - 米色,
  - 护眼绿,
  - 淡蓝,
  - 深灰,
  - 纯黑.
- `翻页`:
  - must be real behavior,
  - default is `平移`,
  - available modes are `仿真`, `覆盖`, `平移`, `上下`, `无动画`.
- `仿真`:
  - should provide a real page-turn-feeling transition,
  - full paper-curl rendering may be split into a later task if it requires custom drawing.
- `其他`:
  - 行距,
  - 段距,
  - 音量键翻页.
- `音量键翻页`:
  - defaults off,
  - Reader-only,
  - volume up goes previous,
  - volume down goes next,
  - in `上下` mode it scrolls by one screen and crosses chapters at boundaries.
- Preferences must persist locally and apply after reopening Reader.
- Reader preferences are global Reader preferences, not per-book.

## Explicitly Excluded

- 评论设置.
- 评论气泡.
- 听书.
- 下载.
- 分享.
- 平台更多菜单.
- Text color picker.
- Backend changes.
- Cloud book storage.
- Uploading raw book/chapter/paragraph/selected/translated content.

## Future Implementation Boundaries

Expected implementation cards may touch:

- `apps/mobile/lib/src/features/reader/**`
- `apps/mobile/test/src/features/reader/**`
- `apps/mobile/android/app/src/main/kotlin/**` only when app-local brightness or hardware key handling requires native Android integration.
- `apps/mobile/pubspec.yaml` only if a future task explicitly proves a dependency is required and updates the task card first.

Expected implementation cards must not touch:

- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Old project paths under `D:\Codex\Study for Read`
- Sync payload code unless the task explicitly proves a Reader setting sync requirement, which is currently not planned.

## Implementation Decomposition

Recommended next cards:

1. `M12-F02-T01-mobile-reader-preferences-persistence.md`
   - Store global Reader preferences locally.
   - Cover font size, line spacing, paragraph spacing, background, night mode, brightness value, eye protection, page-turn mode, and volume-key toggle.
2. `M12-F03-T01-mobile-reader-bottom-controls-directory.md`
   - Replace current control overlay with Fanqie-style bottom controls and real chapter directory.
3. `M12-F04-T01-mobile-reader-settings-panel.md`
   - Add settings panel UI and wire font size/background/night/eye-protection/spacing state.
4. `M12-F05-T01-mobile-reader-app-brightness.md`
   - Implement app-local brightness using Android window brightness or an equivalent app-local method.
5. `M12-F06-T01-mobile-reader-pagination-engine.md`
   - Move text Reader from whole-chapter scroll to paginated pages while preserving images and learning interactions.
6. `M12-F07-T01-mobile-reader-page-turn-modes.md`
   - Implement `平移`, `覆盖`, `上下`, `无动画`, and `仿真` behaviors.
7. `M12-F08-T01-mobile-reader-volume-key-paging.md`
   - Add Reader-only hardware volume-key page turning.
8. `M12-F09-T01-mobile-reader-emulator-acceptance.md`
   - Run emulator acceptance against the sample EPUB and capture local screenshots.

## Verification Commands

This requirements card changes docs only:

```powershell
cd "D:\Codex\Study For Read Phone"
git diff --name-only
git status --short --branch
```

Future implementation cards must run focused Flutter tests, full Flutter tests, and analyze.

## Acceptance Criteria

- M12 milestone plan exists.
- Confirmed requirements are written down.
- Fanqie-style approach is explicitly captured.
- Non-goals are explicit.
- The next implementation cards are listed.
- No production code is changed by this requirements card.

## Stop Conditions

- User changes the confirmed requirements.
- Requirement recording would require modifying production code.

## Completion Report Format

Reply with:

- Modified files.
- Whether production code changed.
- Whether tests were run or skipped, and why.
- Whether code was uploaded.
- Blockers.
- Recommended next task card.
