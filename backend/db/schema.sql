-- Mémoire de l'art — database schema
-- Run with: psql $DATABASE_URL -f db/schema.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Artworks ─────────────────────────────────────────────────────────────────
-- One artwork per month, published by admin.
-- cells is a JSONB array of {index, col, row, zoneId}.
-- Title/artist/description are hidden until published_at.
CREATE TABLE IF NOT EXISTS artworks (
  id            TEXT PRIMARY KEY,          -- e.g. 'jun26'
  cols          INTEGER NOT NULL,
  rows          INTEGER NOT NULL,
  cells         JSONB NOT NULL DEFAULT '[]',
  title         TEXT,
  artist        TEXT,
  description   TEXT,
  thumbnail_url TEXT,
  published_at  TIMESTAMPTZ,               -- NULL = not yet published to players
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Zones ────────────────────────────────────────────────────────────────────
-- Color segments of an artwork. cell_count drives assignment order (ASC = details first).
CREATE TABLE IF NOT EXISTS zones (
  id         TEXT NOT NULL,
  artwork_id TEXT NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  pigment    TEXT NOT NULL,               -- matches Pigment enum key
  cell_count INTEGER NOT NULL,
  target_hex TEXT NOT NULL,              -- e.g. '#9C5A33'
  PRIMARY KEY (id, artwork_id)
);

-- ── Instances ─────────────────────────────────────────────────────────────────
-- A group of players working on the same artwork together.
CREATE TABLE IF NOT EXISTS instances (
  id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  code       TEXT    UNIQUE NOT NULL,    -- 6-char alphanumeric shared code
  artwork_id TEXT    NOT NULL REFERENCES artworks(id),
  year_      INTEGER NOT NULL,
  month_     INTEGER NOT NULL,           -- 1–12
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS instances_code_idx ON instances(code);

-- ── Players ───────────────────────────────────────────────────────────────────
-- Anonymous users identified by UUID + optional pseudo.
CREATE TABLE IF NOT EXISTS players (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id       UUID NOT NULL REFERENCES instances(id) ON DELETE CASCADE,
  pseudo            TEXT,
  avatar_pigment    TEXT NOT NULL,
  fcm_token         TEXT,
  notif_hour        SMALLINT NOT NULL DEFAULT 9,
  notif_minute      SMALLINT NOT NULL DEFAULT 0,
  custom_server_url TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ           -- GDPR soft-delete
);

CREATE INDEX IF NOT EXISTS players_instance_idx
  ON players(instance_id) WHERE deleted_at IS NULL;

-- ── Zone Assignments ──────────────────────────────────────────────────────────
-- One assignment per player per day. submitted_at NULL = not yet done.
-- After submission, photo_url holds the stored object path.
CREATE TABLE IF NOT EXISTS zone_assignments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id       TEXT    NOT NULL,
  artwork_id    TEXT    NOT NULL,
  instance_id   UUID    NOT NULL REFERENCES instances(id),
  player_id     UUID    NOT NULL REFERENCES players(id),
  assigned_date DATE    NOT NULL,
  submitted_at  TIMESTAMPTZ,
  photo_url     TEXT,
  color_delta   REAL,
  blend_mode    TEXT,                    -- 'replace' | 'blend'
  FOREIGN KEY (zone_id, artwork_id) REFERENCES zones(id, artwork_id),
  UNIQUE (zone_id, artwork_id, instance_id, assigned_date)
);

CREATE INDEX IF NOT EXISTS za_instance_date_idx
  ON zone_assignments(instance_id, assigned_date);
CREATE INDEX IF NOT EXISTS za_player_date_idx
  ON zone_assignments(player_id, assigned_date);

-- ── Artwork hints ─────────────────────────────────────────────────────────────
-- Admin can post hints/context snippets about the current artwork at any time.
CREATE TABLE IF NOT EXISTS artwork_hints (
  id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  artwork_id TEXT    NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
  text       TEXT    NOT NULL,
  is_active  BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Instance name column ─────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'instances' AND column_name = 'name'
  ) THEN
    ALTER TABLE instances ADD COLUMN name TEXT;
  END IF;
END;
$$;

-- ── HD URL column ─────────────────────────────────────────────────────────────
-- Added via ALTER if the artworks table already exists without it.
-- schema.sql runs idempotently so we use IF NOT EXISTS pattern via DO block.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'artworks' AND column_name = 'hd_url'
  ) THEN
    ALTER TABLE artworks ADD COLUMN hd_url TEXT;
  END IF;
END;
$$;
