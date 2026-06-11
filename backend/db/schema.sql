-- Mémoire de l'art — database schema (v2, weekly model)
-- Run with: psql $DATABASE_URL -f db/schema.sql   (idempotent)
--
-- v2 domain: one ARTWORK per ISO week, quantised into a multitude of hues
-- grouped into 7 colour FAMILIES (one per day Mon→Sun); each cell references a
-- VARIANT. Players authenticate via Google/Apple (cross-instance USER), CLAIM a
-- variant (portion), submit one PHOTO/day that fills CONTRIBUTIONS across their
-- instances, react with stamps, place a weekly GUESS, and accrue SCORE/STREAK.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Clean up the v1 (monthly/zones) model — nothing is in production ──────────
DROP TABLE IF EXISTS zone_assignments CASCADE;
DROP TABLE IF EXISTS artwork_hints    CASCADE;
DROP TABLE IF EXISTS zones            CASCADE;
-- v1 `players` and `artworks` are superseded; drop so the new shapes apply.
DROP TABLE IF EXISTS players          CASCADE;

-- ── Users ─────────────────────────────────────────────────────────────────────
-- Cross-instance account. provider+provider_sub is the external identity
-- (Google/Apple/dev). RGPD consent captured at signup.
CREATE TABLE IF NOT EXISTS app_users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider        TEXT NOT NULL,                 -- 'google' | 'apple' | 'dev'
  provider_sub    TEXT NOT NULL,                 -- stable subject id from provider
  email           TEXT,
  pseudo          TEXT,
  avatar_pigment  TEXT NOT NULL DEFAULT 'safran',
  locale          TEXT NOT NULL DEFAULT 'fr',    -- 'fr' | 'en'
  notif_hour      SMALLINT NOT NULL DEFAULT 9,
  notif_minute    SMALLINT NOT NULL DEFAULT 0,
  fcm_token       TEXT,
  consent_rgpd    BOOLEAN NOT NULL DEFAULT FALSE,
  consent_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,                   -- RGPD soft-delete / anonymise
  UNIQUE (provider, provider_sub)
);

