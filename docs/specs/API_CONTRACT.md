# API Contract

Base path: `/api/v1`

Path and enum rules:

- `bookFingerprint` is a 64-character lowercase SHA-256 hex string.
- `fileType` values are `txt` and `epub`.
- User-facing status values are lowercase strings.
- Index and offset values must be zero or positive.

Response format:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

Error format:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_INVALID_CREDENTIALS",
    "message": "Invalid email or password"
  }
}
```

## 1. Error Codes

Common:

- `VALIDATION_ERROR`
- `UNAUTHORIZED`
- `FORBIDDEN`
- `NOT_FOUND`
- `CONFLICT`
- `RATE_LIMITED`
- `INTERNAL_ERROR`

Authentication:

- `AUTH_EMAIL_ALREADY_EXISTS`
- `AUTH_INVALID_CREDENTIALS`
- `AUTH_TOKEN_EXPIRED`
- `AUTH_REFRESH_TOKEN_INVALID`

Reading:

- `BOOK_METADATA_INVALID`
- `BOOK_PROGRESS_INVALID`

Vocabulary:

- `LEXEME_NOT_FOUND`
- `WORD_CARD_ALREADY_EXISTS`
- `WORD_CARD_NOT_FOUND`
- `PRIVATE_CARD_INVALID`

Translation:

- `TRANSLATION_PROVIDER_UNAVAILABLE`
- `TRANSLATION_TEXT_TOO_LONG`
- `TRANSLATION_UNSUPPORTED_LANGUAGE_PAIR`

Admin:

- `ADMIN_INVALID_CREDENTIALS`
- `ADMIN_REQUIRED`
- `ADMIN_DISABLED`
- `ADMIN_LEXEME_INVALID`
- `ADMIN_LEXEME_DUPLICATE`

## 2. Authentication APIs

### POST /auth/register

Creates a normal user.

Request:

```json
{
  "email": "reader@example.com",
  "password": "change-this-password",
  "displayName": "Reader",
  "sourceLang": "ja",
  "targetLang": "zh-CN"
}
```

Response data:

```json
{
  "user": {
    "id": "uuid",
    "email": "reader@example.com",
    "displayName": "Reader",
    "sourceLang": "ja",
    "targetLang": "zh-CN",
    "status": "active"
  },
  "accessToken": "jwt",
  "refreshToken": "opaque-token"
}
```

Rules:

- Email is normalized to lowercase.
- Password is never returned.
- Duplicate email returns `AUTH_EMAIL_ALREADY_EXISTS`.

### POST /auth/login

Authenticates a normal user.

Request:

```json
{
  "email": "reader@example.com",
  "password": "change-this-password"
}
```

Response data:

```json
{
  "user": {
    "id": "uuid",
    "email": "reader@example.com",
    "displayName": "Reader",
    "sourceLang": "ja",
    "targetLang": "zh-CN",
    "status": "active"
  },
  "accessToken": "jwt",
  "refreshToken": "opaque-token"
}
```

### POST /auth/refresh

Refreshes tokens.

Request:

```json
{
  "refreshToken": "opaque-token"
}
```

Response data:

```json
{
  "accessToken": "jwt",
  "refreshToken": "opaque-token"
}
```

### GET /auth/me

Returns current user.

Auth:

- User access token required.

Response data:

```json
{
  "id": "uuid",
  "email": "reader@example.com",
  "displayName": "Reader",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "status": "active"
}
```

## 3. Reading Sync APIs

### PUT /reading/books/{bookFingerprint}

Creates or updates local book metadata for the current user.

Path parameters:

- `bookFingerprint`: 64-character lowercase SHA-256 hex string.

Auth:

- User access token required.

Request:

```json
{
  "title": "Kokoro",
  "author": "Natsume Soseki",
  "fileType": "txt",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "chapterCount": 42
}
```

Response data:

```json
{
  "id": "uuid",
  "bookFingerprint": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "title": "Kokoro",
  "author": "Natsume Soseki",
  "fileType": "txt",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "chapterCount": 42,
  "currentChapterIndex": 0,
  "currentParagraphIndex": 0,
  "currentCharOffset": 0,
  "lastReadAt": null
}
```

Forbidden:

- Request must not include original file content.
- Request must not include full chapter text.
- Request must not include fields named `content`, `chapterContent`, `originalFile`, or `filePath`.

Validation:

- Invalid `bookFingerprint` returns `BOOK_METADATA_INVALID`.
- Blank title returns `BOOK_METADATA_INVALID`.
- Unsupported `fileType` returns `BOOK_METADATA_INVALID`.
- `chapterCount < 1` returns `BOOK_METADATA_INVALID`.
- Forbidden content fields return `BOOK_METADATA_INVALID`.

### PATCH /reading/books/{bookFingerprint}/progress

Updates reading progress.

Path parameters:

- `bookFingerprint`: 64-character lowercase SHA-256 hex string.

Auth:

- User access token required.

Request:

```json
{
  "currentChapterIndex": 3,
  "currentParagraphIndex": 12,
  "currentCharOffset": 48,
  "lastReadAt": "2026-05-05T12:30:00Z"
}
```

Response data:

```json
{
  "bookFingerprint": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "currentChapterIndex": 3,
  "currentParagraphIndex": 12,
  "currentCharOffset": 48,
  "lastReadAt": "2026-05-05T12:30:00Z"
}
```

Validation:

- Invalid `bookFingerprint` returns `BOOK_PROGRESS_INVALID`.
- Negative `currentChapterIndex`, `currentParagraphIndex`, or `currentCharOffset` returns `BOOK_PROGRESS_INVALID`.
- Missing current-user book returns `NOT_FOUND`.
- Request must not include fields named `content`, `chapterContent`, `originalFile`, or `filePath`.

### GET /reading/books

Lists synced book metadata and progress for current user.

Auth:

- User access token required.

Response data:

```json
{
  "items": [
    {
      "bookFingerprint": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "title": "Kokoro",
      "author": "Natsume Soseki",
      "fileType": "txt",
      "sourceLang": "ja",
      "targetLang": "zh-CN",
      "chapterCount": 42,
      "currentChapterIndex": 3,
      "currentParagraphIndex": 12,
      "currentCharOffset": 48,
      "lastReadAt": "2026-05-05T12:30:00Z"
    }
  ]
}
```

Rules:

- `bookFingerprint` in responses must be the same 64-character lowercase SHA-256 hex string stored in `user_books`.
- Response must not include `content`, `chapterContent`, `originalFile`, `filePath`, or any original chapter text.

## 4. Lookup And Translation APIs

### POST /study/lookup

Looks up a word, phrase, or idiom.

Auth:

- User access token required.

Request:

```json
{
  "text": "心",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "context": "先生の心を知りたいと思った。"
}
```

Response data:

```json
{
  "kind": "lexeme",
  "lexeme": {
    "id": "uuid",
    "surface": "心",
    "reading": "こころ",
    "entryType": "word",
    "partOfSpeech": "noun",
    "definition": "心；内心；精神",
    "shortDefinition": "心；内心"
  },
  "provider": "public_lexeme",
  "providerMessage": null
}
```

Rules:

- `context` is optional.
- Backend must not log raw context as reusable corpus.

### POST /study/translate-paragraph

Translates one user-selected paragraph.

Auth:

- User access token required.

Request:

```json
{
  "text": "私はその人を常に先生と呼んでいた。",
  "sourceLang": "ja",
  "targetLang": "zh-CN"
}
```

Response data:

```json
{
  "translatedText": "我一直称那个人为先生。",
  "provider": "configured_provider",
  "cached": false,
  "message": null
}
```

Rules:

- Text length limit is set by backend configuration.
- Backend records only text hash, length, request type, provider, and success state.

### POST /study/annotate

Returns basic annotation tokens for reading UI.

Auth:

- User access token required.

Request:

```json
{
  "text": "先生の心",
  "sourceLang": "ja"
}
```

Response data:

```json
{
  "tokens": [
    {
      "text": "先生",
      "reading": "せんせい",
      "dictionaryForm": "先生",
      "partOfSpeech": "noun"
    },
    {
      "text": "の",
      "reading": null,
      "dictionaryForm": "の",
      "partOfSpeech": "particle"
    },
    {
      "text": "心",
      "reading": "こころ",
      "dictionaryForm": "心",
      "partOfSpeech": "noun"
    }
  ]
}
```

## 5. Vocabulary APIs

### POST /vocabulary/cards

Creates or returns a user word card.

Auth:

- User access token required.

Request for public lexeme card:

```json
{
  "cardType": "lexeme",
  "lexemeId": "uuid",
  "sourceBookFingerprint": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "sourceBookTitle": "Kokoro"
}
```

Request for private sentence card:

```json
{
  "cardType": "private_sentence",
  "privateSurface": "私はその人を常に先生と呼んでいた。",
  "privateDefinition": "我一直称那个人为先生。",
  "privateContext": "User private sentence context",
  "sourceBookFingerprint": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "sourceBookTitle": "Kokoro"
}
```

Validation:

- `cardType` must be `lexeme` or `private_sentence`.
- `sourceBookFingerprint`, when present, must be a 64-character lowercase SHA-256 hex string.
- `lexemeId` is required when `cardType=lexeme`.
- `privateSurface` and `privateDefinition` are required when `cardType=private_sentence`.

Response data:

```json
{
  "id": "uuid",
  "cardType": "lexeme",
  "lexeme": {
    "id": "uuid",
    "surface": "心",
    "reading": "こころ",
    "definition": "心；内心；精神"
  },
  "reviewStatus": "new",
  "reviewCount": 0,
  "nextReviewAt": null
}
```

### GET /vocabulary/cards/due

Lists due cards.

Auth:

- User access token required.

Response data:

```json
{
  "items": [
    {
      "id": "uuid",
      "cardType": "lexeme",
      "surface": "心",
      "reading": "こころ",
      "definition": "心；内心；精神",
      "reviewStatus": "new",
      "reviewCount": 0,
      "nextReviewAt": null
    }
  ]
}
```

### POST /vocabulary/cards/{cardId}/review

Reviews one card.

Auth:

- User access token required.

Request:

```json
{
  "known": true,
  "reviewedAt": "2026-05-05T12:30:00Z"
}
```

Response data:

```json
{
  "id": "uuid",
  "reviewStatus": "learning",
  "reviewCount": 1,
  "nextReviewAt": "2026-05-08T12:30:00Z",
  "lastReviewedAt": "2026-05-05T12:30:00Z"
}
```

## 6. Statistics APIs

### POST /stats/daily

Adds daily learning events to the current user's per-day totals. This endpoint is incremental: posting the same `statDate` again adds to existing counters and returns the updated totals for that date.

Auth:

- User access token required.

Request:

```json
{
  "statDate": "2026-05-05",
  "readingMinutes": 12,
  "lookupCount": 8,
  "paragraphTranslationCount": 3,
  "cardsCreated": 2,
  "cardsReviewed": 5
}
```

Response data:

```json
{
  "statDate": "2026-05-05",
  "readingMinutes": 12,
  "lookupCount": 8,
  "paragraphTranslationCount": 3,
  "cardsCreated": 2,
  "cardsReviewed": 5
}
```

Validation:

- `statDate` is required and uses `YYYY-MM-DD`.
- Counter fields are required and must be zero or positive.
- If adding a counter would exceed the database integer range, return `VALIDATION_ERROR`.
- Response values are the current stored totals for this user and date after incrementing.
- Request and response must not include original book content, chapter content, raw lookup text, or raw translated paragraph text.

### GET /stats/summary

Returns current user's study summary.

Auth:

- User access token required.

Response data:

```json
{
  "readingMinutes": 120,
  "lookupCount": 88,
  "paragraphTranslationCount": 24,
  "cardsCreated": 31,
  "cardsReviewed": 46
}
```

Rules:

- Summary totals are calculated only from the current user's `study_daily_stats` rows.
- If the user has no stats, every counter returns `0`.
- Response must not include book metadata, original book content, chapter content, raw lookup text, or raw translated paragraph text.

## 7. Admin APIs

Admin APIs must use admin access tokens. User access tokens must not be accepted by admin endpoints.

### POST /admin/auth/login

Authenticates admin user.

Request:

```json
{
  "username": "admin",
  "password": "change-this-password"
}
```

Response data:

```json
{
  "admin": {
    "id": "uuid",
    "username": "admin",
    "role": "admin",
    "status": "active"
  },
  "accessToken": "jwt"
}
```

Validation:

- Invalid credentials return `ADMIN_INVALID_CREDENTIALS`.
- Disabled admin returns `ADMIN_DISABLED`.
- Password is never returned.

### GET /admin/auth/me

Returns current admin.

Auth:

- Admin access token required.

Response data:

```json
{
  "id": "uuid",
  "username": "admin",
  "role": "admin",
  "status": "active"
}
```

### GET /admin/users

Lists users without book content.

Auth:

- Admin access token required.

Query:

- `page`: zero-based page number, default `0`.
- `size`: page size, default `20`, maximum `100`.
- `status`: optional `active` or `disabled`.
- `q`: optional email or display-name search.

Response data:

```json
{
  "items": [
    {
      "id": "uuid",
      "email": "reader@example.com",
      "displayName": "Reader",
      "sourceLang": "ja",
      "targetLang": "zh-CN",
      "status": "active",
      "createdAt": "2026-05-05T12:30:00Z",
      "updatedAt": "2026-05-05T12:30:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "total": 1
}
```

Rules:

- Response must not include user imported book content, chapter text, raw lookup text, raw paragraph text, translated paragraph text, password hashes, refresh tokens, or access tokens.
- User tokens must return `ADMIN_REQUIRED`.

### GET /admin/stats/summary

Returns platform summary.

Auth:

- Admin access token required.

Response data:

```json
{
  "userCount": 120,
  "activeUserCount": 118,
  "disabledUserCount": 2,
  "bookMetadataCount": 460,
  "lexemeCount": 3200,
  "wordCardCount": 9800,
  "readingMinutes": 24000,
  "lookupCount": 8600,
  "paragraphTranslationCount": 2100,
  "cardsCreated": 9800,
  "cardsReviewed": 16300
}
```

Rules:

- Summary is aggregate only.
- Response must not include original book content, chapter content, raw lookup text, raw paragraph text, or translated paragraph text.

### GET /admin/audit-logs

Lists admin audit logs.

Auth:

- Admin access token required.

Query:

- `page`: zero-based page number, default `0`.
- `size`: page size, default `20`, maximum `100`.
- `adminUserId`: optional admin user id.
- `targetType`: optional target type.
- `action`: optional action.

Response data:

```json
{
  "items": [
    {
      "id": "uuid",
      "adminUserId": "uuid",
      "adminUsername": "admin",
      "action": "lexeme.create",
      "targetType": "lexeme",
      "targetId": "uuid",
      "details": {
        "surface": "心",
        "sourceLang": "ja",
        "targetLang": "zh-CN"
      },
      "createdAt": "2026-05-05T12:30:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "total": 1
}
```

Rules:

- `details` must be redacted.
- Audit logs must not contain passwords, tokens, original book text, raw lookup text, raw translated paragraphs, or full private sentence context.

### GET /admin/lexemes

Lists public lexemes.

Auth:

- Admin access token required.

Query:

- `page`: zero-based page number, default `0`.
- `size`: page size, default `20`, maximum `100`.
- `q`: optional search on surface or normalized surface.
- `sourceLang`: optional source language.
- `targetLang`: optional target language.
- `entryType`: optional `word`, `phrase`, or `idiom`.
- `status`: optional `active`, `candidate`, or `rejected`.

Response data:

```json
{
  "items": [
    {
      "id": "uuid",
      "surface": "心",
      "normalizedSurface": "心",
      "reading": "こころ",
      "sourceLang": "ja",
      "targetLang": "zh-CN",
      "entryType": "word",
      "partOfSpeech": "noun",
      "definition": "心；内心；精神",
      "shortDefinition": "心；内心",
      "example": null,
      "status": "active",
      "createdAt": "2026-05-05T12:30:00Z",
      "updatedAt": "2026-05-05T12:30:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "total": 1
}
```

### POST /admin/lexemes

Creates public lexeme.

Auth:

- Admin access token required.

Request:

```json
{
  "surface": "心",
  "reading": "こころ",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "entryType": "word",
  "partOfSpeech": "noun",
  "definition": "心；内心；精神",
  "shortDefinition": "心；内心",
  "example": null,
  "status": "active"
}
```

Response data:

```json
{
  "id": "uuid",
  "surface": "心",
  "normalizedSurface": "心",
  "reading": "こころ",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "entryType": "word",
  "partOfSpeech": "noun",
  "definition": "心；内心；精神",
  "shortDefinition": "心；内心",
  "example": null,
  "status": "active"
}
```

Validation:

- Blank `surface` or `definition` returns `ADMIN_LEXEME_INVALID`.
- Invalid `entryType` or `status` returns `ADMIN_LEXEME_INVALID`.
- Duplicate `sourceLang + targetLang + normalizedSurface + entryType` returns `ADMIN_LEXEME_DUPLICATE`.
- `example`, when present, must be license-safe and admin-provided, not copied from user private books.

### PATCH /admin/lexemes/{lexemeId}

Updates public lexeme.

Auth:

- Admin access token required.

Request:

```json
{
  "surface": "心",
  "reading": "こころ",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "entryType": "word",
  "partOfSpeech": "noun",
  "definition": "心；内心；精神",
  "shortDefinition": "心；内心",
  "example": null,
  "status": "active"
}
```

Response data:

```json
{
  "id": "uuid",
  "surface": "心",
  "normalizedSurface": "心",
  "reading": "こころ",
  "sourceLang": "ja",
  "targetLang": "zh-CN",
  "entryType": "word",
  "partOfSpeech": "noun",
  "definition": "心；内心；精神",
  "shortDefinition": "心；内心",
  "example": null,
  "status": "active"
}
```

Validation:

- Missing lexeme returns `NOT_FOUND`.
- Invalid fields return `ADMIN_LEXEME_INVALID`.
- Duplicate business key returns `ADMIN_LEXEME_DUPLICATE`.

### POST /admin/lexemes/{lexemeId}/reject

Rejects candidate lexeme.

Auth:

- Admin access token required.

Request:

```json
{
  "reason": "duplicate or low quality"
}
```

Response data:

```json
{
  "id": "uuid",
  "status": "rejected"
}
```

Rules:

- Missing lexeme returns `NOT_FOUND`.
- Operation writes an admin audit log.

Admin forbidden behavior:

- No endpoint may return original user book text.
- No endpoint may download user imported books.
- No endpoint may expose raw translation paragraphs as corpus.
- No endpoint may expose password hashes, raw tokens, or refresh token hashes.
- No endpoint may expose full private sentence context unless a later audited support milestone explicitly allows it.
