import { db }             from './db';
import { evocativeName }  from './segmentation';

export function randomPigment(): string {
  const keys = ['vermillion','sienna','ochre','saffron','olive','viridian',
                 'teal','cobalt','ultramarine','aubergine','rose','slate'];
  return keys[Math.floor(Math.random() * keys.length)]!;
}

export function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function labelFromHex(hex: string): string {
  const n = parseInt(hex.replace('#', ''), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  return evocativeName(r, g, b);
}

export interface TodayZone {
  zoneId:    string;
  pigment:   string;
  label:     string;
  targetHex: string;
}

// Assign today's zone to a player who doesn't have one yet.
// Returns the zone or null if all zones are complete.
export async function assignTodayZone(
  instanceId: string,
  playerId:   string,
  artworkId:  string,
): Promise<TodayZone | null> {
  const today = todayDate();

  // Already assigned today?
  const existing = await db.query<{ zone_id: string; pigment: string; target_hex: string }>(
    `SELECT za.zone_id, z.pigment, z.target_hex
     FROM zone_assignments za
     JOIN zones z ON z.id = za.zone_id AND z.artwork_id = za.artwork_id
     WHERE za.player_id = $1 AND za.assigned_date = $2`,
    [playerId, today],
  );
  if (existing.rows.length > 0) {
    const r = existing.rows[0]!;
    return { zoneId: r.zone_id, pigment: r.pigment, label: labelFromHex(r.target_hex), targetHex: r.target_hex };
  }

  // Pick the next unfilled zone, ordered by cell_count ASC (details → backgrounds)
  // Unfilled = no submitted assignment in this instance
  const candidate = await db.query<{ id: string; pigment: string; target_hex: string }>(
    `SELECT z.id, z.pigment, z.target_hex
     FROM zones z
     WHERE z.artwork_id = $1
       -- Not yet filled (no submitted contribution in this instance)
       AND NOT EXISTS (
         SELECT 1 FROM zone_assignments za
         WHERE za.zone_id = z.id AND za.artwork_id = z.artwork_id
           AND za.instance_id = $2 AND za.submitted_at IS NOT NULL
       )
       -- Not already assigned to someone else today
       AND NOT EXISTS (
         SELECT 1 FROM zone_assignments za
         WHERE za.zone_id = z.id AND za.artwork_id = z.artwork_id
           AND za.instance_id = $2 AND za.assigned_date = $3
       )
     ORDER BY z.cell_count ASC
     LIMIT 1`,
    [artworkId, instanceId, today],
  );

  if (candidate.rows.length === 0) return null;

  const z = candidate.rows[0]!;
  await db.query(
    `INSERT INTO zone_assignments
       (zone_id, artwork_id, instance_id, player_id, assigned_date)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT DO NOTHING`,
    [z.id, artworkId, instanceId, playerId, today],
  );

  return { zoneId: z.id, pigment: z.pigment, label: labelFromHex(z.target_hex), targetHex: z.target_hex };
}

// Build full zone state for an artwork in an instance:
// returns each zone with its contribution (if submitted) and isToday flag.
export async function buildZoneState(
  artworkId:  string,
  instanceId: string,
  playerId:   string,
): Promise<Record<string, ZoneState>> {
  const today = todayDate();

  const rows = await db.query<{
    zone_id:       string;
    pigment:       string;
    cell_count:    number;
    target_hex:    string;
    player_id:     string | null;
    pseudo:        string | null;
    avatar_pigment: string | null;
    submitted_at:  string | null;
    photo_url:     string | null;
    is_today:      boolean;
  }>(
    `SELECT
       z.id                        AS zone_id,
       z.pigment,
       z.cell_count,
       z.target_hex,
       za.player_id::text,
       p.pseudo,
       p.avatar_pigment,
       za.submitted_at::text,
       za.photo_url,
       (za.player_id = $3::uuid AND za.assigned_date = $4) AS is_today
     FROM zones z
     LEFT JOIN zone_assignments za
       ON za.zone_id = z.id AND za.artwork_id = z.artwork_id
       AND za.instance_id = $2 AND za.submitted_at IS NOT NULL
     LEFT JOIN players p ON p.id = za.player_id
     WHERE z.artwork_id = $1`,
    [artworkId, instanceId, playerId, today],
  );

  const result: Record<string, ZoneState> = {};
  for (const r of rows.rows) {
    result[r.zone_id] = {
      id:        r.zone_id,
      pigment:   r.pigment,
      label:     labelFromHex(r.target_hex),
      cellCount: r.cell_count,
      targetHex: r.target_hex,
      isToday:   r.is_today ?? false,
      contribution: r.submitted_at ? {
        playerPseudo:   r.pseudo ?? 'Anonyme',
        playerAvatar:   r.avatar_pigment ?? 'slate',
        contributedAt:  r.submitted_at,
        photoUrl:        r.photo_url ?? undefined,
      } : undefined,
    };
  }
  return result;
}

export interface ZoneState {
  id:        string;
  pigment:   string;
  label:     string;
  cellCount: number;
  targetHex: string;
  isToday:   boolean;
  contribution?: {
    playerPseudo:  string;
    playerAvatar:  string;
    contributedAt: string;
    photoUrl?:     string;
  };
}

// Run each midnight: assign zones to all active players who don't have one yet.
export async function runDailyAssignments(): Promise<void> {
  const now = new Date();
  const instances = await db.query<{ id: string; artwork_id: string }>(
    `SELECT id, artwork_id FROM instances WHERE year_ = $1 AND month_ = $2`,
    [now.getFullYear(), now.getMonth() + 1],
  );
  for (const inst of instances.rows) {
    const players = await db.query<{ id: string }>(
      `SELECT id FROM players WHERE instance_id = $1 AND deleted_at IS NULL`,
      [inst.id],
    );
    for (const player of players.rows) {
      await assignTodayZone(inst.id, player.id, inst.artwork_id);
    }
  }
}

function todayDate(): string {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}
