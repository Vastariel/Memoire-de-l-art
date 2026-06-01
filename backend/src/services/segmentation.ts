import sharp from 'sharp';

// ── Types ─────────────────────────────────────────────────────────────────────

export interface SegmentedArtwork {
  cols:  number;
  rows:  number;
  cells: CellData[];
  zones: ZoneData[];
}

export interface CellData {
  index:  number;
  col:    number;
  row:    number;
  zoneId: string;
}

export interface ZoneData {
  id:        string;
  pigment:   string;   // same as id — kept for API compat
  label:     string;   // evocative French name
  cellCount: number;
  targetHex: string;
}

type RGB = [number, number, number];

// ── K-means segmentation ──────────────────────────────────────────────────────

export async function segmentArtwork(
  imageBuffer: Buffer,
  blockSize = 16,
  numZones  = 16,
): Promise<SegmentedArtwork> {
  const meta = await sharp(imageBuffer).metadata();
  const srcW = meta.width  ?? 512;
  const srcH = meta.height ?? 512;

  const cols = Math.min(Math.max(Math.round(srcW / blockSize), 4), 32);
  const rows = Math.min(Math.max(Math.round(srcH / blockSize), 4), 40);

  const { data } = await sharp(imageBuffer)
    .resize(cols, rows, { fit: 'fill' })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  // Extract pixel array
  const pixels: RGB[] = [];
  for (let i = 0; i < data.length; i += 3) {
    pixels.push([data[i]!, data[i + 1]!, data[i + 2]!]);
  }

  // K-means clustering (k-means++ init, max 30 iterations)
  const k          = Math.min(numZones, pixels.length);
  const centroids  = kMeanspp(pixels, k);
  const { assignments } = kMeansIterate(pixels, centroids, 30);

  // Build zone list — zone IDs are zero-padded slugs
  const sums = Array.from({ length: k }, () => [0, 0, 0, 0] as [number, number, number, number]);
  for (let i = 0; i < pixels.length; i++) {
    const j = assignments[i]!;
    sums[j]![0] += pixels[i]![0];
    sums[j]![1] += pixels[i]![1];
    sums[j]![2] += pixels[i]![2];
    sums[j]![3]++;
  }

  // Keep only non-empty clusters, sorted by cell count ascending
  const zoneList: ZoneData[] = [];
  const zoneMap  = new Map<number, string>(); // centroid index → zone ID

  const occupied = sums
    .map((s, i) => ({ i, r: s[0], g: s[1], b: s[2], count: s[3] }))
    .filter(z => z.count > 0)
    .sort((a, b) => a.count - b.count);

  for (let rank = 0; rank < occupied.length; rank++) {
    const { i, r, g, b, count } = occupied[rank]!;
    const cr = Math.round(r / count);
    const cg = Math.round(g / count);
    const cb = Math.round(b / count);
    const id  = `zone-${String(rank + 1).padStart(2, '0')}`;
    zoneMap.set(i, id);
    zoneList.push({
      id,
      pigment:   id,
      label:     evocativeName(cr, cg, cb),
      cellCount: count,
      targetHex: rgbToHex(cr, cg, cb),
    });
  }

  // Build cells with final zone IDs
  const cells: CellData[] = pixels.map((_, idx) => ({
    index:  idx,
    col:    idx % cols,
    row:    Math.floor(idx / cols),
    zoneId: zoneMap.get(assignments[idx]!)!,
  }));

  return { cols, rows, cells, zones: zoneList };
}

// ── K-means++ initialisation ──────────────────────────────────────────────────

function kMeanspp(pixels: RGB[], k: number): RGB[] {
  const centroids: RGB[] = [pixels[Math.floor(Math.random() * pixels.length)]!];
  while (centroids.length < k) {
    const dists = pixels.map(p => Math.min(...centroids.map(c => distSq(p, c))));
    const total = dists.reduce((a, b) => a + b, 0);
    let r = Math.random() * total;
    for (let i = 0; i < dists.length; i++) {
      r -= dists[i]!;
      if (r <= 0) { centroids.push(pixels[i]!); break; }
    }
    if (centroids.length < k && r > 0) {
      centroids.push(pixels[pixels.length - 1]!);
    }
  }
  return centroids;
}

function kMeansIterate(
  pixels: RGB[], centroids: RGB[], maxIter: number,
): { centroids: RGB[]; assignments: Int32Array } {
  const k           = centroids.length;
  const assignments = new Int32Array(pixels.length);
  let   cents       = centroids.map(c => [...c] as RGB);

  for (let iter = 0; iter < maxIter; iter++) {
    let changed = false;

    // Assign each pixel to nearest centroid
    for (let i = 0; i < pixels.length; i++) {
      let best = 0, bestDist = Infinity;
      for (let j = 0; j < k; j++) {
        const d = distSq(pixels[i]!, cents[j]!);
        if (d < bestDist) { bestDist = d; best = j; }
      }
      if (assignments[i] !== best) { assignments[i] = best; changed = true; }
    }
    if (!changed) break;

    // Recompute centroids
    const sums = Array.from({ length: k }, () => [0, 0, 0, 0] as [number, number, number, number]);
    for (let i = 0; i < pixels.length; i++) {
      const j = assignments[i]!;
      sums[j]![0] += pixels[i]![0];
      sums[j]![1] += pixels[i]![1];
      sums[j]![2] += pixels[i]![2];
      sums[j]![3]++;
    }
    for (let j = 0; j < k; j++) {
      const [sr, sg, sb, cnt] = sums[j]!;
      if (cnt > 0) cents[j] = [sr / cnt, sg / cnt, sb / cnt];
    }
  }

  return { centroids: cents, assignments };
}

