FROM node:24-alpine AS base
# Prisma's query engine on Alpine needs OpenSSL.
RUN apk add --no-cache openssl && corepack enable
WORKDIR /repo

FROM base AS build
# Fetch dependencies from the lockfile only, so this layer stays cached until it changes.
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
RUN pnpm fetch

COPY apps/backend ./apps/backend
RUN pnpm install --offline --frozen-lockfile --filter @plant-flower/backend \
  && pnpm --filter @plant-flower/backend prisma:generate \
  && pnpm --filter @plant-flower/backend build \
  && pnpm --filter @plant-flower/backend deploy --legacy --prod /prod/backend \
  && cd /prod/backend && ./node_modules/.bin/prisma generate

FROM node:24-alpine AS runtime
RUN apk add --no-cache openssl
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /prod/backend ./

EXPOSE 5000
CMD ["node", "dist/server.js"]
