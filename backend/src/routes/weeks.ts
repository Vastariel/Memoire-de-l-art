// weeks.ts — GET /api/v1/weeks/current  +  /current/bundle (offline solo).

import type { FastifyInstance } from 'fastify';
import { db } from '../services/db';
import { currentArtwork, publicArtwork, weekDay } from '../services/cycle';

async function familiesAndVariants(artworkId: string) {
  const [families, variants] = await Promise.all([
    db.query(`SELECT key, day_ AS day, name_fr, name_en FROM color_families WHERE artwork_id = $1 ORDER BY day_`, [artworkId]),
    db.query(`SELECT key, family_key, name_fr, name_en, hex FROM color_variants WHERE artwork_id = $1`, [artworkId]),
  ]);
  return {
    families: families.rows.map(f => ({ key: f.key, day: f.day, nameFr: f.name_fr, nameEn: f.name_en })),
    variants: variants.rows.map(v => ({ key: v.key, familyKey: v.family_key, nameFr: v.name_fr, nameEn: v.name_en, hex: v.hex })),
  };
}

export async function weekRoutes(app: FastifyInstance) {
  // Current week's artwork (metadata hidden until revealed).
  app.get('/current', async (req, reply) => {
    const lang = (req.query as { lang?: string }).lang ?? 'fr';
    const a = await currentArtwork();
    if (!a) return reply.code(503).send({ error: 'Aucune œuvre active cette semaine.' });
    const fv = await familiesAndVariants(a.id);
    return reply.send({ artwork: publicArtwork(a, lang), ...fv, weekDay: weekDay() });
  });

  // Offline bundle (solo): artwork + families/variants + an obfuscated reveal
  // payload (base64 — acceptable v1 obfuscation, decoded client-side at reveal).
  app.get('/current/bundle', async (req, reply) => {
    const lang = (req.query as { lang?: string }).lang ?? 'fr';
    const a = await currentArtwork();
    if (!a) return reply.code(503).send({ error: 'Aucune œuvre active cette semaine.' });
    const fv = await familiesAndVariants(a.id);
    const reveal = Buffer.from(JSON.stringify({
      title: lang === 'en' ? a.title_en : a.title_fr,
      artist: a.artist,
      year: a.year_,
      description: lang === 'en' ? a.description_en : a.description_fr,
      hdUrl: a.hd_url,
    })).toString('base64');
    return reply.send({ artwork: publicArtwork(a, lang), ...fv, weekDay: weekDay(), revealObfuscated: reveal });
  });
}
