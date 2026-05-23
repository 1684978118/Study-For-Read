# M12-F14-T08 Mobile Reader Lookup And Typography Migration

## Summary

Fix two mobile reader regressions found during emulator acceptance: tapping visible reader text can fail to open lookup, and existing local reader preferences keep the old oversized typography after the defaults were tightened.

## Key Changes

- Reader text lookup must not be blocked by paragraph-level blank-tap handling.
- Furigana lookup must map taps on the visible ruby/main-text area back to the original paragraph token.
- The paragraph translation `+` remains independent and must not trigger lookup.
- Mobile database version 6 migrates existing global reader typography to `18 / 1.55 / 10`.
- The migration only overwrites `font_size`, `line_height`, and `paragraph_spacing`; other reader settings remain intact.

## Test Plan

- Add lookup tests for furigana visible-text taps and `+` isolation.
- Add database upgrade coverage proving v5 saved typography is migrated to the tightened v6 values.
- Keep repository default tests proving fresh installs still return the new defaults.
- Run targeted reader/database tests, analyze, full mobile tests, debug APK build, and LDPlayer acceptance.
