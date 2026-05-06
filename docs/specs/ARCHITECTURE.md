# Architecture

## 1. Monorepo Layout

The project uses one repository with multiple applications.

```text
D:\Codex\Study For Read Phone
├── AGENTS.md
├── apps
│   ├── mobile
│   ├── web-reader
│   └── web-admin
├── server
├── infra
└── docs
    ├── ai-process
    ├── plans
    └── specs
```

Directory responsibilities:

- `apps/mobile`: Flutter Android and iOS app.
- `apps/web-reader`: Nuxt user reading website, later milestone.
- `apps/web-admin`: Nuxt admin system, later milestone.
- `server`: Spring Boot API server.
- `infra`: Docker Compose, Nginx, deployment configuration, backup scripts.
- `docs`: product specs, architecture, API contracts, data model, task plans.

## 2. Technology Stack

Mobile:

- Flutter.
- Dart.
- SQLite through `sqflite`; tests use `sqflite_common_ffi`.
- Local file storage for user imported books.
- Secure token storage through Flutter secure storage.

Web reader:

- Nuxt.
- Vue.
- IndexedDB through Dexie for browser-local imported book content, parsed chapters, progress, vocabulary cache, stats, and pending sync events.
- Token storage through a web auth store abstraction; first web release may use `localStorage`, with a later security hardening milestone for cookie-based auth.

Web admin:

- Nuxt.
- Vue.
- Admin-only API access.

Backend:

- Spring Boot 4.0.x.
- Java 25 LTS.
- PostgreSQL.
- Flyway or Liquibase for database migrations.
- JWT authentication.
- Redis optional for cache and rate limiting.

Deployment:

- Docker Compose on one 4-core 4GB server.
- Nginx reverse proxy.
- PostgreSQL container or local service.
- Redis container only when needed.
- Web Reader and Web Admin are built as static assets for first deployment and served by Nginx.

## 3. System Boundary

The backend is a learning-data API, not a book-hosting API.

Backend owns:

- Users.
- Authentication.
- Book metadata and reading progress.
- Public lexemes.
- User word cards.
- Study statistics.
- Translation and lookup API facade.
- Admin operations and audit logs.

Mobile app owns:

- Original imported book file.
- Parsed local chapters.
- Local reading cache.
- Offline reading state.
- Offline vocabulary review queue.

Web reader owns:

- Browser-local imported book content.
- Browser-local reading cache.

Admin owns:

- Operational views.
- Public lexeme maintenance.
- User and statistics management.

## 4. Data Flow

### Login

1. Client sends email and password to backend.
2. Backend validates credentials.
3. Backend returns access token and refresh token.
4. Client stores tokens securely.

### Local Book Import

1. User selects TXT or EPUB in the client.
2. Client parses metadata and chapters locally.
3. Client calculates book fingerprint.
4. Client sends metadata and fingerprint to backend.
5. Backend creates or updates a user book progress record.
6. Backend does not receive original book content.

### Reading Progress Sync

1. Client saves reading progress locally immediately.
2. Client sends progress to backend when online.
3. Backend stores latest progress by user and book fingerprint.
4. Client can restore progress after login on another device if that device imports the same book.

### Word Lookup

1. Client sends selected text, language pair, and optional paragraph context.
2. Backend checks public lexeme table.
3. Backend returns lexeme if found.
4. If not found, backend calls configured lookup or translation provider.
5. Backend may create a candidate lexeme if allowed by the implementation milestone.

### Paragraph Translation

1. Client sends a paragraph selected by the user.
2. Backend calls translation provider.
3. Backend returns translated text and provider status.
4. Backend may record minimal usage statistics.
5. Backend must not store a reusable copyrighted paragraph corpus.

### Vocabulary Save

1. Client saves a word, phrase, or idiom.
2. Backend links user word card to public lexeme when possible.
3. If the item is a private sentence, backend stores it as private user card context only.
4. Review state is user-specific.

## 5. Offline Strategy

Mobile offline allowed:

- Open imported books.
- Read parsed chapters.
- Save local reading position.
- Review already-synced or locally-created word cards.
- Queue sync events for later.

Mobile offline not required:

- New paragraph translation.
- New online lookup.
- Cross-device sync.

When the network returns:

1. Client sends queued progress updates.
2. Client sends queued word card changes.
3. Client fetches remote changes.
4. Conflict resolution uses latest update time for first release.

## 6. API Design Principles

- Every endpoint is under `/api/v1`.
- User endpoints require user token.
- Admin endpoints require admin token.
- Server responses use one consistent envelope.
- Error responses use stable machine-readable codes.
- Clients do not call translation providers directly.
- Clients do not send full books to the backend.

## 7. Security Principles

- Passwords are hashed with a strong password encoder.
- Access token lifetime is short.
- Refresh token lifetime is longer and revocable.
- Admin and user tokens are separated by role.
- Admin APIs are not available to user tokens.
- Translation provider keys stay on the server.
- Logs must not include passwords, tokens, or full copyrighted book text.

## 8. Deployment Architecture

First single-server deployment:

```text
Internet
  |
Nginx
  |
Spring Boot API
  |
PostgreSQL
```

Optional later additions:

- Redis for rate limiting.
- Object storage only for explicitly allowed non-book assets.
- Separate managed PostgreSQL if the single server becomes a bottleneck.

## 9. Milestone Order

1. Documentation and task card foundation.
2. Backend authentication and database foundation.
3. Backend reading sync and vocabulary foundation.
4. Mobile login and local import foundation.
5. Mobile reading and vocabulary loop.
6. Translation and lookup integration.
7. Web reader.
8. Web admin.
9. Deployment hardening.

## 10. Non-Goals

The architecture must not implement these in the first release:

- Cloud bookshelf storing original books.
- Public content hosting.
- Social features.
- Payment.
- Full-book translation.
- Admin access to user original book text.
