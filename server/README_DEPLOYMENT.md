# Server Container Deployment

This directory contains the Spring Boot API container image definition.

## Build

From the repository root:

```powershell
docker build -t study-for-read-api:local .\server
```

The image uses a multi-stage build. The build stage runs the Maven wrapper and creates the Spring Boot jar. The runtime stage uses a JRE image, runs as a non-root user, and sets conservative JVM memory defaults for a first-release 4 GB single-server deployment.

## Runtime Configuration

Runtime configuration is provided through environment variables. Do not bake secrets into the image and do not copy a real `.env` into the build context.

Example local run with placeholder values:

```powershell
docker run --rm -p 8080:8080 `
  -e SPRING_DATASOURCE_URL="jdbc:postgresql://postgres.example.local:5432/study_for_read_example" `
  -e SPRING_DATASOURCE_USERNAME="study_for_read_example" `
  -e SPRING_DATASOURCE_PASSWORD="change-me-datasource-password" `
  -e JWT_SECRET="change-me-user-jwt-secret-at-least-32-bytes" `
  -e ADMIN_JWT_SECRET="change-me-admin-jwt-secret-at-least-32-bytes" `
  -e TRANSLATION_PROVIDER="placeholder-provider" `
  -e TRANSLATION_PROVIDER_API_KEY="change-me-translation-provider-key" `
  -e TRANSLATION_TEXT_MAX_LENGTH="2000" `
  -e CORS_ALLOWED_ORIGINS="http://web-reader.example.local,http://web-admin.example.local" `
  study-for-read-api:local
```

`JAVA_TOOL_OPTIONS` can be overridden by the deployment environment when the host memory budget changes. The default image values are intentionally conservative:

```text
-XX:InitialRAMPercentage=25.0
-XX:MaxRAMPercentage=60.0
-XX:+ExitOnOutOfMemoryError
```

## Image Boundary

The Dockerfile does not create Docker Compose services, Nginx routing, backups, web app images, or real environment files. Those deployment pieces belong to later task cards.
