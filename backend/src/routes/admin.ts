// admin.ts — v2 admin API (Bearer ADMIN_TOKEN). Minimal but functional;
// the rich interactive pixelisation/crop UI is Phase 3.

import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import { storage } from '../services/storage';
import { env } from '../config/env';
import { isoWeek } from '../services/cycle';

async function requireAdmin(req: FastifyRequest, reply: FastifyReply) {
  const auth = req.headers.authorization ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!env.ADMIN_TOKEN || token !== env.ADMIN_TOKEN) {
    return reply.code(401).send({ error: 'Admin token requis.' });
  }
}

const artworkSchema = z.object({
  id: z.string(),
  titleFr: z.string().optional(),
  titleEn: z.string().optional(),
  artist: z.string().optional(),
  year: z.number().int().optional(),
  descriptionFr: z.string().optional(),
  descriptionEn: z.string().optional(),
  sourceLicense: z.string().optional(),
  cols: z.number().int().default(12),
  rows: z.number().int().default(16),
  hdUrl: z.string().optional(),
  status: z.enum(['draft', 'planned', 'active', 'revealed']).default('planned'),
  isoYear: z.number().int(),
  isoWeek: z.number().int(),
  cells: z.array(z.object({ i: z.number(), col: z.number(), row: z.number(), family: z.string(), variant: z.string() })),
  families: z.array(z.object({ key: z.string(), day: z.number().int(), nameFr: z.string(), nameEn: z.string() })),
  variants: z.array(z.object({ key: z.string(), familyKey: z.string(), nameFr: z.string(), nameEn: z.string(), hex: z.string() })),
});

