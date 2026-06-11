"use strict";
// me.ts — profile, collection, RGPD export & erasure.
Object.defineProperty(exports, "__esModule", { value: true });
exports.meRoutes = meRoutes;
const zod_1 = require("zod");
const db_1 = require("../services/db");
const storage_1 = require("../services/storage");
const cycle_1 = require("../services/cycle");
const scoring_1 = require("../services/scoring");
const auth_1 = require("../services/auth");
const auth_2 = require("./auth");
const patchSchema = zod_1.z.object({
    pseudo: zod_1.z.string().max(32).optional(),
    locale: zod_1.z.enum(['fr', 'en']).optional(),
    notifHour: zod_1.z.number().int().min(0).max(23).optional(),
    notifMinute: zod_1.z.number().int().min(0).max(59).optional(),
    fcmToken: zod_1.z.string().optional(),
});
async function meRoutes(app) {
    // Profile + headline stats.
    app.get('/', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const user = await (0, auth_1.loadUser)(userId);
        if (!user)
            return reply.code(404).send({ error: 'Compte introuvable.' });
        const { year, week } = (0, cycle_1.isoWeek)();
        const [pts, streak, works] = await Promise.all([
            db_1.db.query(`SELECT COALESCE(SUM(points),0) AS s FROM scores WHERE user_id=$1 AND iso_year=$2 AND iso_week=$3`, [userId, year, week]),
            db_1.db.query(`SELECT COALESCE(current_,0) AS c FROM streaks WHERE user_id=$1`, [userId]),
            db_1.db.query(`SELECT COUNT(*) AS n FROM artworks WHERE status='revealed'`, []),
        ]);
        return reply.send({
            user: (0, auth_2.publicUser)(user),
            points: parseInt(pts.rows[0]?.s ?? '0'),
            streak: streak.rows[0]?.c ?? 0,
            works: parseInt(works.rows[0]?.n ?? '0'),
        });
    });
    app.patch('/', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const b = patchSchema.parse(req.body ?? {});
        await db_1.db.query(`UPDATE app_users SET
         pseudo       = COALESCE($2, pseudo),
         locale       = COALESCE($3, locale),
         notif_hour   = COALESCE($4, notif_hour),
         notif_minute = COALESCE($5, notif_minute),
         fcm_token    = COALESCE($6, fcm_token)
       WHERE id = $1`, [userId, b.pseudo ?? null, b.locale ?? null, b.notifHour ?? null, b.notifMinute ?? null, b.fcmToken ?? null]);
        const user = await (0, auth_1.loadUser)(userId);
        return reply.send({ user: user ? (0, auth_2.publicUser)(user) : null });
    });
    // Personal museum: revealed artworks, unlocked per the collection rule.
    app.get('/collection', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const lang = req.query.lang ?? 'fr';
        const rows = await db_1.db.query(`SELECT id, title_fr, title_en, artist, year_, iso_week
       FROM artworks WHERE status = 'revealed' ORDER BY iso_year DESC, iso_week DESC`, []);
        const items = await Promise.all(rows.rows.map(async (r) => ({
            id: r.id,
            title: lang === 'en' ? r.title_en : r.title_fr,
            artist: r.artist,
            year: r.year_,
            week: r.iso_week,
            unlocked: await (0, scoring_1.isInCollection)(userId, r.id),
        })));
        return reply.send({ collection: items });
    });
    // RGPD — data export (JSON + photo URLs).
    app.get('/export', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const [user, photos, guesses, scores] = await Promise.all([
            db_1.db.query(`SELECT id, provider, email, pseudo, locale, created_at FROM app_users WHERE id=$1`, [userId]),
            db_1.db.query(`SELECT artwork_id, taken_on, day_, target_variant_key, delta_e, url FROM photos WHERE user_id=$1 AND deleted_at IS NULL`, [userId]),
            db_1.db.query(`SELECT artwork_id, title_guess, day_placed, correct FROM guesses WHERE user_id=$1`, [userId]),
            db_1.db.query(`SELECT instance_id, iso_year, iso_week, points FROM scores WHERE user_id=$1`, [userId]),
        ]);
        return reply
            .header('Content-Disposition', 'attachment; filename="memoire-de-lart-export.json"')
            .send({ user: user.rows[0], photos: photos.rows, guesses: guesses.rows, scores: scores.rows });
    });
    // RGPD — erasure: remove photos from storage, then cascade-delete the user
    // (contributions removed → affected cells revert to flat colour).
    app.delete('/', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        await storage_1.storage.deleteUserPhotos(userId);
        await db_1.db.query(`DELETE FROM app_users WHERE id = $1`, [userId]);
        return reply.code(204).send();
    });
}
//# sourceMappingURL=me.js.map