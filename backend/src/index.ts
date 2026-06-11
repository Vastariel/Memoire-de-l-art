import Fastify, { type FastifyRequest, type FastifyReply } from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import cron from 'node-cron';

import { authRoutes } from './routes/auth';
import { weekRoutes } from './routes/weeks';
import { dayRoutes } from './routes/days';
import { instanceRoutes } from './routes/instances';
import { claimRoutes } from './routes/claims';
import { photoRoutes } from './routes/photos';
import { contributionRoutes } from './routes/contributions';
import { guessRoutes } from './routes/guesses';
import { meRoutes } from './routes/me';
import { adminRoutes } from './routes/admin';
import { env } from './config/env';
import { db } from './services/db';
import { activateCurrentWeek, revealCurrentWeek } from './services/cycle';
import type { JwtPayload } from './models/types';

async function start() {
  const app = Fastify({ logger: { level: env.LOG_LEVEL }, trustProxy: true });

  await app.register(helmet, { contentSecurityPolicy: false });
  await app.register(cors, { origin: env.CORS_ORIGINS.split(','), credentials: true });
  await app.register(rateLimit, { max: 120, timeWindow: '1 minute' });
  await app.register(jwt, { secret: env.JWT_SECRET });
  await app.register(multipart, { limits: { fileSize: 12 * 1024 * 1024 } });

  app.decorate('authenticate', async (req: FastifyRequest, reply: FastifyReply) => {
    try {
      await req.jwtVerify();
    } catch {
      return reply.code(401).send({ error: 'Non autorisé.' });
    }
  });

  // ── Routes (v2) ──────────────────────────────────────────────
  await app.register(authRoutes, { prefix: '/api/v1/auth' });
  await app.register(weekRoutes, { prefix: '/api/v1/weeks' });
  await app.register(dayRoutes, { prefix: '/api/v1/days' });
  await app.register(instanceRoutes, { prefix: '/api/v1/instances' });
  await app.register(claimRoutes, { prefix: '/api/v1/claims' });
  await app.register(photoRoutes, { prefix: '/api/v1/photos' });
  await app.register(contributionRoutes, { prefix: '/api/v1/contributions' });
  await app.register(guessRoutes, { prefix: '/api/v1/guesses' });
  await app.register(meRoutes, { prefix: '/api/v1/me' });
  await app.register(adminRoutes, { prefix: '/api/admin' });

  app.get('/health', async () => ({ status: 'ok', ts: new Date().toISOString() }));

  // ── Weekly UTC cycle ─────────────────────────────────────────
  // New artwork goes live Monday 00:00 UTC; reveal forced Sunday 23:59 UTC.
  cron.schedule('0 0 * * 1', async () => {
    try { await activateCurrentWeek(); } catch (err) { app.log.error({ err }, 'activateCurrentWeek failed'); }
  }, { timezone: 'UTC' });

  cron.schedule('59 23 * * 0', async () => {
    try { await revealCurrentWeek(); } catch (err) { app.log.error({ err }, 'revealCurrentWeek failed'); }
  }, { timezone: 'UTC' });

  await db.query('SELECT 1');
  await app.listen({ port: env.PORT, host: '0.0.0.0' });
  app.log.info(`Server running on port ${env.PORT}`);
}

start().catch(err => {
  console.error(err);
  process.exit(1);
});

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}
declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: JwtPayload;
    user: JwtPayload;
  }
}
