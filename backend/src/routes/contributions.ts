// contributions.ts — POST /api/v1/contributions/:id/reactions : toggle a stamp.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import type { JwtPayload } from '../models/types';

const STAMPS = ['bravo', 'audacieux', 'trouvaille', 'pile', 'lumiere'];
const schema = z.object({ stamp: z.enum(['bravo', 'audacieux', 'trouvaille', 'pile', 'lumiere']) });

export async function contributionRoutes(app: FastifyInstance) {
  app.post('/:id/reactions', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const contributionId = (req.params as { id: string }).id;
    const { stamp } = schema.parse(req.body);

    const existing = await db.query<{ id: string }>(
      `SELECT id FROM reactions WHERE contribution_id = $1 AND user_id = $2 AND stamp = $3`,
      [contributionId, userId, stamp],
    );
    let active: boolean;
    if (existing.rows.length > 0) {
      await db.query(`DELETE FROM reactions WHERE id = $1`, [existing.rows[0]!.id]);
      active = false;
    } else {
      await db.query(
        `INSERT INTO reactions (contribution_id, user_id, stamp) VALUES ($1, $2, $3)
         ON CONFLICT (contribution_id, user_id, stamp) DO NOTHING`,
        [contributionId, userId, stamp],
      );
      active = true;
    }

    const counts = await db.query<{ stamp: string; n: string }>(
      `SELECT stamp, COUNT(*) AS n FROM reactions WHERE contribution_id = $1 GROUP BY stamp`,
      [contributionId],
    );
    const byStamp: Record<string, number> = {};
    for (const s of STAMPS) byStamp[s] = 0;
    for (const r of counts.rows) byStamp[r.stamp] = parseInt(r.n);
    return reply.send({ active, stamp, counts: byStamp });
  });
}
