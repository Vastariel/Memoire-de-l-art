"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.storage = void 0;
const minio_1 = require("minio");
const sharp_1 = __importDefault(require("sharp"));
const env_1 = require("../config/env");
const minio = new minio_1.Client({
    endPoint: env_1.env.STORAGE_ENDPOINT,
    port: env_1.env.STORAGE_PORT,
    useSSL: env_1.env.STORAGE_USE_SSL,
    accessKey: env_1.env.STORAGE_ACCESS_KEY,
    secretKey: env_1.env.STORAGE_SECRET_KEY,
});
exports.storage = {
    /**
     * Process & store a submitted photo. The raw photo is what the vitrail shows,
     * so it is NOT tinted. EXIF (incl. GPS) is stripped: sharp drops metadata by
     * default; .rotate() bakes orientation first so we can discard the tag.
     */
    async uploadPhoto(rawBuffer, userId, photoId) {
        const processed = await (0, sharp_1.default)(rawBuffer)
            .rotate() // apply EXIF orientation, then drop metadata
            .resize(1024, 1024, { fit: 'cover', position: 'center' })
            .jpeg({ quality: 86, progressive: true })
            .toBuffer();
        const key = `photos/${userId}/${photoId}.jpg`;
        await minio.putObject(env_1.env.STORAGE_BUCKET, key, processed, processed.length, {
            'Content-Type': 'image/jpeg',
            'Cache-Control': 'public, max-age=31536000, immutable',
        });
        const scheme = env_1.env.STORAGE_USE_SSL ? 'https' : 'http';
        return { key, url: `${scheme}://${env_1.env.STORAGE_ENDPOINT}/${env_1.env.STORAGE_BUCKET}/${key}` };
    },
    async deletePhoto(key) {
        try {
            await minio.removeObject(env_1.env.STORAGE_BUCKET, key);
        }
        catch { /* already gone */ }
    },
    /** Remove every object under a user's prefix (RGPD erasure). */
    async deleteUserPhotos(userId) {
        const objs = [];
        const stream = minio.listObjectsV2(env_1.env.STORAGE_BUCKET, `photos/${userId}/`, true);
        await new Promise((resolve, reject) => {
            stream.on('data', (o) => { if (o.name)
                objs.push(o.name); });
            stream.on('end', resolve);
            stream.on('error', reject);
        });
        if (objs.length)
            await minio.removeObjects(env_1.env.STORAGE_BUCKET, objs);
    },
};
//# sourceMappingURL=storage.js.map