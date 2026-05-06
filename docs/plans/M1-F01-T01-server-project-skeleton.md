# M1-F01-T01 Server Project Skeleton

## Task ID

`M1-F01-T01`

## Title

Create the Spring Boot server project skeleton.

## Goal

Create a runnable `server` Maven project with the dependencies needed for later backend tasks.

## Scope

This task only does:

- Create `server` project structure.
- Configure Maven wrapper.
- Configure Java 25 LTS.
- Configure Spring Boot parent version `4.0.5`.
- Add Spring Boot dependencies needed by Milestone 1.
- Add one smoke test proving the application context loads.

This task does not:

- Create database tables.
- Implement auth logic.
- Implement API controllers.
- Add mobile, Nuxt, or Docker files.

## Allowed Files

This task may create or modify only:

- `server/pom.xml`
- `server/mvnw`
- `server/mvnw.cmd`
- `server/.mvn/wrapper/maven-wrapper.properties`
- `server/src/main/java/com/studyforread/server/StudyForReadServerApplication.java`
- `server/src/main/resources/application.yml`
- `server/src/test/java/com/studyforread/server/StudyForReadServerApplicationTests.java`
- `server/.gitignore`

## Forbidden Files

This task must not modify:

- `apps/**`
- `infra/**`
- `docs/specs/**`
- `docs/plans/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`
- `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`
- `docs/plans/IMPLEMENTATION_START_GATE.md`
- `docs/plans/M1_BACKEND_FOUNDATION.md`
- `docs/specs/ARCHITECTURE.md`
- `docs/specs/API_CONTRACT.md`

## Tests First

Because this task creates the project skeleton, the first test is the generated application context smoke test.

Create:

- `server/src/test/java/com/studyforread/server/StudyForReadServerApplicationTests.java`

Test content target:

```java
package com.studyforread.server;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class StudyForReadServerApplicationTests {

    @Test
    void contextLoads() {
    }
}
```

Run:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd test
```

Expected result:

- If JDK 25 LTS is missing, command fails with a Java version error. Stop and report.
- If dependencies download correctly and JDK 25 LTS exists, test passes.

## Implementation Steps

- [ ] Step 1: Confirm `D:\Codex\Study For Read Phone\server` does not already contain business code.
- [ ] Step 2: Generate or create a Maven Spring Boot project using package `com.studyforread.server`.
- [ ] Step 3: Use artifact id `server` and application class `StudyForReadServerApplication`.
- [ ] Step 4: Configure Java version `25`.
- [ ] Step 5: Use Spring Boot `4.0.5`; do not use Spring Boot 3.x, milestone, release candidate, snapshot, Gradle, or FastAPI.
- [ ] Step 6: Include dependencies: `spring-boot-starter-web`, `spring-boot-starter-security`, `spring-boot-starter-data-jpa`, `spring-boot-starter-validation`, `org.postgresql:postgresql`, `org.flywaydb:flyway-core`, `spring-boot-starter-actuator`, and `spring-boot-starter-test`.
- [ ] Step 7: Configure the Maven compiler release to `25`.
- [ ] Step 8: Add `application.yml` with only app name and empty profile placeholders; do not add real secrets.
- [ ] Step 9: Add the context loading test shown above.
- [ ] Step 10: Run the verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd test
```

## Acceptance Criteria

- `server/pom.xml` exists.
- Maven wrapper exists.
- `server/pom.xml` uses Spring Boot `4.0.5`.
- `server/pom.xml` configures Java release `25`.
- Main application class exists under `com.studyforread.server`.
- Context smoke test exists.
- Verification command either passes or reports a real environment blocker such as missing JDK 25 LTS.

## Stop Conditions

- JDK 25 LTS is missing.
- Spring Boot `4.0.5` is unavailable from Maven Central.
- Network cannot download dependencies.
- A `server` project already exists with conflicting files.
- Any implementation requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
