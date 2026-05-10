# Web Admin Static Deployment

Web Admin is built as static assets for the first single-server deployment. It is not deployed as an SSR Node runtime container in this milestone.

## Build

From this directory:

```powershell
npm run build
```

The static output is written to:

```text
.output/public
```

## API Base URL

Set the public API base at build/deployment time with a placeholder or environment-specific value:

```powershell
$env:WEB_ADMIN_PUBLIC_API_BASE="/api/v1"
npm run build
```

Use example or placeholder values in documentation and tests. Do not put real secrets, API keys, passwords, or tokens in public web builds.

## Serving

A later Nginx task will serve `.output/public` under the admin route, use the static `200.html` fallback for protected client-side admin routes, and route API traffic to the backend. This task does not add Nginx routing, Docker Compose, backend code, or a Node SSR runtime.
