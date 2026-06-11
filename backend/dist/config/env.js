"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.env = void 0;
const zod_1 = require("zod");
const schema = zod_1.z.object({
    PORT: zod_1.z.coerce.number().default(3000),
    LOG_LEVEL: zod_1.z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
    NODE_ENV: zod_1.z.enum(['development', 'production', 'test']).default('development'),
    // Database
    DATABASE_URL: zod_1.z.string().url(),
    // JWT
    JWT_SECRET: zod_1.z.string().min(32),
    // Object storage (MinIO / S3-compatible)
    STORAGE_ENDPOINT: zod_1.z.string(),
    STORAGE_PORT: zod_1.z.coerce.number().default(9000),
    STORAGE_USE_SSL: zod_1.z.coerce.boolean().default(false),
    STORAGE_ACCESS_KEY: zod_1.z.string(),
    STORAGE_SECRET_KEY: zod_1.z.string(),
    STORAGE_BUCKET: zod_1.z.string().default('memoire-de-lart'),
    // CORS
    CORS_ORIGINS: zod_1.z.string().default('http://localhost:3001'),
    // Firebase (push notifications)
    FIREBASE_PROJECT_ID: zod_1.z.string().optional(),
    FIREBASE_PRIVATE_KEY: zod_1.z.string().optional(),
    FIREBASE_CLIENT_EMAIL: zod_1.z.string().optional(),
    // Color matching — distance threshold below which a photo is "perfect"
    COLOR_DELTA_PERFECT: zod_1.z.coerce.number().default(25),
    COLOR_DELTA_ACCEPT: zod_1.z.coerce.number().default(55),
    // Admin panel authentication
    ADMIN_TOKEN: zod_1.z.string().optional(),
    // Allow POST /auth/dev (no real OAuth) — handy before Firebase is set up.
    ALLOW_DEV_LOGIN: zod_1.z.coerce.boolean().default(false),
});
const parsed = schema.safeParse(process.env);
if (!parsed.success) {
    console.error('❌  Invalid environment variables:\n', parsed.error.flatten().fieldErrors);
    process.exit(1);
}
exports.env = parsed.data;
//# sourceMappingURL=env.js.map