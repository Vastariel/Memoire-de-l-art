"use strict";
// days.ts — GET /api/v1/days/today : family of the day + variants + claims.
Object.defineProperty(exports, "__esModule", { value: true });
exports.dayRoutes = dayRoutes;
const db_1 = require("../services/db");
const cycle_1 = require("../services/cycle");
async function dayRoutes(app) {
    app.get('/today', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const a = await (0, cycle_1.currentArtwork)();
        if (!a)
            return reply.code(503).send({ error: 'Aucune œuvre active cette semaine.' });
        const day = (0, cycle_1.weekDay)();
        const fam = await db_1.db.query(`SELECT key, name_fr, name_en FROM color_families WHERE artwork_id = $1 AND day_ = $2`, [a.id, day]);
        if (fam.rows.length === 0)
            return reply.send({ weekDay: day, family: null, variants: [] });
        const family = fam.rows[0];
        const cells = a.cells ?? [];
        const variants = await db_1.db.query(`SELECT key, name_fr, name_en, hex FROM color_variants WHERE artwork_id = $1 AND family_key = $2`, [a.id, family.key]);
        // The user's instances and which variants are already claimed there.
        const claims = await db_1.db.query(`SELECT c.instance_id, c.variant_key, u.pseudo
       FROM claims c
       JOIN instance_members m ON m.instance_id = c.instance_id AND m.user_id = $1
       JOIN app_users u ON u.id = c.user_id
       WHERE c.artwork_id = $2 AND c.day_ = $3`, [userId, a.id, day]);
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
//# sourceMappingURL=days.js.map