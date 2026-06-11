import type { FastifyInstance } from 'fastify';
import type { AppUser } from '../models/types';
export declare function publicUser(u: AppUser): {
    id: string;
    pseudo: string | null;
    avatarPigment: string;
    locale: string;
    notifHour: number;
    notifMinute: number;
    consentRgpd: boolean;
};
export declare function authRoutes(app: FastifyInstance): Promise<void>;
//# sourceMappingURL=auth.d.ts.map