function distSq(a: RGB, b: RGB): number {
  const dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
  return dr * dr + dg * dg + db * db;
}

function rgbToHex(r: number, g: number, b: number): string {
  return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');
}

// ── Evocative French colour names ─────────────────────────────────────────────

interface NameEntry {
  hMin: number; hMax: number;
  sMin: number; sMax: number;
  lMin: number; lMax: number;
  names: string[];
}

// Ordered from most specific to most general
const NAME_TABLE: NameEntry[] = [
  // Achromatic (very low saturation)
  { hMin:0, hMax:360, sMin:0, sMax:0.10, lMin:0.88, lMax:1.00, names:['Craie blanche','Lait de chaux','Brume d\'hiver'] },
  { hMin:0, hMax:360, sMin:0, sMax:0.12, lMin:0.65, lMax:0.88, names:['Pierre calcaire','Givre matinal','Cendre pâle'] },
  { hMin:0, hMax:360, sMin:0, sMax:0.12, lMin:0.38, lMax:0.65, names:['Cendre froide','Granit poli','Brume d\'automne'] },
  { hMin:0, hMax:360, sMin:0, sMax:0.12, lMin:0.00, lMax:0.38, names:['Encre d\'imprimerie','Nuit de forge','Ombre profonde'] },

  // Red — warm
  { hMin:350, hMax:360, sMin:0.45, sMax:1.0, lMin:0.30, lMax:0.55, names:['Sang de bœuf','Grenade ouverte','Laque de garance'] },
  { hMin:  0, hMax: 15, sMin:0.55, sMax:1.0, lMin:0.30, lMax:0.52, names:['Vermillon d\'atelier','Brique ancienne','Feu couvant'] },
  { hMin:  0, hMax: 15, sMin:0.45, sMax:1.0, lMin:0.52, lMax:0.72, names:['Pivoine tardive','Coquelicot pâle','Rose de Damas'] },
  { hMin:345, hMax:360, sMin:0.45, sMax:1.0, lMin:0.45, lMax:0.70, names:['Cerise tardive','Grenadine','Garance rosée'] },
  { hMin:  0, hMax: 20, sMin:0.15, sMax:0.50, lMin:0.28, lMax:0.52, names:['Terre de Sienne','Bois flotté','Argile cuite'] },

  // Orange
  { hMin: 15, hMax: 45, sMin:0.60, sMax:1.0, lMin:0.42, lMax:0.62, names:['Safran du marché','Braise vive','Cuivre battu'] },
  { hMin: 15, hMax: 45, sMin:0.40, sMax:0.85, lMin:0.58, lMax:0.78, names:['Abricot mûr','Aube d\'été','Miel d\'acacia'] },
  { hMin: 20, hMax: 42, sMin:0.25, sMax:0.65, lMin:0.28, lMax:0.50, names:['Ocre de carrière','Terre brûlée','Sable chaud'] },
  { hMin: 25, hMax: 45, sMin:0.10, sMax:0.35, lMin:0.55, lMax:0.78, names:['Sable fin','Lin naturel','Écorce claire'] },

  // Yellow
  { hMin: 45, hMax: 72, sMin:0.60, sMax:1.0, lMin:0.52, lMax:0.78, names:['Aube dorée','Blé mûr','Or des champs'] },
  { hMin: 45, hMax: 72, sMin:0.45, sMax:1.0, lMin:0.38, lMax:0.55, names:['Ambre ancien','Cire d\'abeille','Feuille de tabac'] },
  { hMin: 45, hMax: 72, sMin:0.25, sMax:0.55, lMin:0.62, lMax:0.85, names:['Parchemin vieilli','Ivoire jauni','Lin séché'] },
  { hMin: 48, hMax: 70, sMin:0.50, sMax:1.0, lMin:0.78, lMax:1.00, names:['Lumière de midi','Citron d\'été','Paille fraîche'] },

  // Yellow-green
  { hMin: 72, hMax:105, sMin:0.40, sMax:0.90, lMin:0.32, lMax:0.58, names:['Mousse de forêt','Lichen sur pierre','Verdure d\'avril'] },
  { hMin: 72, hMax:105, sMin:0.30, sMax:0.70, lMin:0.52, lMax:0.72, names:['Prairie au matin','Jeune pousse','Pistache claire'] },
  { hMin: 72, hMax:105, sMin:0.15, sMax:0.40, lMin:0.42, lMax:0.65, names:['Sauge pâle','Vert de gris','Fougère sèche'] },

  // Green
  { hMin:105, hMax:150, sMin:0.45, sMax:1.0, lMin:0.22, lMax:0.42, names:['Forêt profonde','Vieux buis','Épicéa sombre'] },
  { hMin:105, hMax:150, sMin:0.40, sMax:0.90, lMin:0.32, lMax:0.52, names:['Vert véronèse','Feuille de lierre','Herbe des prés'] },
  { hMin:105, hMax:150, sMin:0.18, sMax:0.48, lMin:0.38, lMax:0.58, names:['Sauge argentée','Eucalyptus pâle','Feuille morte'] },

  // Teal
  { hMin:150, hMax:192, sMin:0.42, sMax:0.90, lMin:0.28, lMax:0.52, names:['Mer du Nord','Patine de bronze','Malachite ancienne'] },
  { hMin:150, hMax:192, sMin:0.38, sMax:0.85, lMin:0.42, lMax:0.62, names:['Lagon secret','Turquoise pâle','Glace arctique'] },
  { hMin:150, hMax:192, sMin:0.15, sMax:0.42, lMin:0.48, lMax:0.68, names:['Brume marine','Menthe séchée','Eucalyptus bleu'] },

  // Blue
  { hMin:192, hMax:240, sMin:0.50, sMax:1.0, lMin:0.25, lMax:0.48, names:['Bleu de Prusse','Nuit bleue','Denim profond'] },
  { hMin:192, hMax:240, sMin:0.50, sMax:1.0, lMin:0.42, lMax:0.62, names:['Azur d\'été','Cobalt profond','Ciel de Provence'] },
  { hMin:192, hMax:240, sMin:0.48, sMax:1.0, lMin:0.55, lMax:0.75, names:['Bleu porcelaine','Horizon lointain','Lavande bleue'] },
  { hMin:192, hMax:245, sMin:0.18, sMax:0.48, lMin:0.38, lMax:0.62, names:['Ardoise mouillée','Pierre de lune','Gris bleuté'] },

  // Indigo / deep blue
  { hMin:240, hMax:268, sMin:0.42, sMax:1.0, lMin:0.18, lMax:0.42, names:['Nuit d\'encre','Bleu outremer','Minuit profond'] },
  { hMin:240, hMax:268, sMin:0.38, sMax:0.90, lMin:0.38, lMax:0.58, names:['Iris sauvage','Velours indigo','Bleu de nuit'] },

  // Violet / purple
  { hMin:268, hMax:312, sMin:0.28, sMax:0.82, lMin:0.22, lMax:0.48, names:['Prune tardive','Ombre d\'aubergine','Raisin de Bourgogne'] },
  { hMin:268, hMax:312, sMin:0.28, sMax:0.80, lMin:0.42, lMax:0.62, names:['Lilas du soir','Bruyère sauvage','Lavande froide'] },
  { hMin:268, hMax:312, sMin:0.12, sMax:0.38, lMin:0.48, lMax:0.70, names:['Mauve des champs','Parme pâle','Gris violet'] },

  // Pink / rose
  { hMin:312, hMax:345, sMin:0.35, sMax:0.85, lMin:0.42, lMax:0.68, names:['Rose de l\'aube','Quartz rosé','Pétale ancien'] },
  { hMin:312, hMax:345, sMin:0.38, sMax:0.90, lMin:0.30, lMax:0.52, names:['Cerise confite','Framboise sauvage','Magenta doux'] },
  { hMin:312, hMax:345, sMin:0.12, sMax:0.38, lMin:0.55, lMax:0.78, names:['Poudre de nacre','Vieux rose','Lilas rosé'] },
];

