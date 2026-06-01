import type { FastifyInstance, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { db } from '../services/db';
import {
  assignTodayZone,
  buildZoneState,
  generateCode,
  randomPigment,
} from '../services/zones';

const joinSchema = z.object({
  code:       z.string().min(4).max(8).transform(s => s.toUpperCase()),
  pseudo:     z.string().max(32).optional(),
  fcmToken:   z.string().optional(),
});

const createSchema = z.object({
  pseudo:   z.string().max(32).optional(),
  fcmToken: z.string().optional(),
});

export async function instanceRoutes(app: FastifyInstance) {

  // POST /api/v1/instances  — create a new group for the current month
  app.post('/', async (req, reply) => {
    const body = createSchema.parse(req.body);

    const artwork = await currentMonthArtwork();
    if (!artwork) return reply.code(503).send({ error: 'Pas d\'œuvre publiée ce mois-ci.' });

    // Generate unique code (retry on collision)
    let code = '';
    for (let i = 0; i < 10; i++) {
      code = generateCode();
      const dup = await db.query('SELECT 1 FROM instances WHERE code = $1', [code]);
      if (dup.rows.length === 0) break;
    }

    const now = new Date();
    const inst = await db.query<{ id: string }>(
      `INSERT INTO instances (code, artwork_id, year_, month_)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [code, artwork.id, now.getFullYear(), now.getMonth() + 1],
    );
    const instanceId = inst.rows[0]!.id;

    const { player, token } = await createPlayer(instanceId, artwork.id, body.pseudo, body.fcmToken, app);

    return reply.code(201).send({
      token,
      instance: await instancePayload(instanceId, artwork.id, player.id),
    });
  });

  // POST /api/v1/instances/join  — join an existing group by code
  app.post('/join', async (req, reply) => {
    const body = joinSchema.parse(req.body);

    const inst = await db.query<{ id: string; artwork_id: string }>(
      `SELECT id, artwork_id FROM instances WHERE code = $1`,
      [body.code],
    );
    if (inst.rows.length === 0) return reply.code(404).send({ error: 'Instance introuvable.' });

    const { id: instanceId, artwork_id: artworkId } = inst.rows[0]!;
    const { player, token } = await createPlayer(instanceId, artworkId, body.pseudo, body.fcmToken, app);

    return reply.code(201).send({
      token,
      instance: await instancePayload(instanceId, artworkId, player.id),
    });
  });

  // GET /api/v1/instances/me  — current player's instance state (poll for updates)
  app.get('/me', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId, instanceId } = (req as FastifyRequest & { user: JwtPayload }).user;

    const inst = await db.query<{ artwork_id: string }>(
      `SELECT artwork_id FROM instances WHERE id = $1`,
      [instanceId],
    );
    if (inst.rows.length === 0) return reply.code(404).send({ error: 'Instance introuvable.' });

    return reply.send({ instance: await instancePayload(instanceId, inst.rows[0]!.artwork_id, playerId) });
  });

  // GET /api/v1/instances/:code/feed  — today's group contributions
  app.get('/:code/feed', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { code } = req.params as { code: string };

    const inst = await db.query<{ id: string; artwork_id: string }>(
      `SELECT id, artwork_id FROM instances WHERE code = $1`,
      [code],
    );
    if (inst.rows.length === 0) return reply.code(404).send({ error: 'Instance introuvable.' });

    const today = new Date().toISOString().slice(0, 10);
    const feed = await db.query(
      `SELECT
         p.id, p.pseudo, p.avatar_pigment,
         za.zone_id, z.pigment,
         za.submitted_at, za.photo_url
       FROM players p
       LEFT JOIN zone_assignments za ON za.player_id = p.id
         AND za.instance_id = $1 AND za.assigned_date = $2
       LEFT JOIN zones z ON z.id = za.zone_id AND z.artwork_id = $3
       WHERE p.instance_id = $1 AND p.deleted_at IS NULL
       ORDER BY p.created_at ASC`,
      [inst.rows[0]!.id, today, inst.rows[0]!.artwork_id],
    );

    return reply.send({ contributions: feed.rows });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

interface JwtPayload { playerId: string; instanceId: string }

async function currentMonthArtwork(): Promise<{ id: string } | null> {
  const now = new Date();
  const res = await db.query<{ id: string }>(
    `SELECT id FROM artworks
     WHERE published_at IS NOT NULL
       AND EXTRACT(YEAR  FROM published_at) = $1
       AND EXTRACT(MONTH FROM published_at) = $2
     ORDER BY published_at DESC LIMIT 1`,
    [now.getFullYear(), now.getMonth() + 1],
  );
  return res.rows[0] ?? null;
}

async function createPlayer(
  instanceId: string,
  artworkId:  string,
  pseudo?:    string,
  fcmToken?:  string,
  app?:       FastifyInstance,
): Promise<{ player: { id: string }; token: string }> {
  const avatarPigment = randomPigment();
  const res = await db.query<{ id: string }>(
    `INSERT INTO players (instance_id, pseudo, avatar_pigment, fcm_token)
     VALUES ($1, $2, $3, $4) RETURNING id`,
    [instanceId, pseudo ?? null, avatarPigment, fcmToken ?? null],
  );
  const player = res.rows[0]!;

  await assignTodayZone(instanceId, player.id, artworkId);

  const token = app!.jwt.sign({ playerId: player.id, instanceId });
  return { player, token };
}

async function instancePayload(instanceId: string, artworkId: string, playerId: string) {
  const now = new Date();
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();

  const [instRow, artworkRow, zonesState, players] = await Promise.all([
    db.query<{ code: string; year_: number; month_: number }>(
      `SELECT code, year_, month_ FROM instances WHERE id = $1`,
      [instanceId],
    ),
    db.query<{ id: string; cols: number; rows: number; cells: unknown }>(
      `SELECT id, cols, rows, cells FROM artworks WHERE id = $1`,
      [artworkId],
    ),
    buildZoneState(artworkId, instanceId, playerId),
    db.query(
      `SELECT
         p.id, p.pseudo, p.avatar_pigment,
         (p.id = $2) AS is_me,
         EXISTS (
           SELECT 1 FROM zone_assignments za
           WHERE za.player_id = p.id
             AND za.assigned_date = CURRENT_DATE
             AND za.submitted_at IS NOT NULL
         ) AS has_contributed_today,
         (
           SELECT za2.zone_id FROM zone_assignments za2
           WHERE za2.player_id = p.id AND za2.assigned_date = CURRENT_DATE
           LIMIT 1
         ) AS today_zone_id
       FROM players p
       WHERE p.instance_id = $1 AND p.deleted_at IS NULL
       ORDER BY p.created_at ASC`,
      [instanceId, playerId],
    ),
  ]);

  const inst    = instRow.rows[0]!;
  const artwork = artworkRow.rows[0]!;

  return {
    code:         inst.code,
    artworkId,
    year:         inst.year_,
    month:        inst.month_,
    dayNumber:    now.getDate(),
    daysInMonth,
    players: players.rows.map(p => ({
      id:                  p.id,
      pseudo:              p.pseudo ?? 'Anonyme',
      avatarPigment:       p.avatar_pigment,
      isMe:                p.is_me,
      hasContributedToday: p.has_contributed_today,
      todayZoneId:         p.today_zone_id ?? null,
    })),
    artwork: {
      id:    artwork.id,
      cols:  artwork.cols,
      rows:  artwork.rows,
      cells: artwork.cells,
      zones: zonesState,
    },
  };
}

