import { Client as MinioClient } from 'minio';
import sharp from 'sharp';
import { env } from '../config/env';

const minio = new MinioClient({
  endPoint:  env.STORAGE_ENDPOINT,
  port:      env.STORAGE_PORT,
  useSSL:    env.STORAGE_USE_SSL,
  accessKey: env.STORAGE_ACCESS_KEY,
  secretKey: env.STORAGE_SECRET_KEY,
});

interface UploadOptions {
  instanceId: string;
  zoneId: string;
  mimeType: string;
  blendMode: 'replace' | 'blend';
  targetHex: string;
}

export const storage = {
  async uploadPhoto(rawBuffer: Buffer, opts: UploadOptions): Promise<string> {
    // Crop to square + resize to 512px
    let processed = await sharp(rawBuffer)
      .resize(512, 512, { fit: 'cover', position: 'center' })
      .jpeg({ quality: 85, progressive: true })
      .toBuffer();

    // If blending: desaturate toward target colour
    if (opts.blendMode === 'blend') {
      processed = await _blendTowardTarget(processed, opts.targetHex);
    }

    const key = `photos/${opts.instanceId}/${opts.zoneId}/${Date.now()}.jpg`;

    await minio.putObject(env.STORAGE_BUCKET, key, processed, processed.length, {
      'Content-Type': 'image/jpeg',
      'Cache-Control': 'public, max-age=31536000, immutable',
    });

    // Return public URL
    return `https://${env.STORAGE_ENDPOINT}/${env.STORAGE_BUCKET}/${key}`;
  },

  async deletePhoto(key: string): Promise<void> {
    await minio.removeObject(env.STORAGE_BUCKET, key);
  },
};

async function _blendTowardTarget(buffer: Buffer, hex: string): Promise<Buffer> {
  // Slightly tint the image toward the target colour (20% opacity overlay)
  const n = parseInt(hex.replace('#', ''), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;

  const overlay = Buffer.alloc(512 * 512 * 4);
  for (let i = 0; i < overlay.length; i += 4) {
    overlay[i]     = r;
    overlay[i + 1] = g;
    overlay[i + 2] = b;
    overlay[i + 3] = 51; // ~20% alpha
  }

  return sharp(buffer)
    .composite([{ input: overlay, raw: { width: 512, height: 512, channels: 4 }, blend: 'over' }])
    .jpeg({ quality: 85 })
    .toBuffer();
}
