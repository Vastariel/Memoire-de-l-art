import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';

const updateSchema = z.object({
  pseudo:           z.string().max(32).optional(),
  fcmToken:         z.string().optional(),
  notifHour:        z.number().int().min(0).max(23).optional(),
  notifMinute:      z.number().int().refine(m => [0, 15, 30, 45].includes(m)).optional(),
  customServerUrl:  z.string().url().optional().nullable(),
});

export async function playerRoutes(app: FastifyInstance) {

  // GET /api/v1/players/me
  app.get('/me', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId } = req.user;
    const res = await db.query(
      `SELECT id, pseudo, avatar_pigment, notif_hour, notif_minute, custom_server_url
       FROM players WHERE id = $1 AND deleted_at IS NULL`,
      [playerId],
    );
    if (res.rows.length === 0) return reply.code(404).send({ error: 'Joueur introuvable.' });
    return reply.send(res.rows[0]);
  });

  // PATCH /api/v1/players/me
  app.patch('/me', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId } = req.user;
    const body = updateSchema.parse(req.body);

    const sets: string[] = [];
    const vals: unknown[] = [];
    let n = 1;

    if (body.pseudo           !== undefined) { sets.push(`pseudo = $${n++}`);            vals.push(body.pseudo); }
    if (body.fcmToken         !== undefined) { sets.push(`fcm_token = $${n++}`);         vals.push(body.fcmToken); }
    if (body.notifHour        !== undefined) { sets.push(`notif_hour = $${n++}`);        vals.push(body.notifHour); }
    if (body.notifMinute      !== undefined) { sets.push(`notif_minute = $${n++}`);      vals.push(body.notifMinute); }
    if (body.customServerUrl  !== undefined) { sets.push(`custom_server_url = $${n++}`); vals.push(body.customServerUrl); }

    if (sets.length === 0) return reply.send({ updated: false });

    vals.push(playerId);
    await db.query(
      `UPDATE players SET ${sets.join(', ')} WHERE id = $${n} AND deleted_at IS NULL`,
      vals,
    );

    return reply.send({ updated: true });
  });

  // DELETE /api/v1/players/me — GDPR erasure (soft-delete)
  app.delete('/me', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId } = req.user;
    await db.query(
      `UPDATE players SET deleted_at = NOW(), pseudo = NULL, fcm_token = NULL
       WHERE id = $1`,
      [playerId],
    );
    return reply.code(204).send();
  });

  // GET /api/v1/players/me/history
  app.get('/me/history', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId } = req.user;

    const res = await db.query(
      `SELECT DISTINCT a.id, a.title, a.artist, a.thumbnail_url, a.published_at
       FROM artworks a
       JOIN instances i ON i.artwork_id = a.id
       JOIN players p   ON p.instance_id = i.id AND p.id = $1
       JOIN zone_assignments za ON za.player_id = p.id AND za.submitted_at IS NOT NULL
       ORDER BY a.published_at DESC NULLS LAST`,
      [playerId],
    );

    return reply.send({ artworks: res.rows });
  });
}
