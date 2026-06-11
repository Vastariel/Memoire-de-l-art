export type AuthProvider = 'google' | 'apple' | 'dev';
export type InstanceMode = 'shared' | 'separate';
export type ArtworkStatus = 'draft' | 'planned' | 'active' | 'revealed';
export interface JwtPayload {
    userId: string;
}
export interface AppUser {
    id: string;
    provider: AuthProvider;
    providerSub: string;
    email: string | null;
    pseudo: string | null;
    avatarPigment: string;
    locale: string;
    notifHour: number;
    notifMinute: number;
    consentRgpd: boolean;
}
export interface ArtworkCell {
    i: number;
    col: number;
    row: number;
    family: string;
    variant: string;
}
export interface FamilyDef {
    key: string;
    day: number;
    nameFr: string;
    nameEn: string;
}
export interface VariantDef {
    key: string;
    familyKey: string;
    nameFr: string;
    nameEn: string;
    hex: string;
}
export interface ColorMatchResult {
    dominantHex: string;
    deltaE: number;
    variance: number;
    verdict: 'parfait' | 'correct' | 'libre';
    matchBonus: number;
}
//# sourceMappingURL=types.d.ts.map