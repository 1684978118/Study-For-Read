# Study For Read Phone PRD v2

## 1. Product Positioning

Study For Read Phone is a personal foreign-language reading and study tool.

The product helps users import their own TXT or EPUB books locally, read them with learning aids, translate selected words or paragraphs, save vocabulary cards, and sync learning progress across devices.

The product is not a cloud novel library, public content platform, or copyrighted book hosting service.

## 2. First Release Goal

The first release focuses on the mobile app reading loop:

1. User registers or signs in.
2. User imports a local TXT or EPUB file.
3. App parses chapters locally.
4. User reads the book locally.
5. User taps a word or phrase for lookup.
6. User requests paragraph translation online.
7. User saves a word, phrase, or idiom as a vocabulary card.
8. User reviews due vocabulary cards.
9. User can export vocabulary cards to an Anki-compatible local text file.
10. App syncs reading progress, vocabulary state, and study statistics to the server.

## 3. Target Users

Primary first-release user:

- Chinese-speaking learner reading Japanese novels.
- Typical level: Japanese N3 to N1.
- Main need: read real text, understand words and paragraphs, collect vocabulary, review later.

Future users:

- Japanese learners reading Chinese.
- English or Korean users learning Japanese or Chinese.
- Multilingual readers using the same reading and vocabulary workflow.

## 4. Platform Scope

First release:

- Flutter mobile app for Android and iOS.
- Spring Boot API server.
- PostgreSQL database.
- Docker Compose single-server deployment.

Later releases:

- Nuxt user reading website.
- Nuxt admin management system.

## 5. Authentication Scope

First release requires login.

Allowed:

- Email registration.
- Email and password login.
- Token refresh.
- Current user profile.

Not in first release:

- Guest mode.
- Google login.
- Apple login.
- WeChat login.
- Passwordless login.
- Payment login gating.

## 6. Book Handling Scope

Books are local-first.

Allowed:

- User imports local TXT or EPUB in the mobile app.
- App stores the original file and parsed chapters locally.
- App calculates a book fingerprint.
- Server stores book metadata and reading progress.

Server may store:

- User id.
- Book fingerprint.
- Book title.
- Author if available.
- Source language.
- Target language.
- Current chapter index.
- Current paragraph index.
- Current character offset.
- Last read time.

Server must not store:

- Full original book file.
- Full original chapter content.
- A public copy of user-imported content.

## 7. Reading Scope

First-release reading features:

- Local bookshelf.
- TXT import.
- EPUB import.
- Chapter list.
- Reading page.
- Font size setting.
- Light and dark reading theme.
- Reading progress save.
- Resume last reading position.

Not in first release:

- Cloud bookshelf.
- Public book discovery.
- Social sharing.
- Comments.
- AI-generated book summaries.
- Full-text cloud search across books.

## 8. Translation And Lookup Scope

First release prioritizes Japanese to Chinese.

Required:

- Word or phrase lookup.
- Paragraph translation.
- Basic Japanese annotation support.
- Shared backend API used by mobile app and future web reader.
- Provider keys stay on the server.

Allowed implementation behavior:

- If a public lexeme exists, return that lexeme first.
- If no lexeme exists, call a configured translation or dictionary provider.
- If provider is unavailable, return a clear error and allow user to keep reading.

Not in first release:

- Offline paragraph translation.
- Full-book translation.
- User-visible paid translation quota.
- Multiple paid provider routing UI.

## 9. Vocabulary Scope

The vocabulary model separates public knowledge from private learning state.

Public lexeme:

- Word, phrase, or idiom.
- Reading.
- Part of speech.
- Definition.
- Example sentence if license-safe.
- Source language and target language.

User word card:

- User-specific saved state.
- Review status.
- Review count.
- Next review time.
- Source book metadata.
- Optional private sentence context.

Vocabulary export:

- First release supports local export to Anki-compatible UTF-8 text.
- Export does not require AnkiWeb login.
- Export does not upload original books, chapters, or exported files to the backend.

Sharing rule:

- Words, phrases, and idioms can be public lexemes.
- Full sentences are private by default.

## 10. Review Scope

First-release review features:

- Due card list.
- Mark as known.
- Mark as unknown.
- Simple spaced repetition intervals.
- Review statistics sync.

Initial interval rule:

- Unknown: due again tomorrow.
- Known first time: due in 3 days.
- Known repeatedly: due in 7, 15, then 30 days.

Advanced scheduling algorithms are not required in first release.

## 11. Study Statistics Scope

Server stores learning statistics only.

Required statistics:

- Reading minutes.
- Paragraph translation count.
- Word lookup count.
- Vocabulary cards created.
- Vocabulary cards reviewed.

Not required:

- Heatmap UI in first mobile release.
- Public leaderboard.
- Social ranking.

## 12. Admin Scope

Admin system is planned after mobile reading loop.

First admin version includes:

- Admin login.
- User list.
- Basic user status.
- Study statistics overview.
- Operation logs.
- Public lexeme management.

Admin must not include:

- Viewing user local book content.
- Downloading user imported books.
- Editing user private sentence context unless explicitly needed for support and audited.

## 13. Monetization Scope

First release does not implement payment.

Allowed:

- Keep future fields or modules in architecture notes.
- Reserve clear boundaries for future payment.

Not allowed in first release:

- Google Play billing.
- App Store purchase.
- Subscription.
- Translation quota billing.
- Paid user gating.

## 14. Compliance Rules

The product must keep a strict personal-tool boundary.

Rules:

- Users provide their own books.
- Server does not host the original book.
- Server does not expose user content publicly.
- Translation requests are processed as user-initiated actions.
- Translation logs must not become a shared copyrighted corpus.
- Users must be able to delete their account and synced learning data in a later privacy milestone.

## 15. Success Criteria

First release is successful when:

- A user can register and sign in.
- A user can import a TXT book locally.
- A user can read chapters locally.
- Reading position is saved locally and synced to server.
- A user can tap a word or phrase and receive lookup results.
- A user can request paragraph translation.
- A user can save a vocabulary card.
- A user can review due vocabulary cards.
- A user can export vocabulary cards to an Anki-compatible local text file.
- App still allows reading when offline.
- Server never stores original book content.
