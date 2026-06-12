import { Client as MinioClient } from 'minio';
import sharp from 'sharp';
import type { Readable } from 'node:stream';
import { env } from '../config/env';

const minio = new MinioClient({
  endPoint: env.STORAGE_ENDPOINT,
  port: env.STORAGE_PORT,
  useSSL: env.STORAGE_USE_SSL,
  accessKey: env.STORAGE_ACCESS_KEY,
  secretKey: env.STORAGE_SECRET_KEY,
});

export interface StoredPhoto { key: string; url: string; }

// Public-facing URL: proxied through the API so the browser/mobile never need
// direct access to MinIO. The /api/v1/photos/file/:id route streams the object.
function publicUrl(photoId: string): string {
  return `/api/v1/photos/file/${photoId}`;
}

export const storage = {
  /**
   * Process & store a submitted photo. The raw photo is what the vitrail shows,
   * so it is NOT tinted. EXIF (incl. GPS) is stripped: sharp drops metadata by
   * default; .rotate() bakes orientation first so we can discard the tag.
   */
  async uploadPhoto(rawBuffer: Buffer, userId: string, photoId: string): Promise<StoredPhoto> {
    const processed = await sharp(rawBuffer)
      .rotate()                                  // apply EXIF orientation, then drop metadata
      .resize(1024, 1024, { fit: 'cover', position: 'center' })
      .jpeg({ quality: 86, progressive: true })
      .toBuffer();

    const key = `photos/${userId}/${photoId}.jpg`;
    await minio.putObject(env.STORAGE_BUCKET, key, processed, processed.length, {
      'Content-Type': 'image/jpeg',
      'Cache-Control': 'public, max-age=31536000, immutable',
    });

    return { key, url: publicUrl(photoId) };
  },

  /** Stream an object back from MinIO so the API can proxy it. */
  async getObjectStream(key: string): Promise<Readable> {
    return minio.getObject(env.STORAGE_BUCKET, key);
  },

  async deletePhoto(key: string): Promise<void> {
    try {
      await minio.removeObject(env.STORAGE_BUCKET, key);
    } catch {/* already gone */}
  },

  /** Remove every object under a user's prefix (RGPD erasure). */
  async deleteUserPhotos(userId: string): Promise<void> {
    const objs: string[] = [];
    const stream = minio.listObjectsV2(env.STORAGE_BUCKET, `photos/${userId}/`, true);
    await new Promise<void>((resolve, reject) => {
      stream.on('data', (o) => { if (o.name) objs.push(o.name); });
      stream.on('end', resolve);
      stream.on('error', reject);
    });
    if (objs.length) await minio.removeObjects(env.STORAGE_BUCKET, objs);
  },
};
