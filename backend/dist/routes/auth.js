"use strict";
// auth.ts — POST /api/v1/auth/:provider  (google | apple | dev)
// Verifies the client token, upserts the user, issues the app JWT.
Object.defineProperty(exports, "__esModule", { value: true });
exports.publicUser = publicUser;
exports.authRoutes = authRoutes;
const zod_1 = require("zod");
const auth_1 = require("../services/auth");
const bodySchema = zod_1.z.object({
    token: zod_1.z.string().default(''),
    pseudo: zod_1.z.string().max(32).optional(),
    locale: zod_1.z.enum(['fr', 'en']).optional(),
    consent: zod_1.z.boolean().optional(),
});
function publicUser(u) {
    return {
        id: u.id,
        pseudo: u.pseudo,
        avatarPigment: u.avatarPigment,
        locale: u.locale,
        notifHour: u.notifHour,
        notifMinute: u.notifMinute,
        consentRgpd: u.consentRgpd,
    };
}
async function authRoutes(app) {
    app.post('/:provider', async (req, reply) => {
        const provider = req.params.provider;
        if (!['google', 'apple', 'dev'].includes(provider)) {
            return reply.code(400).send({ error: 'Fournisseur inconnu.' });
        }
        const body = bodySchema.parse(req.body ?? {});
        try {
            const identity = await (0, auth_1.verifyProvider)(provider, body.token);
            const user = await (0, auth_1.upsertUser)(provider, identity, {
                pseudo: body.pseudo,
                locale: body.locale,
                consent: body.consent,
            });
            const token = app.jwt.sign({ userId: user.id });
            return reply.code(200).send({ token, user: publicUser(user) });
        }
        catch (e) {
            return reply.code(401).send({ error: e instanceof Error ? e.message : 'Authentification échouée.' });
        }
    });
}
//# sourceMappingURL=auth.js.map