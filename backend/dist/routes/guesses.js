"use strict";
// guesses.ts — POST /api/v1/guesses : place/update the weekly mystery bet.
Object.defineProperty(exports, "__esModule", { value: true });
exports.guessRoutes = guessRoutes;
const zod_1 = require("zod");
const db_1 = require("../services/db");
const cycle_1 = require("../services/cycle");
const scoring_1 = require("../services/scoring");
const schema = zod_1.z.object({ titleGuess: zod_1.z.string().min(1).max(120) });
async function guessRoutes(app) {
    app.post('/', { onRequest: [app.authenticate] }, async (req, reply) => {
        const { userId } = req.user;
        const { titleGuess } = schema.parse(req.body);
        const a = await (0, cycle_1.currentArtwork)();
        if (!a)
            return reply.code(503).send({ error: 'Aucune œuvre active.' });
        if (a.status === 'revealed')
            return reply.code(409).send({ error: 'Œuvre déjà révélée.' });
        // One bet per artwork, editable. day_placed keeps the first placement
        // (early commitment is rewarded by the barème).
        const res = await db_1.db.query(`INSERT INTO guesses (user_id, artwork_id, title_guess, day_placed)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, artwork_id) DO UPDATE
         SET title_guess = EXCLUDED.title_guess, updated_at = NOW()
       RETURNING day_placed`, [userId, a.id, titleGuess, (0, cycle_1.weekDay)()]);
        const dayPlaced = res.rows[0].day_placed;
        return reply.send({ ok: true, dayPlaced, potentialPoints: (0, scoring_1.betPoints)(dayPlaced) });
    });
}
//# sourceMappingURL=guesses.js.map