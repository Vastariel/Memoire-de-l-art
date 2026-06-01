import sharp from 'sharp';
import type { ColorMatchResult } from '../models/types';

// Extract dominant colour via k-means on a 64×64 thumbnail (2 clusters,
// take the larger one — avoids background/noise bias from plain average).
async function dominantRgb(imageBuffer: Buffer): Promise<[number, number, number]> {
  const { data, info } = await sharp(imageBuffer)
    .resize(64, 64, { fit: 'cover' })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const pixels = info.width * info.height;

  // Quick 2-cluster k-means to isolate the dominant subject colour
  let r1 = data[0]!, g1 = data[1]!, b1 = data[2]!;
  let r2 = data[data.length - 3]!, g2 = data[data.length - 2]!, b3 = data[data.length - 1]!;

  for (let iter = 0; iter < 8; iter++) {
    let sr1 = 0, sg1 = 0, sb1 = 0, n1 = 0;
    let sr2 = 0, sg2 = 0, sb2 = 0, n2 = 0;
    for (let i = 0; i < data.length; i += 3) {
      const r = data[i]!, g = data[i + 1]!, b = data[i + 2]!;
      const d1 = (r-r1)**2 + (g-g1)**2 + (b-b1)**2;
      const d2 = (r-r2)**2 + (g-g2)**2 + (b-b3)**2;
      if (d1 <= d2) { sr1 += r; sg1 += g; sb1 += b; n1++; }
      else          { sr2 += r; sg2 += g; sb2 += b; n2++; }
    }
    if (n1 > 0) { r1 = sr1/n1; g1 = sg1/n1; b1 = sb1/n1; }
    if (n2 > 0) { r2 = sr2/n2; g2 = sg2/n2; b3 = sb2/n2; }
  }

  // Return the larger cluster's centroid (more representative of the subject)
  let n1 = 0;
  for (let i = 0; i < data.length; i += 3) {
    const r = data[i]!, g = data[i + 1]!, b = data[i + 2]!;
    const d1 = (r-r1)**2 + (g-g1)**2 + (b-b1)**2;
    const d2 = (r-r2)**2 + (g-g2)**2 + (b-b3)**2;
    if (d1 <= d2) n1++;
  }
  return n1 >= pixels / 2 ? [r1, g1, b1] : [r2, g2, b3];
}

function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.replace('#', ''), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

// Perceptual colour distance (weighted Euclidean in RGB — approximates CIE76)
function colorDelta(a: [number, number, number], b: [number, number, number]): number {
  const rmean = (a[0] + b[0]) / 2;
  const dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
  // Redmean formula (better perceptual accuracy than plain Euclidean)
  return Math.sqrt(
    (2 + rmean / 256) * dr * dr +
    4 * dg * dg +
    (2 + (255 - rmean) / 256) * db * db,
  );
}

// Adaptive accept threshold based on player count.
// Fewer players → each person covers more zones → wider tolerance.
export function adaptiveDelta(playerCount: number): number {
  return Math.max(40, Math.round(90 - playerCount * 5));
}

export async function colorMatch(
  imageBuffer: Buffer,
  targetHex:   string,
  playerCount: number,
): Promise<ColorMatchResult> {
  const dominant = await dominantRgb(imageBuffer);
  const target   = hexToRgb(targetHex);
  const delta    = colorDelta(dominant, target);

  const threshold = adaptiveDelta(playerCount);
  const perfect   = Math.round(threshold * 0.45);   // ~45% of accept = perfect

  const verdict: ColorMatchResult['verdict'] =
    delta <= perfect    ? 'parfait'
    : delta <= threshold ? 'correct'
    : 'rejeté';

  // Only replace zone colour when accepted; rejected photos are not stored
  const mode: 'replace' | 'blend' | 'rejected' =
    delta <= threshold ? 'replace' : 'rejected';

  return { delta: Math.round(delta), mode, verdict };
}
