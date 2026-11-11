# Self-hosting (Docker, tailnet only)

The site is a Next.js app. Upstream deploys it to Vercel; this fork adds the
`Dockerfile` at the repo root and the compose file in this folder.

## Build and run

```bash
git clone -b selfhost https://github.com/traderza/involutionhell.git
cd involutionhell
docker build \
  --build-arg NEXT_PUBLIC_SITE_URL=http://<tailnet-host>:3010 \
  -t involutionhell:local .
docker compose -f deploy/docker-compose.yml up -d
```

`NEXT_PUBLIC_SITE_URL` is inlined into the client bundle at build time. Set it to
the URL users open, or canonical links and the sitemap point at the public site.

## Why it runs without the Spring Boot backend

- The docs are static MDX. The build compiles them into `.next`, so no database
  is needed to read them.
- The backend features (`/auth`, `/api/events`, `/api/posts`, `/analytics`) are
  Next.js rewrites to `BACKEND_URL`. With that variable unset they 404; the docs
  keep working.
- `scripts/generate-leaderboard.mts` keeps the committed
  `generated/site-leaderboard.json` when the backend is unreachable, so the
  leaderboard shows the last shipped data instead of failing the build.
- Prisma is used only by maintenance scripts, not by the app.

## Build requirements

The image build is the heavy part.

- Node.js 22 and pnpm 10.20.0 (pinned in `package.json`, used through corepack).
- About 6 GB of RAM for `next build`. On a smaller host, add swap first:
  ```bash
  fallocate -l 8G /swapfile && chmod 600 /swapfile
  mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  ```
  Without it the build is OOM-killed with exit code 137.
- `DOCS_REMOTE_IMAGE_SIZE=disable` (set in the Dockerfile) keeps image handling
  offline and fast.

## Update to new upstream content

```bash
git pull origin selfhost        # or: git pull upstream main
docker build --build-arg NEXT_PUBLIC_SITE_URL=http://<tailnet-host>:3010 \
  -t involutionhell:local .
docker compose -f deploy/docker-compose.yml up -d
```

## Check it

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://<tailnet-ip>:3010/zh/docs   # 200
curl -s -o /dev/null -w '%{http_code}\n' http://<public-ip>:3010/           # 000
ss -ltnp | grep 3010                                                         # tailnet IP only
```
