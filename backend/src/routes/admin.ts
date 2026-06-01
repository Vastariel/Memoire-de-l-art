import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db }              from '../services/db';
import { segmentArtwork }  from '../services/segmentation';
import { env }             from '../config/env';

// ── Admin auth ────────────────────────────────────────────────────────────────

async function requireAdmin(req: FastifyRequest, reply: FastifyReply) {
  const auth  = req.headers.authorization ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!env.ADMIN_TOKEN || token !== env.ADMIN_TOKEN) {
    return reply.code(401).send({ error: 'Admin token requis.' });
  }
}

export async function adminRoutes(app: FastifyInstance) {

  // ── Dashboard stats ───────────────────────────────────────────

  app.get('/stats', { onRequest: [requireAdmin] }, async (_req, reply) => {
    const now = new Date();
    const [instances, players, photos, zones] = await Promise.all([
      db.query<{ count: string }>(`SELECT COUNT(*) FROM instances WHERE year_ = $1 AND month_ = $2`,
        [now.getFullYear(), now.getMonth() + 1]),
      db.query<{ count: string }>(`SELECT COUNT(*) FROM players WHERE deleted_at IS NULL`),
      db.query<{ count: string }>(`SELECT COUNT(*) FROM zone_assignments WHERE submitted_at::date = CURRENT_DATE`),
      db.query<{ total: string; filled: string }>(
        `SELECT COUNT(*) as total,
                SUM(CASE WHEN za.submitted_at IS NOT NULL THEN 1 ELSE 0 END) as filled
         FROM zones z
         LEFT JOIN zone_assignments za ON za.zone_id = z.id AND za.artwork_id = z.artwork_id
           AND za.submitted_at IS NOT NULL
         WHERE z.artwork_id IN (
           SELECT id FROM artworks WHERE published_at IS NOT NULL
             AND EXTRACT(YEAR FROM published_at) = $1
             AND EXTRACT(MONTH FROM published_at) = $2
         )`,
        [now.getFullYear(), now.getMonth() + 1]),
    ]);
    return reply.send({
      instances:    parseInt(instances.rows[0]?.count ?? '0'),
      players:      parseInt(players.rows[0]?.count   ?? '0'),
      photosToday:  parseInt(photos.rows[0]?.count    ?? '0'),
      zonesTotal:   parseInt(zones.rows[0]?.total     ?? '0'),
      zonesFilled:  parseInt(zones.rows[0]?.filled    ?? '0'),
    });
  });

  // ── Instances list ────────────────────────────────────────────

  app.get('/instances', { onRequest: [requireAdmin] }, async (_req, reply) => {
    const rows = await db.query(
      `SELECT i.id, i.code, i.name, i.year_, i.month_,
              COUNT(DISTINCT p.id)  AS players,
              COUNT(DISTINCT za.id) FILTER (WHERE za.assigned_date = CURRENT_DATE) AS today_count,
              COUNT(DISTINCT za2.id) FILTER (WHERE za2.submitted_at IS NOT NULL) AS filled
       FROM instances i
       LEFT JOIN players p   ON p.instance_id = i.id AND p.deleted_at IS NULL
       LEFT JOIN zone_assignments za  ON za.instance_id = i.id AND za.assigned_date = CURRENT_DATE
       LEFT JOIN zone_assignments za2 ON za2.instance_id = i.id AND za2.submitted_at IS NOT NULL
       GROUP BY i.id
       ORDER BY i.created_at DESC`,
    );
    return reply.send({ instances: rows.rows });
  });

  // ── Artworks list ─────────────────────────────────────────────

  app.get('/artworks', { onRequest: [requireAdmin] }, async (_req, reply) => {
    const rows = await db.query(
      `SELECT id, title, artist, published_at, created_at,
              (SELECT COUNT(*) FROM zones WHERE artwork_id = artworks.id) AS zone_count
       FROM artworks ORDER BY created_at DESC`);
    return reply.send({ artworks: rows.rows });
  });

  // ── Segment artwork image ─────────────────────────────────────
  // POST /api/admin/artworks/segment
  // Multipart: file (image) + blockSize + maxZones

  app.post('/artworks/segment', { onRequest: [requireAdmin] }, async (req, reply) => {
    let fileBuffer: Buffer | null = null;
    let blockSize  = 16;
    let numZones   = 16;

    const parts = req.parts();
    for await (const part of parts) {
      if (part.type === 'field') {
        if (part.fieldname === 'blockSize') blockSize = parseInt(part.value as string) || 16;
        if (part.fieldname === 'numZones')  numZones  = Math.min(24, Math.max(8, parseInt(part.value as string) || 16));
      } else if (part.type === 'file') {
        const chunks: Buffer[] = [];
        for await (const chunk of part.file) chunks.push(chunk);
        fileBuffer = Buffer.concat(chunks);
      }
    }

    if (!fileBuffer) return reply.code(400).send({ error: 'Image manquante.' });

    const result = await segmentArtwork(fileBuffer, blockSize, numZones);
    return reply.send(result);
  });

  // ── Publish artwork ───────────────────────────────────────────
  // POST /api/admin/artworks/publish

  app.post('/artworks/publish', { onRequest: [requireAdmin] }, async (req, reply) => {
    const body = req.body as {
      id?:          string;
      cols:         number;
      rows:         number;
      cells:        unknown[];
      zones:        Array<{ id: string; pigment: string; cellCount: number; targetHex: string }>;
      title?:       string;
      artist?:      string;
      year?:        number;
      description?: string;
    };

    const now  = new Date();
    const id   = body.id ?? `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;

    // Upsert artwork
    await db.query(
      `INSERT INTO artworks (id, cols, rows, cells, title, artist, description, published_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       ON CONFLICT (id) DO UPDATE SET
         cols = EXCLUDED.cols, rows = EXCLUDED.rows, cells = EXCLUDED.cells,
         title = EXCLUDED.title, artist = EXCLUDED.artist,
         description = EXCLUDED.description, published_at = NOW()`,
      [id, body.cols, body.rows, JSON.stringify(body.cells),
       body.title ?? null, body.artist ?? null, body.description ?? null],
    );

    // Upsert zones
    for (const z of body.zones) {
      await db.query(
        `INSERT INTO zones (id, artwork_id, pigment, cell_count, target_hex)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id, artwork_id) DO UPDATE SET
           pigment = EXCLUDED.pigment, cell_count = EXCLUDED.cell_count,
           target_hex = EXCLUDED.target_hex`,
        [z.id, id, z.pigment, z.cellCount, z.targetHex],
      );
    }

    return reply.code(201).send({ id, zonesCreated: body.zones.length });
  });

  // ── Delete artwork ────────────────────────────────────────────

  app.delete('/artworks/:id', { onRequest: [requireAdmin] }, async (req, reply) => {
    const { id } = req.params as { id: string };
    await db.query(`DELETE FROM artworks WHERE id = $1`, [id]);
    return reply.code(204).send();
  });

  // ── Hints CRUD ────────────────────────────────────────────────

  // GET /api/admin/artworks/:id/hints
  app.get('/artworks/:id/hints', { onRequest: [requireAdmin] }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const rows = await db.query(
      `SELECT id, text, is_active, created_at
       FROM artwork_hints WHERE artwork_id = $1
       ORDER BY created_at DESC`,
      [id],
    );
    return reply.send({ hints: rows.rows });
  });

  // POST /api/admin/artworks/:id/hints
  app.post('/artworks/:id/hints', { onRequest: [requireAdmin] }, async (req, reply) => {
    const { id }   = req.params as { id: string };
    const { text, isActive } = req.body as { text: string; isActive?: boolean };
    if (!text?.trim()) return reply.code(400).send({ error: 'Texte requis.' });
    const res = await db.query<{ id: string }>(
      `INSERT INTO artwork_hints (artwork_id, text, is_active) VALUES ($1, $2, $3) RETURNING id`,
      [id, text.trim(), isActive ?? false],
    );
    return reply.code(201).send({ id: res.rows[0]!.id });
  });

  // PATCH /api/admin/hints/:hintId — toggle active / update text
  app.patch('/hints/:hintId', { onRequest: [requireAdmin] }, async (req, reply) => {
    const { hintId } = req.params as { hintId: string };
    const { text, isActive } = req.body as { text?: string; isActive?: boolean };
    const sets: string[] = [];
    const vals: unknown[] = [];
    let n = 1;
    if (text     !== undefined) { sets.push(`text = $${n++}`);      vals.push(text); }
    if (isActive !== undefined) { sets.push(`is_active = $${n++}`); vals.push(isActive); }
    if (!sets.length) return reply.code(400).send({ error: 'Aucun champ à mettre à jour.' });
    vals.push(hintId);
    await db.query(`UPDATE artwork_hints SET ${sets.join(', ')} WHERE id = $${n}`, vals);
    return reply.send({ updated: true });
  });

  // DELETE /api/admin/hints/:hintId
  app.delete('/hints/:hintId', { onRequest: [requireAdmin] }, async (req, reply) => {
    const { hintId } = req.params as { hintId: string };
    await db.query(`DELETE FROM artwork_hints WHERE id = $1`, [hintId]);
    return reply.code(204).send();
  });
}