export async function adminRoutes(app: FastifyInstance) {
  app.get('/stats', { onRequest: [requireAdmin] }, async (_req, reply) => {
    const { year, week } = isoWeek();
    const [instances, users, photos, weeks] = await Promise.all([
      db.query<{ n: string }>(`SELECT COUNT(*) AS n FROM instances`),
      db.query<{ n: string }>(`SELECT COUNT(*) AS n FROM app_users WHERE deleted_at IS NULL`),
      db.query<{ n: string }>(`SELECT COUNT(*) AS n FROM photos WHERE taken_on = CURRENT_DATE AND deleted_at IS NULL`),
      db.query<{ n: string }>(`SELECT COUNT(*) AS n FROM artworks WHERE status <> 'draft'`),
    ]);
    return reply.send({
      instances: parseInt(instances.rows[0]?.n ?? '0'),
      users: parseInt(users.rows[0]?.n ?? '0'),
      photosToday: parseInt(photos.rows[0]?.n ?? '0'),
      weeksPlanned: parseInt(weeks.rows[0]?.n ?? '0'),
      currentIsoWeek: `${year}-W${week}`,
    });
  });

  // Full artwork payload for the builder edit screen (metadata + cells + palette).
  app.get('/artworks/:id', { onRequest: [requireAdmin] }, async (req, reply) => {
    const id = (req.params as { id: string }).id;
    const a = await db.query(
      `SELECT id, title_fr, title_en, artist, year_, description_fr, description_en,
              source_license, cols, rows, cells, hd_url, status, iso_year, iso_week
       FROM artworks WHERE id = $1`,
      [id],
    );
    if (a.rows.length === 0) return reply.code(404).send({ error: 'Œuvre introuvable.' });
    const [fams, vars] = await Promise.all([
      db.query(`SELECT key, day_, name_fr, name_en FROM color_families WHERE artwork_id = $1`, [id]),
      db.query(`SELECT key, family_key, name_fr, name_en, hex FROM color_variants WHERE artwork_id = $1`, [id]),
    ]);
    const row = a.rows[0]!;
    return reply.send({
      artwork: {
        id: row.id,
        titleFr: row.title_fr, titleEn: row.title_en,
        artist: row.artist, year: row.year_,
        descriptionFr: row.description_fr, descriptionEn: row.description_en,
        sourceLicense: row.source_license,
        cols: row.cols, rows: row.rows,
        cells: row.cells, hdUrl: row.hd_url,
        status: row.status, isoYear: row.iso_year, isoWeek: row.iso_week,
        families: fams.rows.map(f => ({ key: f.key, day: f.day_, nameFr: f.name_fr, nameEn: f.name_en })),
        variants: vars.rows.map(v => ({ key: v.key, familyKey: v.family_key, nameFr: v.name_fr, nameEn: v.name_en, hex: v.hex })),
      },
    });
  });

  app.get('/artworks', { onRequest: [requireAdmin] }, async (_req, reply) => {
    const rows = await db.query(
      `SELECT id, title_fr, artist, year_, status, iso_year, iso_week, created_at
       FROM artworks ORDER BY iso_year DESC NULLS LAST, iso_week DESC NULLS LAST, created_at DESC`,
    );
    return reply.send({ artworks: rows.rows });
  });

  // Create or replace an artwork with its families, variants and cell map.
  app.post('/artworks', { onRequest: [requireAdmin] }, async (req, reply) => {
    const b = artworkSchema.parse(req.body);
    await db.query(
      `INSERT INTO artworks (id, title_fr, title_en, artist, year_, description_fr, description_en,
                             source_license, cols, rows, cells, hd_url, status, iso_year, iso_week)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13,$14,$15)
       ON CONFLICT (id) DO UPDATE SET
         title_fr=$2, title_en=$3, artist=$4, year_=$5, description_fr=$6, description_en=$7,
         source_license=$8, cols=$9, rows=$10, cells=$11::jsonb, hd_url=$12, status=$13,
         iso_year=$14, iso_week=$15`,
      [b.id, b.titleFr ?? null, b.titleEn ?? null, b.artist ?? null, b.year ?? null,
        b.descriptionFr ?? null, b.descriptionEn ?? null, b.sourceLicense ?? null,
        b.cols, b.rows, JSON.stringify(b.cells), b.hdUrl ?? null, b.status, b.isoYear, b.isoWeek],
    );
    await db.query(`DELETE FROM color_families WHERE artwork_id = $1`, [b.id]);
    for (const f of b.families) {
      await db.query(
        `INSERT INTO color_families (artwork_id, key, day_, name_fr, name_en) VALUES ($1,$2,$3,$4,$5)`,
        [b.id, f.key, f.day, f.nameFr, f.nameEn],
      );
    }
    for (const v of b.variants) {
      await db.query(
        `INSERT INTO color_variants (artwork_id, key, family_key, name_fr, name_en, hex)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [b.id, v.key, v.familyKey, v.nameFr, v.nameEn, v.hex],
      );
    }
    return reply.code(201).send({ ok: true, id: b.id });
  });

  app.post('/artworks/:id/status', { onRequest: [requireAdmin] }, async (req, reply) => {
    const id = (req.params as { id: string }).id;
    const status = z.enum(['draft', 'planned', 'active', 'revealed']).parse((req.body as { status: string }).status);
    await db.query(`UPDATE artworks SET status = $2 WHERE id = $1`, [id, status]);
    return reply.send({ ok: true, id, status });
  });

  app.delete('/artworks/:id', { onRequest: [requireAdmin] }, async (req, reply) => {
    const id = (req.params as { id: string }).id;
    await db.query(`DELETE FROM artworks WHERE id = $1`, [id]);
    return reply.code(204).send();
  });

  // Photo gallery / moderation.
  app.get('/gallery', { onRequest: [requireAdmin] }, async (req, reply) => {
    const q = req.query as { instanceId?: string; userId?: string };
    const rows = await db.query(
      `SELECT p.id, p.url, p.taken_on, p.day_, p.target_variant_key, p.delta_e, u.pseudo
       FROM photos p JOIN app_users u ON u.id = p.user_id
       WHERE p.deleted_at IS NULL
         AND ($1::uuid IS NULL OR p.user_id = $1)
         AND ($2::uuid IS NULL OR p.separate_instance_id = $2
              OR EXISTS (SELECT 1 FROM contributions c WHERE c.photo_id = p.id AND c.instance_id = $2))
       ORDER BY p.created_at DESC LIMIT 200`,
      [q.userId ?? null, q.instanceId ?? null],
    );
    return reply.send({ photos: rows.rows });
  });

  // Delete a photo (removes contributions → cells revert to flat colour).
  app.delete('/photos/:id', { onRequest: [requireAdmin] }, async (req, reply) => {
    const id = (req.params as { id: string }).id;
    const row = await db.query<{ storage_key: string }>(`SELECT storage_key FROM photos WHERE id = $1`, [id]);
    if (row.rows[0]) await storage.deletePhoto(row.rows[0].storage_key);
    await db.query(`DELETE FROM photos WHERE id = $1`, [id]);
    return reply.code(204).send();
  });
}
