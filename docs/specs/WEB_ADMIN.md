# Web Admin

This document defines the first admin management system scope.

## 1. Technology

- App path: `apps/web-admin`.
- Framework: Nuxt and Vue.
- State management: Pinia.
- HTTP client: Nuxt-compatible API client abstraction.
- Admin token storage: web admin token store abstraction; first release may use browser storage.

Do not share runtime code with `apps/web-reader` unless a later task explicitly creates a shared package.

## 2. Admin Scope

First admin version includes:

- Admin login.
- Current admin session restore.
- Dashboard summary.
- User list.
- Platform statistics summary.
- Admin audit log list.
- Public lexeme list.
- Public lexeme create and edit.
- Reject candidate lexeme.

First admin version does not include:

- Viewing user original book content.
- Downloading user imported books.
- Browsing raw paragraph translation logs.
- Editing user private sentence context.
- Payment, subscription, or quota management.
- Role management UI.

## 3. Pages

Required routes:

- `/admin/sign-in`
- `/admin`
- `/admin/users`
- `/admin/stats`
- `/admin/audit-logs`
- `/admin/lexemes`
- `/admin/lexemes/new`
- `/admin/lexemes/:id`

Signed-out admins must be redirected to `/admin/sign-in`.

User access tokens must not be accepted by admin pages or admin APIs.

## 4. Dashboard

Dashboard shows aggregate counters:

- Users.
- Active users.
- Disabled users.
- Book metadata records.
- Public lexemes.
- Word cards.
- Reading minutes.
- Lookups.
- Paragraph translations.
- Cards created.
- Cards reviewed.

Dashboard must not show:

- Original book names in bulk unless they are already metadata returned by admin API.
- Chapter content.
- Raw lookup text.
- Raw paragraph text.
- Translated paragraph text.

## 5. Users

User list shows:

- Email.
- Display name.
- Source language.
- Target language.
- Status.
- Created time.
- Updated time.

User list must not show:

- Password hash.
- Refresh token hash.
- Imported file path.
- Book content.
- Chapter content.
- Private sentence context.

## 6. Audit Logs

Audit logs show:

- Admin username.
- Action.
- Target type.
- Target id.
- Redacted details.
- Created time.

Audit logs must not show:

- Passwords.
- Tokens.
- Raw book content.
- Raw lookup text.
- Raw translated paragraph text.
- Full private sentence context.

## 7. Lexeme Management

Lexeme list supports:

- Search.
- Language pair filter.
- Entry type filter.
- Status filter.
- Pagination.

Lexeme form fields:

- Surface.
- Reading.
- Source language.
- Target language.
- Entry type.
- Part of speech.
- Definition.
- Short definition.
- Example.
- Status.

Rules:

- `normalizedSurface` is derived by backend.
- `example`, when present, must be license-safe and admin-provided.
- Rejecting a lexeme changes status to `rejected` and writes audit log.

## 8. UI Style

Admin UI should be quiet, dense, and work-focused:

- Use tables for list pages.
- Use filters above tables.
- Use simple forms for lexeme create and edit.
- Use compact status badges.
- Avoid landing-page hero sections.
- Avoid decorative card-heavy layouts.

## 9. Compliance

Admin exists to manage operational metadata and public lexemes, not user books.

Every admin page and API client must treat these fields as forbidden:

- `content`
- `chapterContent`
- `chapter_content`
- `originalFile`
- `original_file`
- `filePath`
- `file_path`
- `sourceText`
- `source_text`
- `rawText`
- `raw_text`
- `translatedText`
- `translated_text`
- `paragraphText`
- `paragraph_text`
- `passwordHash`
- `password_hash`
- `tokenHash`
- `token_hash`