-- ── Artworks ──────────────────────────────────────────────────────────────────
-- One per ISO week. Metadata bilingual; title/artist hidden by the API until
-- status = 'revealed'. cells: JSONB array of {i,col,row,family,variant}.
-- crop: JSONB {x,y,w,h} of the 3:4 region taken from the HD source.
CREATE TABLE IF NOT EXISTS artworks (
  id              TEXT PRIMARY KEY,              -- e.g. 'w2026-19'
  title_fr        TEXT,
  title_en        TEXT,
  artist          TEXT,
  year_           INTEGER,
  description_fr  TEXT,
  description_en  TEXT,
  source_license  TEXT,                          -- public-domain source/licence (required to publish)
  cols            INTEGER NOT NULL DEFAULT 12,
  rows            INTEGER NOT NULL DEFAULT 16,
  cells           JSONB   NOT NULL DEFAULT '[]',
  hd_url          TEXT,
  crop            JSONB,
  status          TEXT NOT NULL DEFAULT 'draft', -- draft | planned | active | revealed
  iso_year        INTEGER,
  iso_week        INTEGER,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One scheduled/active/revealed artwork per ISO week.
CREATE UNIQUE INDEX IF NOT EXISTS artworks_isoweek_idx
  ON artworks(iso_year, iso_week) WHERE status <> 'draft';

-- ── Colour families (7 per artwork, one per day Mon→Sun) ──────────────────────
CREATE TABLE IF NOT EXISTS color_families (
  artwork_id  TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  key         TEXT NOT NULL,                     -- 'bleus', 'ors', …
  day_        SMALLINT NOT NULL,                 -- 1 (Mon) … 7 (Sun)
  name_fr     TEXT NOT NULL,
  name_en     TEXT NOT NULL,
  PRIMARY KEY (artwork_id, key)
);

-- ── Colour variants (many per family) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS color_variants (
  artwork_id  TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  key         TEXT NOT NULL,                     -- 'cobalt', 'azur', …
  family_key  TEXT NOT NULL,
  name_fr     TEXT NOT NULL,
  name_en     TEXT NOT NULL,
  hex         TEXT NOT NULL,                     -- '#2D5FA6'
  PRIMARY KEY (artwork_id, key),
  FOREIGN KEY (artwork_id, family_key) REFERENCES color_families(artwork_id, key) ON DELETE CASCADE
);

-- ── Instances ─────────────────────────────────────────────────────────────────
-- A group spanning weeks. mode is deliberately impossible to confuse in the UI.
CREATE TABLE IF NOT EXISTS instances (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code          TEXT UNIQUE NOT NULL,            -- short invite code
  name          TEXT,
  mode          TEXT NOT NULL DEFAULT 'shared',  -- 'shared' | 'separate'
  solo          BOOLEAN NOT NULL DEFAULT FALSE,
  owner_user_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS instances_code_idx ON instances(code);

CREATE TABLE IF NOT EXISTS instance_members (
  instance_id UUID NOT NULL REFERENCES instances(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (instance_id, user_id)
);

-- ── Claims ────────────────────────────────────────────────────────────────────
-- A user takes a variant (portion of the day's family) in an instance,
-- first-come first-served. One claimer per variant per instance per artwork.
CREATE TABLE IF NOT EXISTS claims (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID NOT NULL REFERENCES instances(id) ON DELETE CASCADE,
  artwork_id  TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  variant_key TEXT NOT NULL,
  day_        SMALLINT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (instance_id, artwork_id, variant_key)
);
CREATE INDEX IF NOT EXISTS claims_instance_idx ON claims(instance_id, artwork_id);

-- ── Photos ────────────────────────────────────────────────────────────────────
-- One per user per day (+1 per separate instance). shared=true feeds all the
-- user's shared instances; separate_instance_id binds to a single instance.
CREATE TABLE IF NOT EXISTS photos (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  artwork_id           TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  taken_on             DATE NOT NULL,
  day_                 SMALLINT NOT NULL,        -- targeted colour day (allows catch-up)
  target_variant_key   TEXT NOT NULL,
  dominant_hex         TEXT,
  delta_e              REAL,
  variance             REAL,                     -- image richness (low = flat aplat)
  shared               BOOLEAN NOT NULL DEFAULT TRUE,
  separate_instance_id UUID REFERENCES instances(id) ON DELETE CASCADE,
  storage_key          TEXT NOT NULL,
  url                  TEXT NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at           TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS photos_user_artwork_idx ON photos(user_id, artwork_id);

-- ── Contributions (photo × instance × set of filled cells) ────────────────────
-- crops: JSONB array of {i, ox, oy} — per-cell crop offsets for the vitrail.
CREATE TABLE IF NOT EXISTS contributions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id    UUID NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
  instance_id UUID NOT NULL REFERENCES instances(id) ON DELETE CASCADE,
  artwork_id  TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  variant_key TEXT NOT NULL,
  crops       JSONB NOT NULL DEFAULT '[]',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (instance_id, artwork_id, variant_key)
);
CREATE INDEX IF NOT EXISTS contributions_instance_idx ON contributions(instance_id, artwork_id);

-- ── Reactions (predefined stamps on a contribution) ───────────────────────────
CREATE TABLE IF NOT EXISTS reactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contribution_id UUID NOT NULL REFERENCES contributions(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  stamp           TEXT NOT NULL,                 -- 'bravo'|'audacieux'|'trouvaille'|'pile'|'lumiere'
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (contribution_id, user_id, stamp)
);

-- ── Guesses (mystery-artwork bet, one per user per artwork/week, editable) ─────
CREATE TABLE IF NOT EXISTS guesses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  artwork_id  TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  title_guess TEXT NOT NULL,
  day_placed  SMALLINT NOT NULL,                 -- day the (current) guess was placed → barème
  correct     BOOLEAN,                           -- resolved at reveal
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, artwork_id)
);

-- ── Scores (weekly, per user per instance) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS scores (
  user_id     UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  instance_id UUID NOT NULL REFERENCES instances(id) ON DELETE CASCADE,
  iso_year    INTEGER NOT NULL,
  iso_week    INTEGER NOT NULL,
  points      INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, instance_id, iso_year, iso_week)
);
CREATE INDEX IF NOT EXISTS scores_instance_week_idx ON scores(instance_id, iso_year, iso_week);

-- ── Streaks (consecutive days, per user) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS streaks (
  user_id  UUID PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
  current_ INTEGER NOT NULL DEFAULT 0,
  longest_ INTEGER NOT NULL DEFAULT 0,
  last_day DATE
);
