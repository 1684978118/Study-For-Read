# Infrastructure

This directory is reserved for first-release single-server deployment assets.

## First-Release Boundary

The first deployment target is one Linux server running the public entrypoint, API runtime, and database roles on the same host. The intended roles are:

- Nginx: public HTTP/HTTPS entrypoint, reverse proxy, and static Web Reader/Web Admin asset serving.
- API: Spring Boot backend runtime behind Nginx.
- PostgreSQL: application database, not exposed publicly.

Docker Compose, Dockerfiles, Nginx configuration, certificate setup, backup scripts, and restore scripts are intentionally left for later task cards. This task only defines the environment contract and documentation boundary.

## Environment Contract

Use the repository root `.env.example` as the list of required variables and expected value shapes. It contains placeholder/example values only. Operators must create a local `.env` manually and keep it out of git.

Translation provider secrets belong only in the server runtime environment. Mobile, Web Reader, and Web Admin clients must use the backend API and must not receive provider keys.
