import type { FastifyInstance, FastifyRequest } from 'fastify';
import { db } from '../services/db';
import { buildZoneState } from '../services/zones';

export async function artworkRoutes(app: FastifyInstance) {

  // GET /api/v1/artworks/current
  // Returns the current month's artwork with full zone + contribution state.
  app.get('/current', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId, instanceId } = req.user;

    const inst = await db.query<{ artwork_id: string }>(
      `SELECT artwork_id FROM instances WHERE id = $1`,
      [instanceId],
    );
    if (inst.rows.length === 0) return reply.code(404).send({ error: 'Instance introuvable.' });
    const artworkId = inst.rows[0]!.artwork_id;

    const [artworkRow, zonesState] = await Promise.all([
      db.query<{ id: string; cols: number; rows: number; cells: unknown; published_at: string | null }>(
        `SELECT id, cols, rows, cells, published_at FROM artworks WHERE id = $1`,
        [artworkId],
      ),
      buildZoneState(artworkId, instanceId, playerId),
    ]);

    if (artworkRow.rows.length === 0) return reply.code(404).send({ error: 'Œuvre introuvable.' });
    const a = artworkRow.rows[0]!;

    const isMonthEnd = isRevealTime(a.published_at);

    return reply.send({
      id:    a.id,
      cols:  a.cols,
      rows:  a.rows,
      cells: a.cells,
      zones: zonesState,
      // Title/artist revealed at month-end publish
      ...(isMonthEnd ? await revealedMeta(artworkId) : {}),
    });
  });

  // GET /api/v1/artworks/current/hint — active hint for the current artwork
  app.get('/current/hint', { onRequest: [app.authenticate] }, async (_req, reply) => {
    const now = new Date();
    const res = await db.query<{ id: string; text: string }>(
      `SELECT h.id, h.text
       FROM artwork_hints h
       JOIN artworks a ON a.id = h.artwork_id
       WHERE h.is_active = true
         AND a.published_at IS NOT NULL
         AND EXTRACT(YEAR  FROM a.published_at) = $1
         AND EXTRACT(MONTH FROM a.published_at) = $2
       ORDER BY h.created_at DESC
       LIMIT 1`,
      [now.getFullYear(), now.getMonth() + 1],
    );
    if (res.rows.length === 0) return reply.send({ hint: null });
    return reply.send({ hint: res.rows[0] });
  });

  // GET /api/v1/artworks/:id — past artwork (profile history)
  app.get('/:id', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const { instanceId, playerId } = req.user;

    const artworkRow = await db.query<{
      id: string; cols: number; rows: number; cells: unknown;
      title: string | null; artist: string | null; description: string | null;
    }>(
      `SELECT id, cols, rows, cells, title, artist, description
       FROM artworks WHERE id = $1 AND published_at IS NOT NULL`,
      [id],
    );
    if (artworkRow.rows.length === 0) return reply.code(404).send({ error: 'Œuvre introuvable.' });
    const a = artworkRow.rows[0]!;

    const zonesState = await buildZoneState(a.id, instanceId, playerId);

    return reply.send({ ...a, zones: zonesState });
  });
}

function isRevealTime(publishedAt: string | null): boolean {
  if (!publishedAt) return false;
  const now = new Date();
  const pub = new Date(publishedAt);
  // Reveal when current date is past the end of the published month
  return now.getFullYear() > pub.getFullYear() ||
    (now.getFullYear() === pub.getFullYear() && now.getMonth() > pub.getMonth());
}

async function revealedMeta(artworkId: string) {
  const res = await db.query<{ title: string; artist: string; description: string }>(
    `SELECT title, artist, description FROM artworks WHERE id = $1`,
    [artworkId],
  );
  return res.rows[0] ?? {};
}
