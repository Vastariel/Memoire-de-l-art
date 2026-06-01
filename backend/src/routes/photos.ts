import type { FastifyInstance } from 'fastify';
import { db }          from '../services/db';
import { colorMatch }  from '../services/color-match';
import { storage }     from '../services/storage';

export async function photoRoutes(app: FastifyInstance) {

  // POST /api/v1/photos/submit
  // Multipart: file (JPEG) + zoneId (text field)
  app.post('/submit', { onRequest: [app.authenticate] }, async (req, reply) => {
    const { playerId, instanceId } = req.user;
    const today = new Date().toISOString().slice(0, 10);

    let zoneId     = '';
    let fileBuffer: Buffer | null = null;
    let mimeType   = 'image/jpeg';

    const parts = req.parts();
    for await (const part of parts) {
      if (part.type === 'field' && part.fieldname === 'zoneId') {
        zoneId = part.value as string;
      } else if (part.type === 'file') {
        const chunks: Buffer[] = [];
        for await (const chunk of part.file) chunks.push(chunk);
        fileBuffer = Buffer.concat(chunks);
        mimeType   = part.mimetype;
      }
    }

    if (!fileBuffer || !zoneId) {
      return reply.code(400).send({ error: 'Fichier ou zoneId manquant.' });
    }

    // Verify this assignment belongs to the player today
    const assignment = await db.query<{ zone_id: string; artwork_id: string }>(
      `SELECT zone_id, artwork_id FROM zone_assignments
       WHERE player_id = $1 AND zone_id = $2 AND assigned_date = $3
         AND instance_id = $4 AND submitted_at IS NULL`,
      [playerId, zoneId, today, instanceId],
    );
    if (assignment.rows.length === 0) {
      return reply.code(403).send({ error: 'Aucune assignation valide pour aujourd\'hui.' });
    }
    const { artwork_id: artworkId } = assignment.rows[0]!;

    // Fetch target hex for this zone
    const zoneRow = await db.query<{ target_hex: string }>(
      `SELECT target_hex FROM zones WHERE id = $1 AND artwork_id = $2`,
      [zoneId, artworkId],
    );
    if (zoneRow.rows.length === 0) return reply.code(404).send({ error: 'Zone introuvable.' });
    const targetHex = zoneRow.rows[0]!.target_hex;

    // Count active players in this instance for adaptive tolerance
    const playerRow = await db.query<{ count: string }>(
      `SELECT COUNT(*) FROM players WHERE instance_id = $1 AND deleted_at IS NULL`,
      [instanceId],
    );
    const playerCount = parseInt(playerRow.rows[0]?.count ?? '1', 10);

    // Colour analysis
    const match = await colorMatch(fileBuffer, targetHex, playerCount);

    // Reject if colour is too far from target
    if (match.verdict === 'rejeté') {
      return reply.code(422).send({
        error: 'Couleur trop éloignée de la cible.',
        match,
      });
    }

    // Store photo
    const photoUrl = await storage.uploadPhoto(fileBuffer, {
      instanceId,
      zoneId,
      mimeType,
      blendMode: 'replace',
      targetHex,
    });

    // Mark assignment as submitted
    await db.query(
      `UPDATE zone_assignments
       SET submitted_at = NOW(), photo_url = $1, color_delta = $2, blend_mode = $3
       WHERE player_id = $4 AND zone_id = $5 AND assigned_date = $6`,
      [photoUrl, match.delta, match.mode, playerId, zoneId, today],
    );

    return reply.code(201).send({ photoUrl, match });
  });
}
