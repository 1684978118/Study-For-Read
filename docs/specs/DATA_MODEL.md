# Data Model

Database: PostgreSQL.

Migration tool: Flyway or Liquibase, decided in backend foundation milestone.

## 0. Database Standards

These standards are mandatory for every migration.

- Table names use snake_case.
- Primary keys use UUID.
- UUID primary keys use PostgreSQL `gen_random_uuid()` when the migration enables `pgcrypto`; otherwise the application must generate UUIDs explicitly. Do not mix both approaches inside one table.
- Mutable business tables use `created_at timestamptz not null default now()` and `updated_at timestamptz not null default now()`.
- Append-only event tables may use only `created_at`.
- Soft delete uses `deleted_at` only where needed.
- Enum-like columns use `varchar` plus `check` constraints. Do not use PostgreSQL enum types in first release because they are harder to migrate.
- Hash columns that store SHA-256 hex use `char(64)`.
- Counters and positions use `integer` with non-negative check constraints.
- Foreign keys must be explicit.
- User-owned child tables use `on delete cascade` unless the table is an audit/event table.
- Audit and usage event tables must not cascade-delete unless a privacy deletion milestone explicitly requires it.
- All unique business keys must have database constraints, not only service-level checks.
- Do not store secrets, raw tokens, raw passwords, original book files, original chapters, or raw translation paragraphs.

## 1. users

Stores normal user accounts.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| email | varchar(255) | yes | Unique, lowercase |
| password_hash | varchar(255) | yes | Never store raw password |
| display_name | varchar(80) | no | User-facing name |
| source_lang | varchar(16) | yes | Default `ja` |
| target_lang | varchar(16) | yes | Default `zh-CN` |
| status | varchar(32) | yes | `active`, `disabled` |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Unique index on `email`.
- Index on `status`.

Constraints:

- `status in ('active', 'disabled')`.
- `email = lower(email)`.

## 2. refresh_tokens

Stores revocable refresh tokens.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| user_id | uuid | yes | References `users.id` |
| token_hash | char(64) | yes | SHA-256 hex hash of refresh token |
| expires_at | timestamptz | yes | Expiration |
| revoked_at | timestamptz | no | Null means active |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Index on `user_id`.
- Unique index on `token_hash`.

Constraints:

- `expires_at > created_at`.

Foreign keys:

- `user_id` references `users(id)` on delete cascade.

## 3. admin_users

Stores administrator accounts.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| username | varchar(80) | yes | Unique |
| password_hash | varchar(255) | yes | Never store raw password |
| role | varchar(32) | yes | `admin`, `operator` |
| status | varchar(32) | yes | `active`, `disabled` |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Unique index on `username`.
- Index on `status`.

Constraints:

- `role in ('admin', 'operator')`.
- `status in ('active', 'disabled')`.

## 4. user_books

Stores per-user book metadata and reading progress. It does not store original book content.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| user_id | uuid | yes | References `users.id` |
| book_fingerprint | char(64) | yes | SHA-256 hex hash calculated by client |
| title | varchar(255) | yes | Client-provided title |
| author | varchar(255) | no | Client-provided author |
| file_type | varchar(16) | yes | `txt`, `epub` |
| source_lang | varchar(16) | yes | Example `ja` |
| target_lang | varchar(16) | yes | Example `zh-CN` |
| chapter_count | integer | yes | Client parsed count |
| current_chapter_index | integer | yes | Zero-based |
| current_paragraph_index | integer | yes | Zero-based |
| current_char_offset | integer | yes | Offset inside paragraph |
| last_read_at | timestamptz | no | Last reading time |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Unique index on `user_id, book_fingerprint`.
- Index on `user_id, last_read_at`.

Constraints:

- `file_type in ('txt', 'epub')`.
- `chapter_count >= 1`.
- `current_chapter_index >= 0`.
- `current_paragraph_index >= 0`.
- `current_char_offset >= 0`.

Foreign keys:

- `user_id` references `users(id)` on delete cascade.

Forbidden columns:

- `content`.
- `chapter_content`.
- `original_file`.
- `file_path` for uploaded original books.

## 5. lexemes

Stores public reusable words, phrases, and idioms.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| surface | varchar(255) | yes | Display text |
| normalized_surface | varchar(255) | yes | Search key |
| reading | varchar(255) | no | Furigana or pronunciation |
| source_lang | varchar(16) | yes | Example `ja` |
| target_lang | varchar(16) | yes | Example `zh-CN` |
| entry_type | varchar(32) | yes | `word`, `phrase`, `idiom` |
| part_of_speech | varchar(64) | no | Optional |
| definition | text | yes | Main definition |
| short_definition | varchar(500) | no | Compact display |
| example | text | no | Only license-safe example |
| status | varchar(32) | yes | `active`, `candidate`, `rejected` |
| created_by_admin_id | uuid | no | References `admin_users.id` |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Unique index on `source_lang, target_lang, normalized_surface, entry_type`.
- Index on `normalized_surface`.
- Index on `status`.

