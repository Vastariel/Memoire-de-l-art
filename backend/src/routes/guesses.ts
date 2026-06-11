// guesses.ts — POST /api/v1/guesses : place/update the weekly mystery bet.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import { currentArtwork, weekDay } from '../services/cycle';
import { betPoints } from '../services/scoring';
import type { JwtPayload } from '../models/types';

const schema = z.object({ titleGuess: z.string().min(1).max(120) });

export async function guessRoutes(app: FastifyInstance) {
  app.post('/', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const { titleGuess } = schema.parse(req.body);
    const a = await currentArtwork();
    if (!a) return reply.code(503).send({ error: 'Aucune œuvre active.' });
    if (a.status === 'revealed') return reply.code(409).send({ error: 'Œuvre déjà révélée.' });

    // One bet per artwork, editable. day_placed keeps the first placement
    // (early commitment is rewarded by the barème).
    const res = await db.query<{ day_placed: number }>(
      `INSERT INTO guesses (user_id, artwork_id, title_guess, day_placed)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, artwork_id) DO UPDATE
         SET title_guess = EXCLUDED.title_guess, updated_at = NOW()
       RETURNING day_placed`,
      [userId, a.id, titleGuess, weekDay()],
    );
    const dayPlaced = res.rows[0]!.day_placed;
    return reply.send({ ok: true, dayPlaced, potentialPoints: betPoints(dayPlaced) });
  });
}
