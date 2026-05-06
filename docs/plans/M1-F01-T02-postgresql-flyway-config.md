# M1-F01-T02 PostgreSQL And Flyway Config

## Task ID

`M1-F01-T02`

## Title

Configure PostgreSQL and Flyway profiles for the server.

## Goal

Make the server ready to run schema migrations against PostgreSQL and use an isolated test profile.

## Scope

This task only does:

- Add database configuration.
- Add Flyway migration location.
- Add test profile configuration.
- Add one test proving the application can start with the test profile.

This task does not:

- Create user tables.
- Create auth endpoints.
- Add Docker Compose.
- Add Redis.

## Allowed Files

- `server/src/main/resources/application.yml`
- `server/src/test/resources/application-test.yml`
- `server/src/test/java/com/studyforread/server/config/TestProfileContextTest.java`

## Forbidden Files

- `apps/**`
- `infra/**`
- `docs/specs/**`
- Existing Java files not listed in Allowed Files
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/DATA_MODEL.md`
- `server/pom.xml`
- `server/src/main/resources/application.yml`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/config/TestProfileContextTest.java`

Test content target:

```java
package com.studyforread.server.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class TestProfileContextTest {

    @Test
    void startsWithTestProfile() {
    }
}
```

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TestProfileContextTest test
```

Expected red result:

- Test fails because `application-test.yml` does not exist or datasource configuration is incomplete.

## Implementation Steps

- [ ] Step 1: Read current `server/pom.xml` and confirm Flyway, JPA, PostgreSQL, and test dependencies exist.
- [ ] Step 2: Write `TestProfileContextTest`.
- [ ] Step 3: Run the red verification command and confirm failure is due to missing or incomplete test profile.
- [ ] Step 4: Update `application.yml` to use environment variables for production-like database settings:

```yaml
spring:
  application:
    name: study-for-read-server
  datasource:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/study_for_read}
    username: ${DATABASE_USERNAME:study_for_read}
    password: ${DATABASE_PASSWORD:study_for_read}
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true
    locations: classpath:db/migration
```

- [ ] Step 5: Create `application-test.yml` with an embedded or test-safe datasource supported by existing dependencies. If no embedded database dependency exists, use PostgreSQL Testcontainers only after adding it in a separate task card; otherwise stop and report.
- [ ] Step 6: Run the verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TestProfileContextTest test
```

## Acceptance Criteria

- Main profile uses environment variables, not hard-coded secrets.
- JPA `ddl-auto` is `validate`.
- Flyway location is `classpath:db/migration`.
- Test profile context starts or reports a dependency gap that must be split into a new task card.

## Stop Conditions

- Adding a new dependency is required but not listed in this task.
- Test failure is unrelated to datasource or profile configuration.
- JDK 25 LTS is missing.
- Maven wrapper is missing.
- Any file outside Allowed Files must be modified.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