Constraints:

- `entry_type in ('word', 'phrase', 'idiom')`.
- `status in ('active', 'candidate', 'rejected')`.
- `normalized_surface = lower(trim(normalized_surface))`.

Foreign keys:

- `created_by_admin_id` references `admin_users(id)` on delete set null.

## 6. user_word_cards

Stores user-specific vocabulary review state.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| user_id | uuid | yes | References `users.id` |
| lexeme_id | uuid | no | References `lexemes.id`; null for private sentence card |
| card_type | varchar(32) | yes | `lexeme`, `private_sentence` |
| private_surface | varchar(500) | no | Used only when `card_type=private_sentence` |
| private_definition | text | no | User-private meaning |
| private_context | text | no | User-private sentence context |
| source_book_fingerprint | char(64) | no | No original text; SHA-256 hex when present |
| source_book_title | varchar(255) | no | Metadata only |
| review_status | varchar(32) | yes | `new`, `learning`, `known` |
| review_count | integer | yes | Starts at 0 |
| next_review_at | timestamptz | no | Due time |
| last_reviewed_at | timestamptz | no | Last review time |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Index on `user_id, next_review_at`.
- Index on `user_id, review_status`.
- Unique partial index on `user_id, lexeme_id` where `lexeme_id is not null`.

Rules:

- `lexeme_id` is required when `card_type=lexeme`.
- `private_surface` and `private_definition` are required when `card_type=private_sentence`.
- Public lexeme data is shared.
- Review state is never shared.

Constraints:

- `card_type in ('lexeme', 'private_sentence')`.
- `review_status in ('new', 'learning', 'known')`.
- `review_count >= 0`.
- For `card_type='lexeme'`, `lexeme_id is not null`.
- For `card_type='private_sentence'`, `private_surface is not null and private_definition is not null`.

Foreign keys:

- `user_id` references `users(id)` on delete cascade.
- `lexeme_id` references `lexemes(id)` on delete restrict.

## 7. study_daily_stats

Stores per-user daily learning statistics.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| user_id | uuid | yes | References `users.id` |
| stat_date | date | yes | User local date |
| reading_minutes | integer | yes | Default 0 |
| lookup_count | integer | yes | Default 0 |
| paragraph_translation_count | integer | yes | Default 0 |
| cards_created | integer | yes | Default 0 |
| cards_reviewed | integer | yes | Default 0 |
| created_at | timestamptz | yes | Creation time |
| updated_at | timestamptz | yes | Last update time |

Indexes:

- Unique index on `user_id, stat_date`.

Constraints:

- `reading_minutes >= 0`.
- `lookup_count >= 0`.
- `paragraph_translation_count >= 0`.
- `cards_created >= 0`.
- `cards_reviewed >= 0`.

Foreign keys:

- `user_id` references `users(id)` on delete cascade.

## 8. translation_events

Stores minimal translation usage records. It must not become a reusable book corpus.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| user_id | uuid | yes | References `users.id` |
| request_type | varchar(32) | yes | `word_lookup`, `paragraph_translation`, `annotation` |
| source_lang | varchar(16) | yes | Source language |
| target_lang | varchar(16) | yes | Target language |
| provider | varchar(64) | no | Provider name |
| source_text_hash | char(64) | yes | SHA-256 hex hash only |
| source_text_length | integer | yes | Character count |
| success | boolean | yes | Request success |
| error_code | varchar(64) | no | Stable error code |
| created_at | timestamptz | yes | Creation time |

Indexes:

- Index on `user_id, created_at`.
- Index on `request_type, created_at`.

Constraints:

- `request_type in ('word_lookup', 'paragraph_translation', 'annotation')`.
- `source_text_length > 0`.

Foreign keys:

- `user_id` references `users(id)` on delete restrict until privacy deletion workflow is designed.

Forbidden columns:

- Raw paragraph text.
- Full translated paragraph text.
- Original book content.

## 9. admin_audit_logs

Stores admin operation logs.

Columns:

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| id | uuid | yes | Primary key |
| admin_user_id | uuid | yes | References `admin_users.id` |
| action | varchar(128) | yes | Stable action name |
| target_type | varchar(64) | yes | Example `lexeme`, `user` |
| target_id | uuid | no | Target id |
| details_json | jsonb | no | Redacted details |
| ip_address | varchar(64) | no | Optional |
| created_at | timestamptz | yes | Creation time |

Indexes:

- Index on `admin_user_id, created_at`.
- Index on `target_type, target_id`.

Foreign keys:

- `admin_user_id` references `admin_users(id)` on delete restrict.

## 10. Future Payment Tables

Payment is not implemented in the first release.

Do not create payment tables in the first backend milestone unless a later task card explicitly asks for them.

Future concepts:

- User entitlement.
- Translation quota.
- Purchase receipt.
- Subscription status.
