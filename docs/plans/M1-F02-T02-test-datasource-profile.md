# M1-F02-T02 Test Datasource Profile

## Task ID

`M1-F02-T02`

## Title

Enable a test datasource for JPA and Flyway tests.

## Goal

Make the `test` Spring profile able to start a real datasource, JPA, and Flyway without requiring Docker or a local PostgreSQL server.

## Scope

This task only does:

- Replace the direct `org.flywaydb:flyway-core` dependency with the Spring Boot 4 Flyway starter so Flyway auto-configuration is available.
- Add a test-scope H2 dependency.
- Configure `application-test.yml` to use H2 in PostgreSQL compatibility mode.
- Re-enable datasource, JPA, and Flyway for the `test` profile.
- Add one context test proving datasource and Flyway beans are available.

This task does not:

- Create application database tables.
- Create users or refresh tokens.
- Add production H2 dependency.
- Add Testcontainers.
- Add Docker Compose.
- Modify API, auth, user, or service code.

## Allowed Files

- `server/pom.xml`
- `server/src/test/resources/application-test.yml`
- `server/src/test/java/com/studyforread/server/config/TestDatasourceContextTest.java`

## Forbidden Files

- `server/src/main/resources/application.yml`
- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/api/**`
- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `docs/plans/M1-F03-T01-users-refresh-tokens-persistence.md`
- `server/pom.xml`
- `server/src/test/resources/application-test.yml`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/config/TestDatasourceContextTest.java`

Test content target:

```java
package com.studyforread.server.config;

import static org.assertj.core.api.Assertions.assertThat;

import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class TestDatasourceContextTest {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private Flyway flyway;

    @Test
    void startsWithDatasourceAndFlyway() throws Exception {
        assertThat(flyway).isNotNull();

        try (var connection = dataSource.getConnection();
                var statement = connection.createStatement();
                var resultSet = statement.executeQuery("select 1")) {
            assertThat(resultSet.next()).isTrue();
            assertThat(resultSet.getInt(1)).isEqualTo(1);
        }
    }
}
```

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
$env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
$env:Path = (Join-Path $env:JAVA_HOME "bin") + ";" + $env:Path
.\mvnw.cmd -Dtest=TestDatasourceContextTest test
```

Expected red result:

- Test fails because `application-test.yml` currently excludes datasource and JPA auto-configuration, disables Flyway, no H2 dependency exists, or Flyway auto-configuration is unavailable.

## Implementation Steps

- [ ] Step 1: Read all `Read First` files.
- [ ] Step 2: Create `TestDatasourceContextTest` exactly for datasource and Flyway availability.
- [ ] Step 3: Run the red test command and confirm failure is caused by missing datasource, missing Flyway, or missing H2 driver.
- [ ] Step 4: In `server/pom.xml`, replace the direct `org.flywaydb:flyway-core` dependency with `org.springframework.boot:spring-boot-starter-flyway`. Spring Boot 4 keeps Flyway auto-configuration in the Boot Flyway module; `flyway-core` alone is not enough.
- [ ] Step 5: Add `com.h2database:h2` as a `test` scope dependency in `server/pom.xml`.
- [ ] Step 6: Replace `application-test.yml` exclusions with a test datasource:

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:study_for_read_test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH
    driver-class-name: org.h2.Driver
    username: sa
    password:
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true
    locations: classpath:db/migration
```

- [ ] Step 7: Run the verification command.
- [ ] Step 8: Run full backend tests to confirm previous context tests still pass.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
$env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
$env:Path = (Join-Path $env:JAVA_HOME "bin") + ";" + $env:Path
.\mvnw.cmd -Dtest=TestDatasourceContextTest test
.\mvnw.cmd test
```

## Acceptance Criteria

- `TestDatasourceContextTest` passes.
- Full backend test suite passes.
- `application-test.yml` no longer excludes datasource, JPA, or Flyway auto-configuration.
- `server/pom.xml` uses `org.springframework.boot:spring-boot-starter-flyway`.
- `server/pom.xml` does not keep a direct `org.flywaydb:flyway-core` dependency.
- H2 dependency is test-scope only.
- No production datasource settings are changed.
- No application tables or entities are created in this task.

## Stop Conditions

- H2 cannot run under Java 25.
- Maven cannot download H2.
- Maven cannot download `spring-boot-starter-flyway`.
- Fix requires modifying files outside Allowed Files.
- Test failure is unrelated to datasource, JPA, Flyway, or H2 setup.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
