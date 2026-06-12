# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo layout

Three deployable units share one repo:

- `mobile/` — Flutter 3.3+ / Dart app (Riverpod, go_router, dio). Talks to the API via JWT.
- `backend/` — Fastify 5 + TypeScript + raw `pg` + MinIO. Owns the JWT, schema, scoring, cron.
- `admin/` — React 18 + Vite + Refine + Ant Design. Reads/writes via `Authorization: Bearer $ADMIN_TOKEN`.
- `docker-compose.yml` at the root wires `api + admin + db + minio`. Schema/seed are mounted into the `db` container's `docker-entrypoint-initdb.d` and apply on a **fresh** volume.

## Common commands

### Mobile
```bash
cd mobile
LC_ALL=en_US.UTF-8 flutter pub get
LC_ALL=en_US.UTF-8 flutter analyze         # must be clean before pushing UI changes
LC_ALL=en_US.UTF-8 flutter test            # unit + smoke
LC_ALL=en_US.UTF-8 flutter test test/app_smoke_test.dart   # single file
LC_ALL=en_US.UTF-8 flutter run -d 46080DLAQ001LM           # Pixel 9 deploy
LC_ALL=en_US.UTF-8 flutter run -d chrome --dart-define=USE_API=false   # offline mock
LC_ALL=en_US.UTF-8 flutter build apk --debug
LC_ALL=en_US.UTF-8 flutter build web
```
- `LC_ALL=en_US.UTF-8` is required because the project path contains `é` (Mémoire).
- `flutter`/`dart` are not on `PATH`; SDK lives at `~/develop/flutter/bin`. Either prepend it or use the absolute binary.
- l10n: ARB files in `mobile/lib/l10n/`. Apostrophes are **single** (`l'art`, not `l''art`) — `gen-l10n` emits literal Dart strings even inside plurals, so doubled apostrophes render as `''`. Generation runs automatically on `flutter pub get` / build (`generate: true` in `pubspec.yaml`, config in `l10n.yaml`).

### Backend
```bash
cd backend
npm install
npm run build         # tsc — typecheck (no Node in this dev env; build is the validation gate)
npm run dev           # tsx watch src/index.ts — port 3000
npm run db:setup      # psql $DATABASE_URL -f db/schema.sql (idempotent)
npm run db:seed       # tsx db/seed.ts — current ISO week artwork ("Le Semeur")
```
- `db/schema.sql` is idempotent **and** auto-heals v1 → v2 (drops legacy `artworks`/`instances` only when v1-only columns are detected). Safe to re-run.
- `db/seed.sql` is a pure-SQL equivalent of `seed.ts`, mounted into the db container so a fresh volume is seeded automatically.
- Compose Up does **not** re-apply schema on an existing `pg_data` volume. To re-apply: run `psql -f /docker-entrypoint-initdb.d/01_schema.sql` inside the `db` container.

### Admin
```bash
cd admin
npm install
npm run build         # tsc && vite build
npm run dev           # vite — port 5173
```

### Full stack (Docker)
```bash
cp .env.example .env  # fill secrets
docker compose up -d --build
# api → :3000  admin → :3001  minio → :9000/:9001  db → :5432
```
Deployment target is Unraid; the host path `/mnt/user/memoire-de-lart` is hard-coded as the build context in `docker-compose.yml`. Local rebuilds need that path to exist or the context lines edited.

## Architecture — the v2 domain model

The game is **weekly**, not monthly. Every concept below is keyed off the ISO week (UTC). Read [`backend/db/schema.sql`](backend/db/schema.sql) and [`backend/src/services/cycle.ts`](backend/src/services/cycle.ts) before touching domain logic — the cycle drives everything.

