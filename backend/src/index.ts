import Fastify, { type FastifyRequest, type FastifyReply } from 'fastify';
import cors      from '@fastify/cors';
import helmet    from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import jwt       from '@fastify/jwt';
import multipart from '@fastify/multipart';
import cron      from 'node-cron';

import { instanceRoutes }      from './routes/instances';
import { artworkRoutes }       from './routes/artworks';
import { photoRoutes }         from './routes/photos';
import { playerRoutes }        from './routes/players';
import { adminRoutes }         from './routes/admin';
import { env }                 from './config/env';
import { runDailyAssignments } from './services/zones';
import { db }                  from './services/db';

async function start() {
  const app = Fastify({
    logger: { level: env.LOG_LEVEL },
    trustProxy: true,
  });

  // ── Security ────────────────────────────────────────────────
  await app.register(helmet, { contentSecurityPolicy: false });
  await app.register(cors, {
    origin: env.CORS_ORIGINS.split(','),
    credentials: true,
  });
  await app.register(rateLimit, { max: 60, timeWindow: '1 minute' });

  // ── Auth ─────────────────────────────────────────────────────
  await app.register(jwt, { secret: env.JWT_SECRET });

  app.decorate('authenticate', async (req: FastifyRequest, reply: FastifyReply) => {
    try {
      await req.jwtVerify();
    } catch {
      return reply.code(401).send({ error: 'Non autorisé.' });
    }
  });

  // ── File upload ──────────────────────────────────────────────
  await app.register(multipart, {
    limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  });

  // ── Routes ───────────────────────────────────────────────────
  await app.register(instanceRoutes, { prefix: '/api/v1/instances' });
  await app.register(artworkRoutes,  { prefix: '/api/v1/artworks' });
  await app.register(photoRoutes,    { prefix: '/api/v1/photos' });
  await app.register(playerRoutes,   { prefix: '/api/v1/players' });
  await app.register(adminRoutes,    { prefix: '/api/admin' });

  // ── Health ───────────────────────────────────────────────────
  app.get('/health', async () => ({ status: 'ok', ts: new Date().toISOString() }));

  // ── Daily zone assignment cron ───────────────────────────────
  // 00:01 every night — assign zones to all active players
  cron.schedule('1 0 * * *', async () => {
    app.log.info('Running daily zone assignments…');
    try {
      await runDailyAssignments();
    } catch (err) {
      app.log.error({ err }, 'Daily zone assignment failed');
    }
  });

  // ── Start ────────────────────────────────────────────────────
  await db.query('SELECT 1'); // verify DB on startup
  await app.listen({ port: env.PORT, host: '0.0.0.0' });
  app.log.info(`Server running on port ${env.PORT}`);
}

start().catch(err => {
  console.error(err);
  process.exit(1);
});

// Type extensions
declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}
declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: { playerId: string; instanceId: string };
  }
}
