// cycle.ts — weekly UTC cycle helpers (ISO week, day→family, current artwork).

import { db } from './db';

export interface IsoWeek { year: number; week: number; }

/** ISO-8601 week number (UTC). */
export function isoWeek(d: Date = new Date()): IsoWeek {
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const dayNum = (date.getUTCDay() + 6) % 7;            // Mon=0 … Sun=6
  date.setUTCDate(date.getUTCDate() - dayNum + 3);      // nearest Thursday
  const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
  const firstDayNum = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNum + 3);
  const week = 1 + Math.round((date.getTime() - firstThursday.getTime()) / (7 * 86400000));
  return { year: date.getUTCFullYear(), week };
}

/** Day of week, Monday=1 … Sunday=7 (UTC). */
export function weekDay(d: Date = new Date()): number {
  return ((d.getUTCDay() + 6) % 7) + 1;
}

export function artworkId({ year, week }: IsoWeek): string {
  return `w${year}-${String(week).padStart(2, '0')}`;
}

export interface ArtworkRow {
  id: string;
  title_fr: string | null;
  title_en: string | null;
  artist: string | null;
  year_: number | null;
  description_fr: string | null;
  description_en: string | null;
  cols: number;
  rows: number;
  cells: unknown;
  hd_url: string | null;
  status: string;
  iso_year: number;
  iso_week: number;
}

/** The week's artwork (active or revealed) for the given/current date, or null. */
export async function currentArtwork(at: Date = new Date()): Promise<ArtworkRow | null> {
  const { year, week } = isoWeek(at);
  const res = await db.query<ArtworkRow>(
    `SELECT id, title_fr, title_en, artist, year_, description_fr, description_en,
            cols, rows, cells, hd_url, status, iso_year, iso_week
     FROM artworks
     WHERE iso_year = $1 AND iso_week = $2 AND status IN ('active','revealed')
     ORDER BY (status = 'active') DESC
     LIMIT 1`,
    [year, week],
  );
  return res.rows[0] ?? null;
}

/** Monday 00:00 UTC — promote the week's planned artwork to active. */
export async function activateCurrentWeek(): Promise<void> {
  const { year, week } = isoWeek();
  await db.query(
    `UPDATE artworks SET status = 'active' WHERE status = 'planned' AND iso_year = $1 AND iso_week = $2`,
    [year, week],
  );
}

/** Sunday 23:59 UTC — resolve guesses, award bet points, reveal the artwork. */
export async function revealCurrentWeek(): Promise<void> {
  const a = await db.query<{ id: string; title_fr: string | null; title_en: string | null }>(
    `SELECT id, title_fr, title_en FROM artworks WHERE status = 'active'
     ORDER BY iso_year DESC, iso_week DESC LIMIT 1`,
  );
  if (a.rows.length === 0) return;
  const art = a.rows[0]!;

  await db.query(
    `UPDATE guesses SET correct = (LOWER(title_guess) = LOWER(COALESCE($2,''))
                                   OR LOWER(title_guess) = LOWER(COALESCE($3,'')))
     WHERE artwork_id = $1`,
    [art.id, art.title_fr, art.title_en],
  );

  // Award the day-based barème to each instance the correct guessers belong to.
  await db.query(
    `INSERT INTO scores (user_id, instance_id, iso_year, iso_week, points)
     SELECT g.user_id, m.instance_id, w.iso_year, w.iso_week,
            (ARRAY[70,50,35,25,15,10,5])[LEAST(GREATEST(g.day_placed,1),7)]
     FROM guesses g
     JOIN instance_members m ON m.user_id = g.user_id
     CROSS JOIN LATERAL (SELECT iso_year, iso_week FROM artworks WHERE id = g.artwork_id) w
     WHERE g.artwork_id = $1 AND g.correct = TRUE
     ON CONFLICT (user_id, instance_id, iso_year, iso_week)
     DO UPDATE SET points = scores.points + EXCLUDED.points`,
    [art.id],
  );

  await db.query(`UPDATE artworks SET status = 'revealed' WHERE id = $1`, [art.id]);
}

/** Public-facing metadata is hidden until the artwork is revealed. */
export function publicArtwork(a: ArtworkRow, locale: string) {
  const revealed = a.status === 'revealed';
  return {
    id: a.id,
    cols: a.cols,
    rows: a.rows,
    cells: a.cells,
    status: a.status,
    isoYear: a.iso_year,
    isoWeek: a.iso_week,
    // Metadata only after reveal (offline bundle obfuscates separately).
    title: revealed ? (locale === 'en' ? a.title_en : a.title_fr) : null,
    artist: revealed ? a.artist : null,
    year: revealed ? a.year_ : null,
    description: revealed ? (locale === 'en' ? a.description_en : a.description_fr) : null,
    hdUrl: revealed ? a.hd_url : null,
  };
}
