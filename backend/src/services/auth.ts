// auth.ts — verify a provider token (Firebase-issued for Google/Apple), upsert
// the cross-instance user. The backend keeps its own JWT (issued in the route).

import admin from 'firebase-admin';
import { env } from '../config/env';
import { db } from './db';
import type { AppUser, AuthProvider } from '../models/types';

let _app: admin.app.App | null | undefined;
function firebase(): admin.app.App | null {
  if (_app !== undefined) return _app;
  if (env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY) {
    _app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: env.FIREBASE_PROJECT_ID,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
        privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
  } else {
    _app = null;
  }
  return _app;
}

export interface VerifiedIdentity { sub: string; email: string | null; }

/** Verify the client-supplied token and return a stable subject id. */
export async function verifyProvider(provider: AuthProvider, token: string): Promise<VerifiedIdentity> {
  if (provider === 'dev') {
    if (env.NODE_ENV === 'production' && !env.ALLOW_DEV_LOGIN) {
      throw new Error('Connexion dev désactivée (mettre ALLOW_DEV_LOGIN=true pour tester).');
    }
    const sub = token && token.length > 0 ? token : `${Date.now()}`;
    return { sub: `dev:${sub}`, email: null };
  }
  const fb = firebase();
  if (!fb) throw new Error('OAuth non configurée (renseigner FIREBASE_*).');
  const decoded = await fb.auth().verifyIdToken(token);
  return { sub: `${provider}:${decoded.uid}`, email: decoded.email ?? null };
}

function mapUser(r: any): AppUser {
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

export async function upsertUser(
  provider: AuthProvider,
  identity: VerifiedIdentity,
  opts: { pseudo?: string; locale?: string; consent?: boolean } = {},
): Promise<AppUser> {
  const res = await db.query(
    `INSERT INTO app_users (provider, provider_sub, email, pseudo, locale, consent_rgpd, consent_at)
     VALUES ($1, $2, $3, $4, COALESCE($5,'fr'), $6, CASE WHEN $6 THEN NOW() ELSE NULL END)
     ON CONFLICT (provider, provider_sub) DO UPDATE SET
       email      = COALESCE(EXCLUDED.email, app_users.email),
       pseudo     = COALESCE(app_users.pseudo, EXCLUDED.pseudo),
       locale     = COALESCE(EXCLUDED.locale, app_users.locale),
       consent_rgpd = app_users.consent_rgpd OR EXCLUDED.consent_rgpd,
       deleted_at = NULL
     RETURNING *`,
    [provider, identity.sub, identity.email, opts.pseudo ?? null, opts.locale ?? null, opts.consent ?? false],
  );
  return mapUser(res.rows[0]);
}

export async function loadUser(id: string): Promise<AppUser | null> {
  const res = await db.query(`SELECT * FROM app_users WHERE id = $1 AND deleted_at IS NULL`, [id]);
  return res.rows[0] ? mapUser(res.rows[0]) : null;
}
