// guesses.ts — POST /api/v1/guesses : place/update the weekly mystery bet.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import { currentArtwork, weekDay } from '../services/cycle';
import { betPoints } from '../services/scoring';
import type { JwtPayload } from '../models/types';

const schema = z.object({ titleGuess: z.string().min(1).max(120) });

// Deterministic-per-week shuffle: same artwork always exposes the same 4
// options in the same order, so the client doesn't see them flip on refresh.
function seededShuffle<T>(arr: T[], seed: string): T[] {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) h = (h ^ seed.charCodeAt(i)) * 16777619 >>> 0;
  const out = arr.slice();
  for (let i = out.length - 1; i > 0; i--) {
    h = (h * 1664525 + 1013904223) >>> 0;
    const j = h % (i + 1);
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

export async function guessRoutes(app: FastifyInstance) {
  // The caller's current bet on this week's artwork (null if none placed).
  // `correct` stays null until the Sunday reveal settles it.
  app.get('/mine', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const a = await currentArtwork();
    if (!a) return reply.send({ guess: null });
    const r = await db.query<{ title_guess: string; day_placed: number; correct: boolean | null }>(
      `SELECT title_guess, day_placed, correct FROM guesses WHERE user_id = $1 AND artwork_id = $2`,
      [userId, a.id],
    );
    const g = r.rows[0];
    if (!g) return reply.send({ guess: null });
    return reply.send({
      guess: {
        titleGuess: g.title_guess,
        dayPlaced: g.day_placed,
        correct: g.correct,
        points: betPoints(g.day_placed),
      },
    });
  });

  // Options for the mystery bet UI: the real title + 3 decoys, shuffled.
  app.get('/options', { onRequest: [app.authenticate] }, async (_req, reply) => {
    const a = await currentArtwork();
    if (!a) return reply.send({ options: [] });
    const correct = await db.query<{ id: string; title_fr: string | null; title_en: string | null; artist: string | null; year_: number | null }>(
      `SELECT id, title_fr, title_en, artist, year_ FROM artworks WHERE id = $1`, [a.id],
    );
    const decoys = await db.query<{ id: string; title_fr: string | null; title_en: string | null; artist: string | null; year_: number | null }>(
      `SELECT id, title_fr, title_en, artist, year_ FROM artworks
       WHERE id <> $1 AND title_fr IS NOT NULL ORDER BY RANDOM() LIMIT 3`,
      [a.id],
    );
    const all = [...correct.rows, ...decoys.rows].map(r => ({
      id: r.id, title: r.title_fr ?? r.title_en ?? '—', artist: r.artist ?? '—', year: r.year_ ?? 0,
    }));
    return reply.send({ options: seededShuffle(all, a.id) });
  });

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
