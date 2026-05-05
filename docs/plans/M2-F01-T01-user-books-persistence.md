# M2-F01-T01 User Books Persistence

## Task ID

`M2-F01-T01`

## Title

Create user book metadata and progress persistence.

## Goal

Add the database migration, entity, repository, and repository tests for `user_books`.

## Scope

This task only does:

- Add `user_books` migration.
- Add `UserBook` entity.
- Add file type enum if needed.
- Add repository methods for current-user reading sync.
- Add repository tests.

This task does not:

- Add reading controllers.
- Add API DTOs.
- Parse book files.
- Store original book content.
- Implement mobile code.

## Allowed Files

- `server/src/main/resources/db/migration/V2__create_user_books.sql`
- `server/src/main/java/com/studyforread/server/reading/UserBook.java`
- `server/src/main/java/com/studyforread/server/reading/BookFileType.java`
- `server/src/main/java/com/studyforread/server/reading/UserBookRepository.java`
- `server/src/test/java/com/studyforread/server/reading/UserBookRepositoryTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `server/src/main/java/com/studyforread/server/api/**`
- `server/src/main/java/com/studyforread/server/reading/*Controller.java`
- `server/src/main/java/com/studyforread/server/reading/*Service.java`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`
- `server/src/main/java/com/studyforread/server/user/UserAccountRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/reading/UserBookRepositoryTest.java`

Test behavior:

- Saving a `UserBook` for a user can be found by `userId` and `bookFingerprint`.
- Duplicate `userId + bookFingerprint` is rejected by database uniqueness.
- Querying by user returns only that user's books.
- Entity and migration do not expose fields named `content`, `chapterContent`, `originalFile`, or `filePath`.
- `book_fingerprint` is stored as `char(64)`.
- `file_type` rejects values outside `txt` and `epub`.
- `chapter_count` rejects values below 1.
- Progress indexes and offsets reject negative values.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UserBookRepositoryTest test
```

Expected red result:

- Test fails because `UserBook`, repository, or migration does not exist.

## Implementation Steps

- [ ] Step 1: Write `UserBookRepositoryTest`.
- [ ] Step 2: Run red test and confirm missing class or missing table failure.
- [ ] Step 3: Create `V2__create_user_books.sql` following `DATA_MODEL.md`.
- [ ] Step 4: Ensure `book_fingerprint` is `char(64)`.
- [ ] Step 5: Ensure migration includes unique constraint on `user_id, book_fingerprint`.
- [ ] Step 6: Ensure `user_id` references `users(id)` on delete cascade.
- [ ] Step 7: Ensure migration includes check constraints for `file_type`, `chapter_count`, `current_chapter_index`, `current_paragraph_index`, and `current_char_offset`.
- [ ] Step 8: Ensure migration does not include forbidden columns: `content`, `chapter_content`, `original_file`, `file_path`.
- [ ] Step 9: Create `BookFileType` enum with `TXT` and `EPUB`, mapping to lowercase database values or converting at persistence boundary.
- [ ] Step 10: Create `UserBook` entity mapped to `user_books`.
- [ ] Step 11: Create `UserBookRepository` with methods:
  - `Optional<UserBook> findByUserIdAndBookFingerprint(UUID userId, String bookFingerprint)`
  - `List<UserBook> findByUserIdOrderByLastReadAtDesc(UUID userId)`
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UserBookRepositoryTest test
```

## Acceptance Criteria

- Repository tests pass.
- `user_books` has no original content columns.
- User-specific uniqueness is enforced.
- `book_fingerprint` and progress constraints match `DATA_MODEL.md`.
- No controller or service is created.

## Stop Conditions

- M1 persistence is incomplete.
- Migration number conflicts.
- Test datasource cannot run migrations.
- Any file outside Allowed Files must be modified.
- Any implementation needs to store original book content.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
