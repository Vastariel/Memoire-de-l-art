"use strict";
// admin.ts — v2 admin API (Bearer ADMIN_TOKEN). Minimal but functional;
// the rich interactive pixelisation/crop UI is Phase 3.
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminRoutes = adminRoutes;
const zod_1 = require("zod");
const db_1 = require("../services/db");
const storage_1 = require("../services/storage");
const env_1 = require("../config/env");
const cycle_1 = require("../services/cycle");
async function requireAdmin(req, reply) {
    const auth = req.headers.authorization ?? '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!env_1.env.ADMIN_TOKEN || token !== env_1.env.ADMIN_TOKEN) {
        return reply.code(401).send({ error: 'Admin token requis.' });
    }
}
const artworkSchema = zod_1.z.object({
    id: zod_1.z.string(),
    titleFr: zod_1.z.string().optional(),
    titleEn: zod_1.z.string().optional(),
    artist: zod_1.z.string().optional(),
    year: zod_1.z.number().int().optional(),
    descriptionFr: zod_1.z.string().optional(),
    descriptionEn: zod_1.z.string().optional(),
    sourceLicense: zod_1.z.string().optional(),
    cols: zod_1.z.number().int().default(12),
    rows: zod_1.z.number().int().default(16),
    hdUrl: zod_1.z.string().optional(),
    status: zod_1.z.enum(['draft', 'planned', 'active', 'revealed']).default('planned'),
    isoYear: zod_1.z.number().int(),
    isoWeek: zod_1.z.number().int(),
    cells: zod_1.z.array(zod_1.z.object({ i: zod_1.z.number(), col: zod_1.z.number(), row: zod_1.z.number(), family: zod_1.z.string(), variant: zod_1.z.string() })),
    families: zod_1.z.array(zod_1.z.object({ key: zod_1.z.string(), day: zod_1.z.number().int(), nameFr: zod_1.z.string(), nameEn: zod_1.z.string() })),
    variants: zod_1.z.array(zod_1.z.object({ key: zod_1.z.string(), familyKey: zod_1.z.string(), nameFr: zod_1.z.string(), nameEn: zod_1.z.string(), hex: zod_1.z.string() })),
});
async function adminRoutes(app) {
    app.get('/stats', { onRequest: [requireAdmin] }, async (_req, reply) => {
        const { year, week } = (0, cycle_1.isoWeek)();
        const [instances, users, photos, weeks] = await Promise.all([
            db_1.db.query(`SELECT COUNT(*) AS n FROM instances`),
            db_1.db.query(`SELECT COUNT(*) AS n FROM app_users WHERE deleted_at IS NULL`),
            db_1.db.query(`SELECT COUNT(*) AS n FROM photos WHERE taken_on = CURRENT_DATE AND deleted_at IS NULL`),
            db_1.db.query(`SELECT COUNT(*) AS n FROM artworks WHERE status <> 'draft'`),
        ]);
        return reply.send({
            instances: parseInt(instances.rows[0]?.n ?? '0'),
            users: parseInt(users.rows[0]?.n ?? '0'),
            photosToday: parseInt(photos.rows[0]?.n ?? '0'),
            weeksPlanned: parseInt(weeks.rows[0]?.n ?? '0'),
            currentIsoWeek: `${year}-W${week}`,
        });
    });
    app.get('/artworks', { onRequest: [requireAdmin] }, async (_req, reply) => {
        const rows = await db_1.db.query(`SELECT id, title_fr, artist, year_, status, iso_year, iso_week, created_at
       FROM artworks ORDER BY iso_year DESC NULLS LAST, iso_week DESC NULLS LAST, created_at DESC`);
        return reply.send({ artworks: rows.rows });
    });
    // Create or replace an artwork with its families, variants and cell map.
    app.post('/artworks', { onRequest: [requireAdmin] }, async (req, reply) => {
        const b = artworkSchema.parse(req.body);
        await db_1.db.query(`INSERT INTO artworks (id, title_fr, title_en, artist, year_, description_fr, description_en,
                             source_license, cols, rows, cells, hd_url, status, iso_year, iso_week)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13,$14,$15)
       ON CONFLICT (id) DO UPDATE SET
         title_fr=$2, title_en=$3, artist=$4, year_=$5, description_fr=$6, description_en=$7,
         source_license=$8, cols=$9, rows=$10, cells=$11::jsonb, hd_url=$12, status=$13,
         iso_year=$14, iso_week=$15`, [b.id, b.titleFr ?? null, b.titleEn ?? null, b.artist ?? null, b.year ?? null,
            b.descriptionFr ?? null, b.descriptionEn ?? null, b.sourceLicense ?? null,
            b.cols, b.rows, JSON.stringify(b.cells), b.hdUrl ?? null, b.status, b.isoYear, b.isoWeek]);
        await db_1.db.query(`DELETE FROM color_families WHERE artwork_id = $1`, [b.id]);
        for (const f of b.families) {
            await db_1.db.query(`INSERT INTO color_families (artwork_id, key, day_, name_fr, name_en) VALUES ($1,$2,$3,$4,$5)`, [b.id, f.key, f.day, f.nameFr, f.nameEn]);
        }
        for (const v of b.variants) {
            await db_1.db.query(`INSERT INTO color_variants (artwork_id, key, family_key, name_fr, name_en, hex)
         VALUES ($1,$2,$3,$4,$5,$6)`, [b.id, v.key, v.familyKey, v.nameFr, v.nameEn, v.hex]);
        }
        return reply.code(201).send({ ok: true, id: b.id });
    });
    app.post('/artworks/:id/status', { onRequest: [requireAdmin] }, async (req, reply) => {
        const id = req.params.id;
        const status = zod_1.z.enum(['draft', 'planned', 'active', 'revealed']).parse(req.body.status);
        await db_1.db.query(`UPDATE artworks SET status = $2 WHERE id = $1`, [id, status]);
        return reply.send({ ok: true, id, status });
    });
    app.delete('/artworks/:id', { onRequest: [requireAdmin] }, async (req, reply) => {
        const id = req.params.id;
        await db_1.db.query(`DELETE FROM artworks WHERE id = $1`, [id]);
        return reply.code(204).send();
    });
    // Photo gallery / moderation.
    app.get('/gallery', { onRequest: [requireAdmin] }, async (req, reply) => {
        const q = req.query;
        const rows = await db_1.db.query(`SELECT p.id, p.url, p.taken_on, p.day_, p.target_variant_key, p.delta_e, u.pseudo
       FROM photos p JOIN app_users u ON u.id = p.user_id
       WHERE p.deleted_at IS NULL
         AND ($1::uuid IS NULL OR p.user_id = $1)
         AND ($2::uuid IS NULL OR p.separate_instance_id = $2
              OR EXISTS (SELECT 1 FROM contributions c WHERE c.photo_id = p.id AND c.instance_id = $2))
       ORDER BY p.created_at DESC LIMIT 200`, [q.userId ?? null, q.instanceId ?? null]);
        return reply.send({ photos: rows.rows });
    });
    // Delete a photo (removes contributions → cells revert to flat colour).
    app.delete('/photos/:id', { onRequest: [requireAdmin] }, async (req, reply) => {
        const id = req.params.id;
        const row = await db_1.db.query(`SELECT storage_key FROM photos WHERE id = $1`, [id]);
        if (row.rows[0])
            await storage_1.storage.deletePhoto(row.rows[0].storage_key);
        await db_1.db.query(`DELETE FROM photos WHERE id = $1`, [id]);
        return reply.code(204).send();
    });
}
//# sourceMappingURL=admin.js.map