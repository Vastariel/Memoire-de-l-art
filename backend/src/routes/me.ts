// me.ts — profile, collection, RGPD export & erasure.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import { storage } from '../services/storage';
import { isoWeek } from '../services/cycle';
import { isInCollection } from '../services/scoring';
import { loadUser } from '../services/auth';
import { publicUser } from './auth';
import type { JwtPayload } from '../models/types';

const patchSchema = z.object({
  pseudo: z.string().max(32).optional(),
  locale: z.enum(['fr', 'en']).optional(),
  notifHour: z.number().int().min(0).max(23).optional(),
  notifMinute: z.number().int().min(0).max(59).optional(),
  fcmToken: z.string().optional(),
});

export async function meRoutes(app: FastifyInstance) {
  // Profile + headline stats.
  app.get('/', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const user = await loadUser(userId);
    if (!user) return reply.code(404).send({ error: 'Compte introuvable.' });
    const { year, week } = isoWeek();
    const [pts, streak, revealed, activity] = await Promise.all([
      db.query<{ s: string }>(`SELECT COALESCE(SUM(points),0) AS s FROM scores WHERE user_id=$1 AND iso_year=$2 AND iso_week=$3`, [userId, year, week]),
      db.query<{ c: number }>(`SELECT COALESCE(current_,0) AS c FROM streaks WHERE user_id=$1`, [userId]),
      db.query<{ id: string }>(`SELECT id FROM artworks WHERE status='revealed'`, []),
      // Attendance: distinct days with a photo over the last 28 days.
      db.query<{ d: string }>(
        `SELECT DISTINCT taken_on::text AS d FROM photos
         WHERE user_id = $1 AND deleted_at IS NULL AND taken_on >= CURRENT_DATE - 27`,
        [userId],
      ),
    ]);
    // Works = revealed artworks actually unlocked in the user's collection.
    const unlockedFlags = await Promise.all(revealed.rows.map(r => isInCollection(userId, r.id)));
    return reply.send({
      user: publicUser(user),
      points: parseInt(pts.rows[0]?.s ?? '0'),
      streak: streak.rows[0]?.c ?? 0,
      works: unlockedFlags.filter(Boolean).length,
      activity: activity.rows.map(r => r.d),
    });
  });

  app.patch('/', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const b = patchSchema.parse(req.body ?? {});
    await db.query(
      `UPDATE app_users SET
         pseudo       = COALESCE($2, pseudo),
         locale       = COALESCE($3, locale),
         notif_hour   = COALESCE($4, notif_hour),
         notif_minute = COALESCE($5, notif_minute),
         fcm_token    = COALESCE($6, fcm_token)
       WHERE id = $1`,
      [userId, b.pseudo ?? null, b.locale ?? null, b.notifHour ?? null, b.notifMinute ?? null, b.fcmToken ?? null],
    );
    const user = await loadUser(userId);
    return reply.send({ user: user ? publicUser(user) : null });
  });

  // Personal museum: revealed artworks, unlocked per the collection rule.
  app.get('/collection', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const lang = (req.query as { lang?: string }).lang ?? 'fr';
    const rows = await db.query(
      `SELECT id, title_fr, title_en, artist, year_, iso_week, cols, rows AS rows_, cells
       FROM artworks WHERE status = 'revealed' ORDER BY iso_year DESC, iso_week DESC`,
      [],
    );
    const items = await Promise.all(rows.rows.map(async r => {
      const unlocked = await isInCollection(userId, r.id);
      return {
        id: r.id,
        title: lang === 'en' ? r.title_en : r.title_fr,
        artist: r.artist,
        year: r.year_,
        week: r.iso_week,
        unlocked,
        // Cell map only for unlocked works (locked cards render a placeholder).
        ...(unlocked ? { cols: r.cols, rows: r.rows_, cells: r.cells } : {}),
      };
    }));
    return reply.send({ collection: items });
  });

  // RGPD — data export (JSON + photo URLs).
  app.get('/export', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const [user, photos, guesses, scores] = await Promise.all([
      db.query(`SELECT id, provider, email, pseudo, locale, created_at FROM app_users WHERE id=$1`, [userId]),
      db.query(`SELECT artwork_id, taken_on, day_, target_variant_key, delta_e, url FROM photos WHERE user_id=$1 AND deleted_at IS NULL`, [userId]),
      db.query(`SELECT artwork_id, title_guess, day_placed, correct FROM guesses WHERE user_id=$1`, [userId]),
      db.query(`SELECT instance_id, iso_year, iso_week, points FROM scores WHERE user_id=$1`, [userId]),
    ]);
    return reply
      .header('Content-Disposition', 'attachment; filename="memoire-de-lart-export.json"')
      .send({ user: user.rows[0], photos: photos.rows, guesses: guesses.rows, scores: scores.rows });
  });

  // RGPD — erasure: remove photos from storage, then cascade-delete the user
  // (contributions removed → affected cells revert to flat colour).
  app.delete('/', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    await storage.deleteUserPhotos(userId);
    await db.query(`DELETE FROM app_users WHERE id = $1`, [userId]);
    return reply.code(204).send();
  });
}
