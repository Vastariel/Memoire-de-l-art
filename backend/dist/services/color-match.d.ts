import type { ColorMatchResult } from '../models/types';
export declare function hexToRgb(hex: string): [number, number, number];
export declare function colorDelta(a: [number, number, number], b: [number, number, number]): number;
export declare function analyzePhoto(imageBuffer: Buffer, targetHex: string): Promise<ColorMatchResult>;
//# sourceMappingURL=color-match.d.ts.map