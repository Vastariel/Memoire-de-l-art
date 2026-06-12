// palette.ts — the fixed 21 museum pigments / 7 families, mirroring the mobile
// engine (engine/mosaic_engine.dart). Admin artworks map image colours to the
// nearest of these so the phone can render them with the same palette.

export interface FamilyDef {
  key: string;
  day: number; // default Mon→Sun order
  nameFr: string;
  nameEn: string;
  variants: string[];
}

export const FAMILIES: FamilyDef[] = [
  { key: 'bleus', day: 1, nameFr: 'Bleus', nameEn: 'Blues', variants: ['outremer', 'cobalt', 'azur'] },
  { key: 'ors', day: 2, nameFr: 'Ors', nameEn: 'Golds', variants: ['safran', 'ocre', 'ambre'] },
  { key: 'verts', day: 3, nameFr: 'Verts', nameEn: 'Greens', variants: ['veronese', 'olive', 'sauge'] },
  { key: 'terres', day: 4, nameFr: 'Terres', nameEn: 'Earths', variants: ['sienne', 'brulee', 'ombre'] },
  { key: 'roses', day: 5, nameFr: 'Roses', nameEn: 'Roses', variants: ['rose', 'lilas', 'prune'] },
  { key: 'rouges', day: 6, nameFr: 'Rouges', nameEn: 'Reds', variants: ['vermillon', 'garance', 'brique'] },
  { key: 'gris', day: 7, nameFr: 'Gris', nameEn: 'Greys', variants: ['ardoise', 'taupe', 'lin'] },
];

export interface VariantDef {
  key: string;
  familyKey: string;
  nameFr: string;
  nameEn: string;
  hex: string;
}

export const VARIANTS: VariantDef[] = [
  { key: 'outremer', familyKey: 'bleus', nameFr: 'Outremer', nameEn: 'Ultramarine', hex: '#2C3A86' },
  { key: 'cobalt', familyKey: 'bleus', nameFr: 'Cobalt', nameEn: 'Cobalt', hex: '#2D5FA6' },
  { key: 'azur', familyKey: 'bleus', nameFr: 'Azur', nameEn: 'Azure', hex: '#5B8FC9' },
  { key: 'safran', familyKey: 'ors', nameFr: 'Safran', nameEn: 'Saffron', hex: '#E8B53C' },
  { key: 'ocre', familyKey: 'ors', nameFr: 'Ocre', nameEn: 'Ochre', hex: '#CC8B3C' },
  { key: 'ambre', familyKey: 'ors', nameFr: 'Ambre', nameEn: 'Amber', hex: '#C2792E' },
  { key: 'veronese', familyKey: 'verts', nameFr: 'Vert véronèse', nameEn: 'Veronese', hex: '#2E7D5B' },
  { key: 'olive', familyKey: 'verts', nameFr: 'Olive', nameEn: 'Olive', hex: '#7E8B3F' },
  { key: 'sauge', familyKey: 'verts', nameFr: 'Sauge', nameEn: 'Sage', hex: '#9BA677' },
  { key: 'sienne', familyKey: 'terres', nameFr: 'Terre de Sienne', nameEn: 'Sienna', hex: '#9C5A33' },
  { key: 'brulee', familyKey: 'terres', nameFr: 'Terre brûlée', nameEn: 'Burnt earth', hex: '#6E3B25' },
  { key: 'ombre', familyKey: 'terres', nameFr: 'Terre d’ombre', nameEn: 'Umber', hex: '#4A3526' },
  { key: 'rose', familyKey: 'roses', nameFr: 'Rose', nameEn: 'Rose', hex: '#C45B7C' },
  { key: 'lilas', familyKey: 'roses', nameFr: 'Lilas', nameEn: 'Lilac', hex: '#9A6FA6' },
  { key: 'prune', familyKey: 'roses', nameFr: 'Prune', nameEn: 'Plum', hex: '#6E3A6B' },
  { key: 'vermillon', familyKey: 'rouges', nameFr: 'Vermillon', nameEn: 'Vermilion', hex: '#D7472F' },
  { key: 'garance', familyKey: 'rouges', nameFr: 'Garance', nameEn: 'Madder', hex: '#A8324A' },
  { key: 'brique', familyKey: 'rouges', nameFr: 'Brique', nameEn: 'Brick', hex: '#B5543A' },
  { key: 'ardoise', familyKey: 'gris', nameFr: 'Ardoise', nameEn: 'Slate', hex: '#4A5763' },
  { key: 'taupe', familyKey: 'gris', nameFr: 'Taupe', nameEn: 'Taupe', hex: '#8A7E70' },
  { key: 'lin', familyKey: 'gris', nameFr: 'Lin', nameEn: 'Flax', hex: '#CBBFA9' },
];

export function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.replace('#', ''), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

const _RGB = VARIANTS.map(v => ({ v, rgb: hexToRgb(v.hex) }));

/// Nearest of the 21 pigments to a raw RGB colour (weighted-RGB distance).
export function nearestVariant(r: number, g: number, b: number): VariantDef {
  let best = _RGB[0].v;
  let bestD = Infinity;
  for (const { v, rgb } of _RGB) {
    const rmean = (rgb[0] + r) / 2;
    const dr = rgb[0] - r, dg = rgb[1] - g, db = rgb[2] - b;
    const d = (2 + rmean / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rmean) / 256) * db * db;
    if (d < bestD) { bestD = d; best = v; }
  }
  return best;
}