function rgbToHsl(r: number, g: number, b: number): [number, number, number] {
  const rn = r / 255, gn = g / 255, bn = b / 255;
  const max = Math.max(rn, gn, bn), min = Math.min(rn, gn, bn);
  const l   = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h: number;
  if (max === rn)      h = ((gn - bn) / d + (gn < bn ? 6 : 0)) / 6;
  else if (max === gn) h = ((bn - rn) / d + 2) / 6;
  else                 h = ((rn - gn) / d + 4) / 6;
  return [h * 360, s, l];
}

export function evocativeName(r: number, g: number, b: number): string {
  const [h, s, l] = rgbToHsl(r, g, b);

  for (const e of NAME_TABLE) {
    // Handle hue ranges that wrap around 360
    const hueOk = e.hMin > e.hMax
      ? h >= e.hMin || h <= e.hMax
      : h >= e.hMin && h <= e.hMax;

    if (hueOk && s >= e.sMin && s <= e.sMax && l >= e.lMin && l <= e.lMax) {
      // Deterministic pick from the names array
      const idx = ((r * 31 + g * 17 + b * 7) >>> 0) % e.names.length;
      return e.names[idx]!;
    }
  }

  // Fallback based on luminance only
  if (l < 0.20) return 'Ombre ancienne';
  if (l > 0.80) return 'Lumière dorée';
  return 'Teinte naturelle';
}
