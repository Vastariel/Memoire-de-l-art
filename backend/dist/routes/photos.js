"use strict";
// photos.ts — POST /api/v1/photos (+ /catchup) : submit one photo/day.
// Analyses ΔE + variance, stores (EXIF stripped), fans contributions out to the
// user's shared instances (or a single separate instance), scores + streak.
Object.defineProperty(exports, "__esModule", { value: true });
exports.photoRoutes = photoRoutes;
const node_crypto_1 = require("node:crypto");
const db_1 = require("../services/db");
const color_match_1 = require("../services/color-match");
const storage_1 = require("../services/storage");
const cycle_1 = require("../services/cycle");
const scoring_1 = require("../services/scoring");
function readFields(fields) {
    const val = (k) => fields[k]?.value;
    const sep = val('separateInstanceId') || null;
    return {
        day: parseInt(val('day') ?? '0', 10),
        variantKey: val('variantKey') ?? '',
        shared: sep ? false : (val('shared') ?? 'true') !== 'false',
        separateInstanceId: sep,
    };
}
async function photoRoutes(app) {
    app.post('/', { onRequest: [app.authenticate] }, submit);
    // Catch-up uses the same handler with a past `day` field.
    app.post('/catchup', { onRequest: [app.authenticate] }, submit);
}
async function submit(req, reply) {
    const { userId } = req.user;
    const data = await req.file();
    if (!data)
        return reply.code(400).send({ error: 'Photo manquante.' });
    const buffer = await data.toBuffer();
    const f = readFields(data.fields ?? {});
    if (!f.variantKey)
        return reply.code(400).send({ error: 'variantKey requis.' });
    const a = await (0, cycle_1.currentArtwork)();
    if (!a)
        return reply.code(503).send({ error: 'Aucune œuvre active.' });
    const day = f.day >= 1 && f.day <= 7 ? f.day : (0, cycle_1.weekDay)();
    const variant = await db_1.db.query(`SELECT hex FROM color_variants WHERE artwork_id = $1 AND key = $2`, [a.id, f.variantKey]);
    if (variant.rows.length === 0)
        return reply.code(400).send({ error: 'Variante inconnue.' });
    const targetHex = variant.rows[0].hex;
    const match = await (0, color_match_1.analyzePhoto)(buffer, targetHex);
    const photoId = (0, node_crypto_1.randomUUID)();
    const stored = await storage_1.storage.uploadPhoto(buffer, userId, photoId);
    const takenOn = new Date().toISOString().slice(0, 10);
    await db_1.db.query(`INSERT INTO photos (id, user_id, artwork_id, taken_on, day_, target_variant_key,
                         dominant_hex, delta_e, variance, shared, separate_instance_id, storage_key, url)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`, [photoId, userId, a.id, takenOn, day, f.variantKey, match.dominantHex, match.deltaE, match.variance,
        f.shared, f.separateInstanceId, stored.key, stored.url]);
    // Target instances: all the user's shared instances, or the one separate instance.
    let targets;
    if (f.separateInstanceId) {
        targets = [f.separateInstanceId];
    }
    else {
        const rows = await db_1.db.query(`SELECT i.id FROM instances i
       JOIN instance_members m ON m.instance_id = i.id AND m.user_id = $1
       WHERE i.mode = 'shared'`, [userId]);
        targets = rows.rows.map(r => r.id);
    }
    for (const instanceId of targets) {
        await db_1.db.query(`INSERT INTO contributions (photo_id, instance_id, artwork_id, user_id, variant_key, crops)
       VALUES ($1, $2, $3, $4, $5, '[]'::jsonb)
       ON CONFLICT (instance_id, artwork_id, variant_key) DO NOTHING`, [photoId, instanceId, a.id, userId, f.variantKey]);
    }
    // Scoring: streak then per-instance points (base + match bonus × multiplier).
    const streak = await (0, scoring_1.bumpStreak)(db_1.db, userId, takenOn);
    const pts = (0, scoring_1.photoPoints)(match.matchBonus, streak);
    const { year, week } = (0, cycle_1.isoWeek)();
    for (const instanceId of targets) {
        await (0, scoring_1.addPoints)(db_1.db, userId, instanceId, year, week, pts);
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
//# sourceMappingURL=photos.js.map