"use strict";
// contributions.ts — POST /api/v1/contributions/:id/reactions : toggle a stamp.
Object.defineProperty(exports, "__esModule", { value: true });
exports.contributionRoutes = contributionRoutes;
const zod_1 = require("zod");
const db_1 = require("../services/db");
const STAMPS = ['bravo', 'audacieux', 'trouvaille', 'pile', 'lumiere'];
const schema = zod_1.z.object({ stamp: zod_1.z.enum(['bravo', 'audacieux', 'trouvaille', 'pile', 'lumiere']) });
async function contributionRoutes(app) {
    app.post('/:id/reactions', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const contributionId = req.params.id;
        const { stamp } = schema.parse(req.body);
        const existing = await db_1.db.query(`SELECT id FROM reactions WHERE contribution_id = $1 AND user_id = $2 AND stamp = $3`, [contributionId, userId, stamp]);
        let active;
        if (existing.rows.length > 0) {
            await db_1.db.query(`DELETE FROM reactions WHERE id = $1`, [existing.rows[0].id]);
            active = false;
        }
        else {
            await db_1.db.query(`INSERT INTO reactions (contribution_id, user_id, stamp) VALUES ($1, $2, $3)
         ON CONFLICT (contribution_id, user_id, stamp) DO NOTHING`, [contributionId, userId, stamp]);
            active = true;
        }
        const counts = await db_1.db.query(`SELECT stamp, COUNT(*) AS n FROM reactions WHERE contribution_id = $1 GROUP BY stamp`, [contributionId]);
        const byStamp = {};
        for (const s of STAMPS)
            byStamp[s] = 0;
        for (const r of counts.rows)
            byStamp[r.stamp] = parseInt(r.n);
        return reply.send({ active, stamp, counts: byStamp });
    });
}
//# sourceMappingURL=contributions.js.map