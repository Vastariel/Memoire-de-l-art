// instances.ts — create / join / mine / artwork state / leaderboard.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import { currentArtwork, isoWeek } from '../services/cycle';
import type { JwtPayload } from '../models/types';

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function genCode(len = 6): string {
  let s = '';
  for (let i = 0; i < len; i++) s += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  return s;
}

const createSchema = z.object({
  name: z.string().max(64).optional(),
  mode: z.enum(['shared', 'separate']).default('shared'),
  solo: z.boolean().default(false),
});
const joinSchema = z.object({ code: z.string().min(4).max(8).transform(s => s.toUpperCase()) });

export async function instanceRoutes(app: FastifyInstance) {
  // Create an instance and join it.
  app.post('/', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const body = createSchema.parse(req.body ?? {});

    let code = '';
    for (let i = 0; i < 10; i++) {
      code = genCode();
      const dup = await db.query('SELECT 1 FROM instances WHERE code = $1', [code]);
      if (dup.rows.length === 0) break;
    }
    const inst = await db.query<{ id: string }>(
      `INSERT INTO instances (code, name, mode, solo, owner_user_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [code, body.name ?? null, body.mode, body.solo, userId],
    );
    const id = inst.rows[0]!.id;
    await db.query(`INSERT INTO instance_members (instance_id, user_id) VALUES ($1, $2)`, [id, userId]);
    return reply.code(201).send({
      instance: { id, code, name: body.name ?? null, mode: body.mode, solo: body.solo, members: 1, place: 1 },
    });
  });

  // Join an instance by code; import this week's shared photos as contributions.
  app.post('/join', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const { code } = joinSchema.parse(req.body);
    const inst = await db.query<{ id: string; name: string | null; mode: string; solo: boolean }>(
      `SELECT id, name, mode, solo FROM instances WHERE code = $1`, [code],
    );
    if (inst.rows.length === 0) return reply.code(404).send({ error: 'Instance introuvable.' });
    const it = inst.rows[0]!;
    await db.query(
      `INSERT INTO instance_members (instance_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [it.id, userId],
    );
    await importSharedPhotos(userId, it.id, it.mode);
    const members = await db.query<{ n: string }>(
      `SELECT COUNT(*) AS n FROM instance_members WHERE instance_id = $1`, [it.id],
    );
    return reply.send({
      instance: { id: it.id, code, name: it.name, mode: it.mode, solo: it.solo, members: parseInt(members.rows[0]!.n), place: 1 },
    });
  });

  // The user's instances with member count and weekly rank.
  app.get('/mine', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const { year, week } = isoWeek();
    const rows = await db.query(
      `WITH ranked AS (
         SELECT instance_id, user_id, RANK() OVER (PARTITION BY instance_id ORDER BY points DESC) AS rnk
         FROM scores WHERE iso_year = $2 AND iso_week = $3
       )
       SELECT i.id, i.code, i.name, i.mode, i.solo,
         (SELECT COUNT(*) FROM instance_members m2 WHERE m2.instance_id = i.id) AS members,
         COALESCE((SELECT rnk FROM ranked r WHERE r.instance_id = i.id AND r.user_id = $1), 1) AS place
       FROM instances i
       JOIN instance_members m ON m.instance_id = i.id AND m.user_id = $1
       ORDER BY i.created_at`,
      [userId, year, week],
    );
    return reply.send({
      instances: rows.rows.map(r => ({
        id: r.id, code: r.code, name: r.name, mode: r.mode, solo: r.solo,
        members: parseInt(r.members), place: parseInt(r.place),
      })),
    });
  });

  // Cell state of the artwork inside an instance (for the vitrail).
  app.get('/:id/artwork', { onRequest: [app.authenticate] }, async (req, reply) => {
    const id = (req.params as { id: string }).id;
    const a = await currentArtwork();
    if (!a) return reply.code(503).send({ error: 'Aucune œuvre active.' });
    const contribs = await db.query(
      `SELECT c.variant_key, c.crops, u.pseudo, u.avatar_pigment AS pig, p.url, p.delta_e
       FROM contributions c
       JOIN photos p ON p.id = c.photo_id
       JOIN app_users u ON u.id = c.user_id
       WHERE c.instance_id = $1 AND c.artwork_id = $2`,
      [id, a.id],
    );
    return reply.send({
      artwork: { id: a.id, cols: a.cols, rows: a.rows, cells: a.cells },
      filled: contribs.rows.map(c => ({
        variantKey: c.variant_key, pseudo: c.pseudo, pig: c.pig, url: c.url, deltaE: c.delta_e, crops: c.crops,
      })),
    });
  });

  // Weekly leaderboard for an instance.
  app.get('/:id/leaderboard', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const id = (req.params as { id: string }).id;
    const a = await currentArtwork();
    const { year, week } = isoWeek();
    const rows = await db.query(
      `SELECT u.id, u.pseudo, u.avatar_pigment AS pig,
              COALESCE(s.points, 0) AS points,
              COALESCE(st.current_, 0) AS streak,
              (SELECT COUNT(DISTINCT day_) FROM photos ph
                 WHERE ph.user_id = u.id AND ph.artwork_id = $3 AND ph.deleted_at IS NULL) AS photos,
              (u.id = $1) AS you
       FROM instance_members m
       JOIN app_users u ON u.id = m.user_id
       LEFT JOIN scores s ON s.user_id = u.id AND s.instance_id = $2 AND s.iso_year = $4 AND s.iso_week = $5
       LEFT JOIN streaks st ON st.user_id = u.id
       WHERE m.instance_id = $2
       ORDER BY points DESC, u.created_at`,
      [userId, id, a?.id ?? '', year, week],
    );
    return reply.send({
      leaderboard: rows.rows.map(r => ({
        pseudo: r.pseudo ?? 'Anonyme', pig: r.pig, points: parseInt(r.points),
        streak: parseInt(r.streak), photos: parseInt(r.photos), you: r.you,
      })),
    });
  });
}

// On joining mid-week, the user's shared photos already taken are imported into
// the new instance (as contributions) if their variant isn't already filled.
async function importSharedPhotos(userId: string, instanceId: string, mode: string): Promise<void> {
  if (mode !== 'shared') return;
  const a = await currentArtwork();
  if (!a) return;
  await db.query(
    `INSERT INTO contributions (photo_id, instance_id, artwork_id, user_id, variant_key, crops)
     SELECT p.id, $2, p.artwork_id, p.user_id, p.target_variant_key, '[]'::jsonb
     FROM photos p
     WHERE p.user_id = $1 AND p.artwork_id = $3 AND p.shared = TRUE AND p.deleted_at IS NULL
     ON CONFLICT (instance_id, artwork_id, variant_key) DO NOTHING`,
    [userId, instanceId, a.id],
  );
}
