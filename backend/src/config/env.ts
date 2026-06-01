import { z } from 'zod';

const schema = z.object({
  PORT:         z.coerce.number().default(3000),
  LOG_LEVEL:    z.enum(['fatal','error','warn','info','debug','trace']).default('info'),
  NODE_ENV:     z.enum(['development','production','test']).default('development'),

  // Database
  DATABASE_URL: z.string().url(),

  // JWT
  JWT_SECRET:   z.string().min(32),

  // Object storage (MinIO / S3-compatible)
  STORAGE_ENDPOINT:   z.string(),
  STORAGE_PORT:       z.coerce.number().default(9000),
  STORAGE_USE_SSL:    z.coerce.boolean().default(false),
  STORAGE_ACCESS_KEY: z.string(),
  STORAGE_SECRET_KEY: z.string(),
  STORAGE_BUCKET:     z.string().default('memoire-de-lart'),

  // CORS
  CORS_ORIGINS: z.string().default('http://localhost:3001'),

  // Firebase (push notifications)
  FIREBASE_PROJECT_ID:      z.string().optional(),
  FIREBASE_PRIVATE_KEY:     z.string().optional(),
  FIREBASE_CLIENT_EMAIL:    z.string().optional(),

  // Color matching — distance threshold below which a photo is "perfect"
  COLOR_DELTA_PERFECT: z.coerce.number().default(25),
  COLOR_DELTA_ACCEPT:  z.coerce.number().default(55),

  // Admin panel authentication
  ADMIN_TOKEN: z.string().optional(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('❌  Invalid environment variables:\n', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
