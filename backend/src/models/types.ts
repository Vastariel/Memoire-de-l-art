// types.ts — v2 domain types.

export type AuthProvider = 'google' | 'apple' | 'dev';
export type InstanceMode = 'shared' | 'separate';
export type ArtworkStatus = 'draft' | 'planned' | 'active' | 'revealed';

// JWT payload (cross-instance user). The backend keeps its own JWT.
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

// Result of analysing a submitted photo. Matching is laxiste: never rejected.
export interface ColorMatchResult {
  dominantHex: string;
  deltaE: number;       // distance to the target variant hue (lower = better)
  variance: number;     // image richness 0..1 (low = flat aplat)
  verdict: 'parfait' | 'correct' | 'libre'; // 'libre' = accepted, gentle feedback
  matchBonus: number;   // 0..15 points
}
