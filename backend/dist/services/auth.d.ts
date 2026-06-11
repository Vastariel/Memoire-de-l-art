import type { AppUser, AuthProvider } from '../models/types';
export interface VerifiedIdentity {
    sub: string;
    email: string | null;
}
/** Verify the client-supplied token and return a stable subject id. */
export declare function verifyProvider(provider: AuthProvider, token: string): Promise<VerifiedIdentity>;
export declare function upsertUser(provider: AuthProvider, identity: VerifiedIdentity, opts?: {
    pseudo?: string;
    locale?: string;
    consent?: boolean;
}): Promise<AppUser>;
export declare function loadUser(id: string): Promise<AppUser | null>;
//# sourceMappingURL=auth.d.ts.map