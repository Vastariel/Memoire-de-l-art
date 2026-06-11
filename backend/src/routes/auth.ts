// auth.ts — POST /api/v1/auth/:provider  (google | apple | dev)
// Verifies the client token, upserts the user, issues the app JWT.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { verifyProvider, upsertUser } from '../services/auth';
import type { AppUser, AuthProvider } from '../models/types';

const bodySchema = z.object({
  token: z.string().default(''),
  pseudo: z.string().max(32).optional(),
  locale: z.enum(['fr', 'en']).optional(),
  consent: z.boolean().optional(),
});

export function publicUser(u: AppUser) {
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

export async function authRoutes(app: FastifyInstance) {
  app.post('/:provider', async (req, reply) => {
    const provider = (req.params as { provider: string }).provider as AuthProvider;
    if (!['google', 'apple', 'dev'].includes(provider)) {
      return reply.code(400).send({ error: 'Fournisseur inconnu.' });
    }
    const body = bodySchema.parse(req.body ?? {});
    try {
      const identity = await verifyProvider(provider, body.token);
      const user = await upsertUser(provider, identity, {
        pseudo: body.pseudo,
        locale: body.locale,
        consent: body.consent,
      });
      const token = app.jwt.sign({ userId: user.id });
      return reply.code(200).send({ token, user: publicUser(user) });
    } catch (e) {
      return reply.code(401).send({ error: e instanceof Error ? e.message : 'Authentification échouée.' });
    }
  });
}