- **Artwork** — one per ISO week, portrait 3:4 grid (default 12×16 = 192 cells). Status: `draft → planned → active → revealed`. Title/description bilingual (`title_fr`/`title_en`).
- **Family** — 7 per artwork, one per day (Mon=1 … Sun=7). Keys: `bleus`, `ors`, `verts`, `terres`, `roses`, `rouges`, `gris`.
- **Variant** — 3 per family (21 per artwork). Hex colour. The cell map references variants, never families directly.
- **Claim** — first-come reservation of a variant inside an instance.
- **Contribution** — a photo placed into an instance's cells (cells × crops). Carries `delta_e`, variance, stamp reactions.
- **Instance** — `shared` (members must pick distinct variants — same photo fills everyone's instance) or `separate` (each member fills their own copy). Solo flag for single-player. Join via 6-char `code`.
- **Guess** — weekly title bet, editable until reveal. Points are degressive by `day_placed` (lun→dim: `[70,50,35,25,15,10,5]`).
- **Score / streak** — photo = 10 + ΔE bonus 0–15, × streak multiplier (×1.1/day, capped ×1.5). Collection unlock: 7 photos that week **and** ≥1 non-solo instance at 100 %.

Matching is **laxiste** (`backend/src/services/color-match.ts`): no photo is ever refused. ΔE ≤ 25 → "parfait", ≤ 55 → "correct", above → accepted with zero bonus. EXIF (incl. GPS) is stripped on upload.

### Cycle automation (`backend/src/services/cycle.ts` + cron in `index.ts`)
- Mon 00:00 UTC — `activateCurrentWeek()` promotes the `planned` artwork of the current ISO week to `active`.
- Sun 23:59 UTC — `revealCurrentWeek()` settles guesses, applies bet barème, flips status to `revealed`.
- The day-of-week → family mapping is deterministic from the date; there is no "current family" column.

## Mobile architecture

- Entry: `mobile/lib/main.dart` → `App` in `app.dart` → `routerProvider` in `router.dart`.
- Router: `go_router` with `StatefulShellRoute.indexedStack` for the 5-tab shell (`/today`, `/artwork`, `/instances`, `/collection`, `/profile`); push routes for `/variant`, `/catchup`, `/camera`, `/confirm`, `/bet`, `/reveal`, `/settings`, `/onboarding`. Auth-guard redirects unsigned users to `/onboarding`.
- State: Riverpod. Two layers:
  - **Action state**: `providers/auth_provider.dart` (signed-in / pseudo / online flag), `providers/game_provider.dart` (`GameNotifier` — owns the in-flight game state, calls API on transitions like `captureDone`, `claimVariant`, `placeBet`).
  - **Read providers**: `providers/data_providers.dart` — `FutureProvider`s for artwork cells, leaderboard, collection, claims, instance fill, instance photos, bet options. Each one mock-falls-back when `useApiProvider` is `false` or the API throws.
- API client: `services/api_client.dart` — single `dio` instance, baseURL from `AppConfig.apiBaseUrl` (`https://mda.vastariel.fr` by default; override at build with `--dart-define=USE_API=false` for offline). JWT persisted in `flutter_secure_storage` (`mda.jwt`), attached via interceptor.
- Engine: `mobile/lib/engine/mosaic_engine.dart` is the Dart port of the JS reference engine. It defines `kFamilies`, `kVariants`, `kArtwork` (procedural "Le Semeur"), and the fill/photo painter helpers. The same algorithm is mirrored in `backend/db/seed.sql` and `admin/src/lib/palette.ts` — **changes must be ported across all three.**
- Mosaic widget (`widgets/mosaic.dart`) is **data-driven**: it accepts an optional `ArtworkData` (cells/cols/rows). Screens read `artworkDataProvider` and pass the result in; the default `kArtwork` is used only as a mock fallback.
- Auth flow: client gets a provider token (Firebase Google/Apple, or `dev`) → `POST /api/v1/auth/{provider}` → backend verifies → emits app JWT. `ALLOW_DEV_LOGIN=true` lets the `dev` provider work without Firebase credentials.

## Backend architecture

- Entry: `backend/src/index.ts` registers Fastify plugins (`helmet`, `cors`, `rate-limit`, `@fastify/jwt`, `@fastify/multipart`) and routes under `/api/v1/*` plus admin under `/api/admin/*`. Cron handlers for Mon-activation and Sun-reveal are registered inline.
- All routes use `app.authenticate` (JWT) except `/auth/*` and the public read of `/weeks/current`.
- DB access is **raw SQL via `pg`** (`services/db.ts`). No ORM. Queries are inline in the routes; keep them parameterised.
- Storage: `services/storage.ts` wraps MinIO. EXIF stripping happens here (`sharp().rotate().withMetadata({})`).
- Photo pipeline (`routes/photos.ts`): upload → strip EXIF → MinIO put → dominant colour + ΔE + variance (`color-match.ts`) → contribution rows (one per cell of the variant) → score + streak update → propagate to all the user's instances if `shared=true`.
- Admin (`routes/admin.ts`) is auth-gated by a static `Authorization: Bearer $ADMIN_TOKEN` header — not JWT.

## Admin architecture

- Refine + Ant Design SPA. Token is entered on `/login`, stored in `localStorage`, attached to axios in `services/api.ts`.
- Three main pages:
  - `Dashboard.tsx` — `GET /api/admin/stats` cards.
  - `ArtworksList.tsx` — manage artwork lifecycle (`planned`/`active`/`revealed`/delete).
  - `ArtworkBuilder.tsx` — upload an image, drag-crop to 3:4, slide grid size, the canvas is repixelised live via `lib/pixelize.ts` + `lib/palette.ts` (which mirror the mobile engine). On publish, POSTs `{artwork, families, variants, cells}` to `/api/admin/artworks`.
  - `Gallery.tsx` — moderation (`DELETE /api/admin/photos/:id`).

## Cross-cutting things easy to break

- **Engine triple-port**: any change to `FAMILIES` / `VARIANTS` / cell map / fill style must land in `mobile/lib/engine/mosaic_engine.dart`, `backend/db/seed.sql`, and `admin/src/lib/palette.ts` simultaneously.
- **Bilingual content**: artworks have `title_fr`/`title_en`/`desc_fr`/`desc_en`. The API picks one via `?lang=`. UI strings live in ARB files. Don't hard-code French in routes that return user-facing text.
- **ISO week is UTC.** Don't use the server's local time; use `isoWeek()` / `weekDay()` from `cycle.ts`.
- **No SSH on the deployment target.** Production is Unraid + Compose Manager GUI; updates flow via SMB copy or `git pull` in `/mnt/user/memoire-de-lart`, then "Stack Update". DB migrations have to be runnable from the Unraid db-container console (`psql -f /docker-entrypoint-initdb.d/01_schema.sql`).

## Setup docs to read first
- `backend/README.md` — endpoint table + scoring/matching constants.
- `mobile/AUTH_SETUP.md` — Firebase / Apple Developer setup for real OAuth (otherwise use `dev` login).
- `.env.example` — every secret the stack needs.
