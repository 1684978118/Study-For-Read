# Environment Files

## Creating A Local `.env`

1. Start from the repository root `.env.example`.
2. Manually create a local `.env` beside it.
3. Replace every `change-me`, `placeholder`, or `example` value with an environment-specific value.
4. Do not commit `.env`.

This task does not create `.env`, and production secrets should not be pasted into documentation, chat, tests, or source files.

## Secret Sources

Use host secret management, deployment automation secrets, or an operator-managed runtime environment file. Secrets include database passwords, user JWT signing secrets, admin JWT signing secrets, and translation provider API keys.

Rotate secrets when an operator leaves, a deployment host is replaced, a credential may have been exposed, or a provider recommends rotation. Rotation must update the server runtime first, then dependent clients only through non-secret public API base URLs.

## Translation Provider Key Boundary

`TRANSLATION_PROVIDER_API_KEY` is server-only. It must be available to the Spring Boot API runtime and must not be exposed through mobile builds, Web Reader public runtime config, Web Admin public runtime config, static assets, logs, or API responses.
