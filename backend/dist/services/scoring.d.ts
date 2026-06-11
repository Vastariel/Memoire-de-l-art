import { db } from './db';
export declare const PHOTO_POINTS = 10;
export declare const INSTANCE_COMPLETE_BONUS = 50;
export declare const BET_BAREME: number[];
/** Streak multiplier ×1.1 per consecutive day, capped ×1.5. */
export declare function streakMultiplier(days: number): number;
/** Points for a photo: (base + match bonus) × streak multiplier. */
export declare function photoPoints(matchBonus: number, streakDays: number): number;
export declare function betPoints(dayPlaced: number): number;
type Q = Pick<typeof db, 'query'>;
/** Add weekly points for a user in an instance (upsert). */
export declare function addPoints(q: Q, userId: string, instanceId: string, isoYear: number, isoWeek: number, pts: number): Promise<void>;
/** Bump the consecutive-day streak; returns the new current streak. */
export declare function bumpStreak(q: Q, userId: string, takenOn: string): Promise<number>;
/**
 * Collection eligibility for a user/artwork: 7 personal photos this week AND
 * at least one non-solo instance completed 100%. Solo does not count.
 */
export declare function isInCollection(userId: string, artworkId: string): Promise<boolean>;
export {};
//# sourceMappingURL=scoring.d.ts.map