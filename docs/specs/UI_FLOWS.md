# UI Flows

This document describes user-facing flows. Visual and interaction style rules for mobile are defined in `docs/specs/MOBILE_UI_STYLE.md`.

First release priority:

1. Mobile login.
2. Mobile local book import.
3. Mobile reader.
4. Mobile lookup and paragraph translation.
5. Mobile vocabulary save and review.
6. Mobile sync status.

Web reader and web admin are later milestones.

## 1. Mobile App Navigation

First-release bottom navigation:

- Library.
- Vocabulary.
- Stats.
- Settings.

Rules:

- User must sign in before entering the app.
- No guest mode in first release.
- Reader opens only after a local book is imported or selected.
- Reader is a standalone full-screen route, not a bottom-navigation tab.
- Offline mode must keep Library, Reader, and Vocabulary usable for local data.

## 2. Login Flow

Screens:

- Sign In.
- Register.
- Loading session.
- Auth error state.

Sign In flow:

1. User opens app.
2. App checks local token.
3. If token is valid, enter Library.
4. If token is missing or expired, show Sign In.
5. User enters email and password.
6. App calls `/api/v1/auth/login`.
7. On success, store tokens and enter Library.
8. On failure, show inline error.

Register flow:

1. User opens Register from Sign In.
2. User enters email, password, display name.
3. Default language pair is Japanese to Chinese.
4. App calls `/api/v1/auth/register`.
5. On success, store tokens and enter Library.

Do not include in first release:

- Social login.
- Forgot password.
- Phone login.

## 3. Library Flow

Library screen states:

- Empty library.
- Imported books list.
- Import in progress.
- Import error.
- Offline available.

Import flow:

1. User taps import.
2. App opens file picker.
3. User selects TXT or EPUB.
4. App validates extension and size.
5. App parses metadata and chapters locally.
6. App calculates book fingerprint.
7. App stores original file locally.
8. App stores parsed chapters locally.
9. App calls `/api/v1/reading/books/{bookFingerprint}` when online.
10. App shows the book in Library.

Important UI copy:

- Make clear that books stay on this device.
- Do not imply cloud book storage.
- Show sync status for progress only.

## 4. Reader Flow

Reader layout for mobile:

- Default state: full-screen readable text.
- Hidden by default: title bar, chapter controls, font controls, and bottom app navigation.
- Tap blank reading space: toggle temporary top and bottom control overlays.
- Top overlay: back, book title, chapter title, sync/offline status, font settings.
- Bottom overlay: previous chapter, translation/progress control, next chapter, progress bar.

Reader interactions:

- Tap word or phrase: open lookup bottom sheet.
- Tap the very subtle `+` hotspot after a paragraph's last punctuation or last word: translate that paragraph.
- Paragraph translation inserts the translated paragraph directly below the original paragraph.
- Save progress automatically.
- Save progress when leaving page.

Reader offline behavior:

- Reading continues.
- Local progress saves.
- Lookup requiring server shows offline message.
- Paragraph translation hotspot shows a lightweight offline state.

Do not include in first release:

- Three-column desktop layout.
- Full-book translation.
- Public comments.
- AI summary panel.

## 5. Lookup Bottom Sheet

Open condition:

- User taps a token, word, phrase, or selected text in Reader.

Content:

- Surface text.
- Reading if available.
- Short definition.
- Full definition.
- Entry type: word, phrase, or idiom.
- Speaker button for pronunciation.
- Save to vocabulary action.

States:

- Loading.
- Found public lexeme.
- Provider lookup result.
- Not found.
- Offline unavailable.
- Error.

Save behavior:

1. User taps Save.
2. App calls `/api/v1/vocabulary/cards`.
3. App stores local card state.
4. Bottom sheet shows saved state.

## 6. Paragraph Translation Flow

Open condition:

- User taps the very subtle `+` hotspot after the paragraph's final punctuation or final word.

Content:

- The translated paragraph is inserted directly below the original paragraph.
- The translation uses a style close to reader text and is only lightly distinguished by color.

Rules:

- App sends only the selected paragraph.
- App does not upload full chapter.
- App does not trigger full-book translation in first release.
- Translation result can be cached locally for user convenience.
- Do not show a paragraph action menu.
- Do not show copy/save/collapse buttons under translated paragraphs in first release.

## 7. Vocabulary Flow

Vocabulary tabs:

- Due.
- All.
- Private sentences.

Due card flow:

1. User opens Vocabulary.
2. App shows cards due now.
3. User opens card.
4. User chooses Known or Unknown.
5. App updates local state.
6. App syncs review result when online.

Card display:

- Surface.
- Reading.
- Definition.
- Example or private context if available.
- Review status.
- Next review time.

Anki export:

- Vocabulary supports local export to Anki-compatible UTF-8 `.txt`.
- Export format follows `docs/specs/MOBILE_UI_STYLE.md`.
- First release does not implement AnkiWeb login or automatic Anki sync.

Do not include in first release:

- Shared vocabulary marketplace.
- User-to-user sharing.
- Public sentence sharing.

## 8. Stats Flow

Stats screen first release:

- Reading minutes.
- Lookups.
- Paragraph translations.
- Cards created.
- Cards reviewed.

States:

- Today.
- Last 7 days.
- All time summary.

Stats are allowed to be simple. Do not build complex charts before the reading loop is stable.

## 9. Settings Flow

First-release settings:

- Source language.
- Target language.
- Font size.
- Theme.
- Sync status.
- Export to Anki.
- Sign out.

Later settings:

- Translation provider preference.
- Data export.
- Account deletion.
- Privacy controls.

## 10. Web Reader Later Flow

Web reader will reuse the same product rules:

- User signs in.
- User imports local TXT or EPUB in browser.
- Browser stores content locally.
- Server syncs only metadata, progress, cards, and stats.
- Same lookup and translation APIs.

Do not implement before mobile reading loop works.

## 11. Web Admin Later Flow

Admin first screens:

- Admin login.
- Dashboard summary.
- Users list.
- Public lexeme list.
- Lexeme editor.
- Audit logs.

Admin forbidden UI:

- No button to view user original book content.
- No button to download user imported books.
- No raw paragraph corpus browser.

## 12. First Release Acceptance Flow

The first release is ready for broader testing when one user can complete this path:

1. Register.
2. Import local TXT.
3. Open the book.
4. Read one chapter.
5. Tap a Japanese word.
6. Save it as vocabulary.
7. Translate one paragraph.
8. Review the saved card.
9. Export vocabulary to an Anki-compatible text file.
10. Close app.
11. Reopen app offline.
12. Continue reading locally.
13. Reconnect network.
14. Sync progress and review state.
