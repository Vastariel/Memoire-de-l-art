# ── Build ────────────────────────────────────────────────────────
FROM node:22-alpine AS builder
WORKDIR /app

# Native deps for sharp
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm install

COPY tsconfig.json ./
COPY src ./src

RUN npm run build
RUN npm prune --omit=dev

# ── Runtime ──────────────────────────────────────────────────────
FROM node:22-alpine
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist         ./dist
COPY db ./db

EXPOSE 3000
USER node
CMD ["node", "dist/index.js"]
