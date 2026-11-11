# syntax=docker/dockerfile:1
# Self-host image for the Involution Hell Next.js site (tailnet only).
# Fork addition: upstream deploys to Vercel; this builds the same app for Docker.

FROM node:22-bookworm-slim AS builder
ENV HUSKY=0 \
    CI=1 \
    NEXT_TELEMETRY_DISABLED=1 \
    DOCS_REMOTE_IMAGE_SIZE=disable
WORKDIR /app
RUN corepack enable \
 && apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY . .
RUN --mount=type=cache,id=pnpm-store,target=/pnpm-store \
    pnpm config set store-dir /pnpm-store \
 && pnpm install --frozen-lockfile
# NEXT_PUBLIC_* values are inlined into the client bundle at build time.
ARG NEXT_PUBLIC_SITE_URL=http://srv989192:3010
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
RUN pnpm build

FROM node:22-bookworm-slim AS runner
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=3000
WORKDIR /app
RUN corepack enable
COPY --from=builder /app /app
EXPOSE 3000
CMD ["pnpm", "start"]
