"use strict";
// claims.ts — POST /api/v1/claims : claim (or swap to) a variant for the day.
Object.defineProperty(exports, "__esModule", { value: true });
exports.claimRoutes = claimRoutes;
const zod_1 = require("zod");
const db_1 = require("../services/db");
const cycle_1 = require("../services/cycle");
const schema = zod_1.z.object({
    instanceId: zod_1.z.string().uuid(),
    variantKey: zod_1.z.string().min(1),
});
async function claimRoutes(app) {
    app.post('/', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const { instanceId, variantKey } = schema.parse(req.body);
        const a = await (0, cycle_1.currentArtwork)();
        if (!a)
            return reply.code(503).send({ error: 'Aucune œuvre active.' });
        const day = (0, cycle_1.weekDay)();
        // Variant must belong to the day's family.
        const fam = await db_1.db.query(`SELECT cv.family_key
       FROM color_variants cv
       JOIN color_families cf ON cf.artwork_id = cv.artwork_id AND cf.key = cv.family_key
       WHERE cv.artwork_id = $1 AND cv.key = $2 AND cf.day_ = $3`, [a.id, variantKey, day]);
        if (fam.rows.length === 0)
            return reply.code(400).send({ error: 'Variante hors de la famille du jour.' });
        const familyKey = fam.rows[0].family_key;
        // Swap: drop the user's previous claim within the same family (same instance).
        await db_1.db.query(`DELETE FROM claims
       WHERE instance_id = $1 AND artwork_id = $2 AND user_id = $3
         AND variant_key IN (SELECT key FROM color_variants WHERE artwork_id = $2 AND family_key = $4)`, [instanceId, a.id, userId, familyKey]);
        const ins = await db_1.db.query(`INSERT INTO claims (instance_id, artwork_id, user_id, variant_key, day_)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (instance_id, artwork_id, variant_key) DO NOTHING
       RETURNING id`, [instanceId, a.id, userId, variantKey, day]);
        if (ins.rows.length === 0) {
            const who = await db_1.db.query(`SELECT u.pseudo FROM claims c JOIN app_users u ON u.id = c.user_id
         WHERE c.instance_id = $1 AND c.artwork_id = $2 AND c.variant_key = $3`, [instanceId, a.id, variantKey]);
            return reply.code(409).send({ error: 'Variante déjà prise.', byPseudo: who.rows[0]?.pseudo ?? null });
        }
        return reply.code(201).send({ ok: true, variantKey });
    });
}
//# sourceMappingURL=claims.js.map