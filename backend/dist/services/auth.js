"use strict";
// auth.ts — verify a provider token (Firebase-issued for Google/Apple), upsert
// the cross-instance user. The backend keeps its own JWT (issued in the route).
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyProvider = verifyProvider;
exports.upsertUser = upsertUser;
exports.loadUser = loadUser;
const firebase_admin_1 = __importDefault(require("firebase-admin"));
const env_1 = require("../config/env");
const db_1 = require("./db");
let _app;
function firebase() {
    if (_app !== undefined)
        return _app;
    if (env_1.env.FIREBASE_PROJECT_ID && env_1.env.FIREBASE_CLIENT_EMAIL && env_1.env.FIREBASE_PRIVATE_KEY) {
        _app = firebase_admin_1.default.initializeApp({
            credential: firebase_admin_1.default.credential.cert({
                projectId: env_1.env.FIREBASE_PROJECT_ID,
                clientEmail: env_1.env.FIREBASE_CLIENT_EMAIL,
                privateKey: env_1.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            }),
        });
    }
    else {
        _app = null;
    }
    return _app;
}
/** Verify the client-supplied token and return a stable subject id. */
async function verifyProvider(provider, token) {
    if (provider === 'dev') {
        if (env_1.env.NODE_ENV === 'production' && !env_1.env.ALLOW_DEV_LOGIN) {
            throw new Error('Connexion dev désactivée (mettre ALLOW_DEV_LOGIN=true pour tester).');
        }
        const sub = token && token.length > 0 ? token : `${Date.now()}`;
        return { sub: `dev:${sub}`, email: null };
    }
    const fb = firebase();
    if (!fb)
        throw new Error('OAuth non configurée (renseigner FIREBASE_*).');
    const decoded = await fb.auth().verifyIdToken(token);
    return { sub: `${provider}:${decoded.uid}`, email: decoded.email ?? null };
}
function mapUser(r) {
    return {
        id: r.id,
        provider: r.provider,
        providerSub: r.provider_sub,
        email: r.email,
        pseudo: r.pseudo,
        avatarPigment: r.avatar_pigment,
        locale: r.locale,
        notifHour: r.notif_hour,
        notifMinute: r.notif_minute,
        consentRgpd: r.consent_rgpd,
    };
}
async function upsertUser(provider, identity, opts = {}) {
    const res = await db_1.db.query(`INSERT INTO app_users (provider, provider_sub, email, pseudo, locale, consent_rgpd, consent_at)
     VALUES ($1, $2, $3, $4, COALESCE($5,'fr'), $6, CASE WHEN $6 THEN NOW() ELSE NULL END)
     ON CONFLICT (provider, provider_sub) DO UPDATE SET
       email      = COALESCE(EXCLUDED.email, app_users.email),
       pseudo     = COALESCE(app_users.pseudo, EXCLUDED.pseudo),
       locale     = COALESCE(EXCLUDED.locale, app_users.locale),
       consent_rgpd = app_users.consent_rgpd OR EXCLUDED.consent_rgpd,
       deleted_at = NULL
     RETURNING *`, [provider, identity.sub, identity.email, opts.pseudo ?? null, opts.locale ?? null, opts.consent ?? false]);
    return mapUser(res.rows[0]);
}
async function loadUser(id) {
    const res = await db_1.db.query(`SELECT * FROM app_users WHERE id = $1 AND deleted_at IS NULL`, [id]);
    return res.rows[0] ? mapUser(res.rows[0]) : null;
}
//# sourceMappingURL=auth.js.map