// days.ts — GET /api/v1/days/today : family of the day + variants + claims.

import type { FastifyInstance } from 'fastify';
import { db } from '../services/db';
import { currentArtwork, weekDay } from '../services/cycle';
import type { JwtPayload } from '../models/types';

export async function dayRoutes(app: FastifyInstance) {
  app.get('/today', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { userId } = req.user as JwtPayload;
    const a = await currentArtwork();
    if (!a) return reply.code(503).send({ error: 'Aucune œuvre active cette semaine.' });

    const day = weekDay();
    const fam = await db.query<{ key: string; name_fr: string; name_en: string }>(
      `SELECT key, name_fr, name_en FROM color_families WHERE artwork_id = $1 AND day_ = $2`,
      [a.id, day],
    );
    if (fam.rows.length === 0) return reply.send({ weekDay: day, family: null, variants: [] });
    const family = fam.rows[0]!;

    const cells = (a.cells as { variant: string }[]) ?? [];
    const variants = await db.query<{ key: string; name_fr: string; name_en: string; hex: string }>(
      `SELECT key, name_fr, name_en, hex FROM color_variants WHERE artwork_id = $1 AND family_key = $2`,
      [a.id, family.key],
    );

    // The user's instances and which variants are already claimed there.
    const claims = await db.query<{ instance_id: string; variant_key: string; pseudo: string | null }>(
      `SELECT c.instance_id, c.variant_key, u.pseudo
       FROM claims c
       JOIN instance_members m ON m.instance_id = c.instance_id AND m.user_id = $1
       JOIN app_users u ON u.id = c.user_id
       WHERE c.artwork_id = $2 AND c.day_ = $3`,
      [userId, a.id, day],
    );

    return reply.send({
      weekDay: day,
      family: { key: family.key, nameFr: family.name_fr, nameEn: family.name_en },
      variants: variants.rows.map(v => ({
        key: v.key,
        nameFr: v.name_fr,
        nameEn: v.name_en,
        hex: v.hex,
        blocks: cells.filter(c => c.variant === v.key).length,
      })),
      claims: claims.rows.map(c => ({ instanceId: c.instance_id, variantKey: c.variant_key, byPseudo: c.pseudo })),
    });
  });
}
