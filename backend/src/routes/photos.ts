// photos.ts — POST /api/v1/photos (+ /catchup) : submit one photo/day.
// Analyses ΔE + variance, stores (EXIF stripped), fans contributions out to the
// user's shared instances (or a single separate instance), scores + streak.

import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { randomUUID } from 'node:crypto';
import { db } from '../services/db';
import { analyzePhoto } from '../services/color-match';
import { storage } from '../services/storage';
import { currentArtwork, isoWeek, weekDay } from '../services/cycle';
import { addPoints, bumpStreak, photoPoints } from '../services/scoring';
import type { JwtPayload } from '../models/types';

interface SubmitFields {
  day: number;
  variantKey: string;
  shared: boolean;
  separateInstanceId: string | null;
}

function readFields(fields: Record<string, unknown>): SubmitFields {
  const val = (k: string): string | undefined => (fields[k] as { value?: string } | undefined)?.value;
  const sep = val('separateInstanceId') || null;
  return {
    day: parseInt(val('day') ?? '0', 10),
    variantKey: val('variantKey') ?? '',
    shared: sep ? false : (val('shared') ?? 'true') !== 'false',
    separateInstanceId: sep,
  };
}

export async function photoRoutes(app: FastifyInstance) {
  app.post('/', { onRequest: [app.authenticate] }, submit);
  // Catch-up uses the same handler with a past `day` field.
  app.post('/catchup', { onRequest: [app.authenticate] }, submit);

  // Public photo proxy: streams the stored JPEG from MinIO. Photo IDs are
  // unguessable UUIDs; non-deleted photos are visible to whoever has the URL
  // (admin gallery, mobile collection, instance contributions).
  app.get('/file/:id', async (req, reply) => {
    const { id } = req.params as { id: string };
    const row = await db.query<{ storage_key: string }>(
      `SELECT storage_key FROM photos WHERE id = $1 AND deleted_at IS NULL`,
      [id],
    );
    const key = row.rows[0]?.storage_key;
    if (!key) return reply.code(404).send({ error: 'Photo introuvable.' });
    try {
      const stream = await storage.getObjectStream(key);
      reply.header('Content-Type', 'image/jpeg');
      reply.header('Cache-Control', 'public, max-age=31536000, immutable');
      return reply.send(stream);
    } catch {
      return reply.code(404).send({ error: 'Photo introuvable.' });
    }
  });
}

async function submit(req: FastifyRequest, reply: FastifyReply) {
  const { userId } = req.user as JwtPayload;
  const data = await (req as FastifyRequest & { file: () => Promise<any> }).file();
  if (!data) return reply.code(400).send({ error: 'Photo manquante.' });
  const buffer: Buffer = await data.toBuffer();
  const f = readFields(data.fields ?? {});
  if (!f.variantKey) return reply.code(400).send({ error: 'variantKey requis.' });

  const a = await currentArtwork();
  if (!a) return reply.code(503).send({ error: 'Aucune œuvre active.' });
  const day = f.day >= 1 && f.day <= 7 ? f.day : weekDay();

  const variant = await db.query<{ hex: string }>(
    `SELECT hex FROM color_variants WHERE artwork_id = $1 AND key = $2`,
    [a.id, f.variantKey],
  );
  if (variant.rows.length === 0) return reply.code(400).send({ error: 'Variante inconnue.' });
  const targetHex = variant.rows[0]!.hex;

  const match = await analyzePhoto(buffer, targetHex);

  const photoId = randomUUID();
  const stored = await storage.uploadPhoto(buffer, userId, photoId);
  const takenOn = new Date().toISOString().slice(0, 10);

  await db.query(
    `INSERT INTO photos (id, user_id, artwork_id, taken_on, day_, target_variant_key,
                         dominant_hex, delta_e, variance, shared, separate_instance_id, storage_key, url)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
    [photoId, userId, a.id, takenOn, day, f.variantKey, match.dominantHex, match.deltaE, match.variance,
      f.shared, f.separateInstanceId, stored.key, stored.url],
  );

  // Target instances: all the user's shared instances, or the one separate instance.
  let targets: string[];
  if (f.separateInstanceId) {
    targets = [f.separateInstanceId];
  } else {
    const rows = await db.query<{ id: string }>(
      `SELECT i.id FROM instances i
       JOIN instance_members m ON m.instance_id = i.id AND m.user_id = $1
       WHERE i.mode = 'shared'`,
      [userId],
    );
    targets = rows.rows.map(r => r.id);
  }

  for (const instanceId of targets) {
    await db.query(
      `INSERT INTO contributions (photo_id, instance_id, artwork_id, user_id, variant_key, crops)
       VALUES ($1, $2, $3, $4, $5, '[]'::jsonb)
       ON CONFLICT (instance_id, artwork_id, variant_key) DO NOTHING`,
      [photoId, instanceId, a.id, userId, f.variantKey],
    );
  }

  // Scoring: streak then per-instance points (base + match bonus × multiplier).
  const streak = await bumpStreak(db, userId, takenOn);
  const pts = photoPoints(match.matchBonus, streak);
  const { year, week } = isoWeek();
  for (const instanceId of targets) {
    await addPoints(db, userId, instanceId, year, week, pts);
  }

  const score = Math.max(0, Math.round(100 - match.deltaE));
  return reply.code(201).send({
    result: {
      photoId, url: stored.url,
      dominantHex: match.dominantHex, deltaE: match.deltaE, variance: match.variance,
      verdict: match.verdict, matchBonus: match.matchBonus,
      score, points: pts, streak,
    },
  });
}
