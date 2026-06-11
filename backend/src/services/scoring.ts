// scoring.ts — points, streaks, bet barème, collection rule.
// Constants are intentionally simple/configurable.

import { db } from './db';

export const PHOTO_POINTS = 10;          // posting a photo
export const INSTANCE_COMPLETE_BONUS = 50; // instance reaches 100%
export const BET_BAREME = [70, 50, 35, 25, 15, 10, 5]; // by day Mon→Sun

/** Streak multiplier ×1.1 per consecutive day, capped ×1.5. */
export function streakMultiplier(days: number): number {
  return Math.min(1.5, 1 + 0.1 * Math.max(0, days));
}

/** Points for a photo: (base + match bonus) × streak multiplier. */
export function photoPoints(matchBonus: number, streakDays: number): number {
  return Math.round((PHOTO_POINTS + matchBonus) * streakMultiplier(streakDays));
}

export function betPoints(dayPlaced: number): number {
  return BET_BAREME[Math.max(0, Math.min(6, dayPlaced - 1))] ?? 5;
}

type Q = Pick<typeof db, 'query'>;

/** Add weekly points for a user in an instance (upsert). */
export async function addPoints(
  q: Q, userId: string, instanceId: string, isoYear: number, isoWeek: number, pts: number,
): Promise<void> {
  await q.query(
    `INSERT INTO scores (user_id, instance_id, iso_year, iso_week, points)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (user_id, instance_id, iso_year, iso_week)
     DO UPDATE SET points = scores.points + EXCLUDED.points`,
    [userId, instanceId, isoYear, isoWeek, pts],
  );
}

/** Bump the consecutive-day streak; returns the new current streak. */
export async function bumpStreak(q: Q, userId: string, takenOn: string): Promise<number> {
  const res = await q.query<{ current_: number; last_day: string | null }>(
    `SELECT current_, last_day FROM streaks WHERE user_id = $1`, [userId],
  );
  const prev = res.rows[0];
  let next = 1;
  if (prev?.last_day) {
    const last = new Date(prev.last_day + 'T00:00:00Z');
    const cur = new Date(takenOn + 'T00:00:00Z');
    const diff = Math.round((cur.getTime() - last.getTime()) / 86400000);
    if (diff === 0) next = prev.current_;          // already counted today
    else if (diff === 1) next = prev.current_ + 1; // consecutive
    else next = 1;                                 // reset
  }
  await q.query(
    `INSERT INTO streaks (user_id, current_, longest_, last_day)
     VALUES ($1, $2, $2, $3)
     ON CONFLICT (user_id) DO UPDATE
       SET current_ = $2, longest_ = GREATEST(streaks.longest_, $2), last_day = $3`,
    [userId, next, takenOn],
  );
  return next;
}

/**
 * Collection eligibility for a user/artwork: 7 personal photos this week AND
 * at least one non-solo instance completed 100%. Solo does not count.
 */
export async function isInCollection(userId: string, artworkId: string): Promise<boolean> {
  const photos = await db.query<{ n: string }>(
    `SELECT COUNT(DISTINCT day_) AS n FROM photos
     WHERE user_id = $1 AND artwork_id = $2 AND deleted_at IS NULL`,
    [userId, artworkId],
  );
  if (parseInt(photos.rows[0]?.n ?? '0') < 7) return false;

  // A non-solo instance the user belongs to where every variant is filled.
  const complete = await db.query<{ ok: boolean }>(
    `SELECT EXISTS (
       SELECT 1 FROM instances i
       JOIN instance_members m ON m.instance_id = i.id AND m.user_id = $1
       WHERE i.solo = FALSE
         AND (SELECT COUNT(*) FROM color_variants v WHERE v.artwork_id = $2)
             = (SELECT COUNT(*) FROM contributions c WHERE c.instance_id = i.id AND c.artwork_id = $2)
     ) AS ok`,
    [userId, artworkId],
  );
  return complete.rows[0]?.ok ?? false;
}
