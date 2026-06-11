"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fastify_1 = __importDefault(require("fastify"));
const cors_1 = __importDefault(require("@fastify/cors"));
const helmet_1 = __importDefault(require("@fastify/helmet"));
const rate_limit_1 = __importDefault(require("@fastify/rate-limit"));
const jwt_1 = __importDefault(require("@fastify/jwt"));
const multipart_1 = __importDefault(require("@fastify/multipart"));
const node_cron_1 = __importDefault(require("node-cron"));
const auth_1 = require("./routes/auth");
const weeks_1 = require("./routes/weeks");
const days_1 = require("./routes/days");
const instances_1 = require("./routes/instances");
const claims_1 = require("./routes/claims");
const photos_1 = require("./routes/photos");
const contributions_1 = require("./routes/contributions");
const guesses_1 = require("./routes/guesses");
const me_1 = require("./routes/me");
const admin_1 = require("./routes/admin");
const env_1 = require("./config/env");
const db_1 = require("./services/db");
const cycle_1 = require("./services/cycle");
async function start() {
    const app = (0, fastify_1.default)({ logger: { level: env_1.env.LOG_LEVEL }, trustProxy: true });
    await app.register(helmet_1.default, { contentSecurityPolicy: false });
    await app.register(cors_1.default, { origin: env_1.env.CORS_ORIGINS.split(','), credentials: true });
    await app.register(rate_limit_1.default, { max: 120, timeWindow: '1 minute' });
    await app.register(jwt_1.default, { secret: env_1.env.JWT_SECRET });
    await app.register(multipart_1.default, { limits: { fileSize: 12 * 1024 * 1024 } });
    app.decorate('authenticate', async (req, reply) => {
        try {
            await req.jwtVerify();
        }
        catch {
            return reply.code(401).send({ error: 'Non autorisé.' });
        }
    });
    // ── Routes (v2) ──────────────────────────────────────────────
    await app.register(auth_1.authRoutes, { prefix: '/api/v1/auth' });
    await app.register(weeks_1.weekRoutes, { prefix: '/api/v1/weeks' });
    await app.register(days_1.dayRoutes, { prefix: '/api/v1/days' });
    await app.register(instances_1.instanceRoutes, { prefix: '/api/v1/instances' });
    await app.register(claims_1.claimRoutes, { prefix: '/api/v1/claims' });
    await app.register(photos_1.photoRoutes, { prefix: '/api/v1/photos' });
    await app.register(contributions_1.contributionRoutes, { prefix: '/api/v1/contributions' });
    await app.register(guesses_1.guessRoutes, { prefix: '/api/v1/guesses' });
    await app.register(me_1.meRoutes, { prefix: '/api/v1/me' });
    await app.register(admin_1.adminRoutes, { prefix: '/api/admin' });
    app.get('/health', async () => ({ status: 'ok', ts: new Date().toISOString() }));
    // ── Weekly UTC cycle ─────────────────────────────────────────
    // New artwork goes live Monday 00:00 UTC; reveal forced Sunday 23:59 UTC.
    node_cron_1.default.schedule('0 0 * * 1', async () => {
        try {
            await (0, cycle_1.activateCurrentWeek)();
        }
        catch (err) {
            app.log.error({ err }, 'activateCurrentWeek failed');
        }
    }, { timezone: 'UTC' });
    node_cron_1.default.schedule('59 23 * * 0', async () => {
        try {
            await (0, cycle_1.revealCurrentWeek)();
        }
        catch (err) {
            app.log.error({ err }, 'revealCurrentWeek failed');
        }
    }, { timezone: 'UTC' });
    await db_1.db.query('SELECT 1');
    await app.listen({ port: env_1.env.PORT, host: '0.0.0.0' });
    app.log.info(`Server running on port ${env_1.env.PORT}`);
}
start().catch(err => {
    console.error(err);
    process.exit(1);
});
//# sourceMappingURL=index.js.map