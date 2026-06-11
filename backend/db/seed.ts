// seed.ts — seed the current ISO week with "Le Semeur" (12×16), active.
// Run: DATABASE_URL=... npx tsx db/seed.ts   (or: npm run db:seed)
// Ports the mobile engine (engine/mosaic_engine.dart) so server cells match.

import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const COLS = 12, ROWS = 16;

const PIG: Record<string, string> = {
  outremer: '#2C3A86', cobalt: '#2D5FA6', azur: '#5B8FC9',
  safran: '#E8B53C', ocre: '#CC8B3C', ambre: '#C2792E',
  veronese: '#2E7D5B', olive: '#7E8B3F', sauge: '#9BA677',
  sienne: '#9C5A33', brulee: '#6E3B25', ombre: '#4A3526',
  rose: '#C45B7C', lilas: '#9A6FA6', prune: '#6E3A6B',
  vermillon: '#D7472F', garance: '#A8324A', brique: '#B5543A',
  ardoise: '#4A5763', taupe: '#8A7E70', lin: '#CBBFA9',
};

const FAMILIES: Record<string, { day: number; fr: string; en: string; variants: string[] }> = {
  bleus: { day: 1, fr: 'Bleus', en: 'Blues', variants: ['outremer', 'cobalt', 'azur'] },
  ors: { day: 2, fr: 'Ors', en: 'Golds', variants: ['safran', 'ocre', 'ambre'] },
  verts: { day: 3, fr: 'Verts', en: 'Greens', variants: ['veronese', 'olive', 'sauge'] },
  terres: { day: 4, fr: 'Terres', en: 'Earths', variants: ['sienne', 'brulee', 'ombre'] },
  roses: { day: 5, fr: 'Roses', en: 'Roses', variants: ['rose', 'lilas', 'prune'] },
  rouges: { day: 6, fr: 'Rouges', en: 'Reds', variants: ['vermillon', 'garance', 'brique'] },
  gris: { day: 7, fr: 'Gris', en: 'Greys', variants: ['ardoise', 'taupe', 'lin'] },
};

const VNAMES: Record<string, [string, string]> = {
  outremer: ['Outremer', 'Ultramarine'], cobalt: ['Cobalt', 'Cobalt'], azur: ['Azur', 'Azure'],
  safran: ['Safran', 'Saffron'], ocre: ['Ocre', 'Ochre'], ambre: ['Ambre', 'Amber'],
  veronese: ['Vert véronèse', 'Veronese'], olive: ['Olive', 'Olive'], sauge: ['Sauge', 'Sage'],
  sienne: ['Terre de Sienne', 'Sienna'], brulee: ['Terre brûlée', 'Burnt earth'], ombre: ['Terre d’ombre', 'Umber'],
  rose: ['Rose', 'Rose'], lilas: ['Lilas', 'Lilac'], prune: ['Prune', 'Plum'],
  vermillon: ['Vermillon', 'Vermilion'], garance: ['Garance', 'Madder'], brique: ['Brique', 'Brick'],
  ardoise: ['Ardoise', 'Slate'], taupe: ['Taupe', 'Taupe'], lin: ['Lin', 'Flax'],
};

const familyOf = (v: string) => Object.keys(FAMILIES).find(f => FAMILIES[f]!.variants.includes(v))!;
const frac = (x: number) => x - Math.floor(x);
const hash = (i: number) => frac(Math.sin(i * 127.1) * 43758.5453);
const SUNX = 8.4, SUNY = 4.6;
const dSun = (c: number, r: number) => Math.hypot((c - SUNX) * 0.92, (r - SUNY) * 1.12);

function familyAt(col: number, row: number): string {
  const d = dSun(col, row);
  if (d < 2.7) return 'ors';
  if (row <= 2) return 'bleus';
  if (row <= 5) return (d < 4.3 && row >= 3) ? 'roses' : 'bleus';
  if (row <= 8) return 'verts';
  if (row <= 11) return hash(col * 3 + row * 7) > 0.5 ? 'terres' : 'verts';
  if (col >= 3 && col <= 6 && row >= 10) return 'gris';
  if (hash(col * 7.3 + row * 3.1) > 0.84) return 'rouges';
  return 'terres';
}
function variantAt(col: number, row: number): string {
  const fam = familyAt(col, row);
  const d = dSun(col, row);
  if (fam === 'ors') return d < 1.5 ? 'safran' : (d < 2.1 ? 'ocre' : 'ambre');
  if (fam === 'bleus') return row <= 1 ? 'outremer' : (row <= 3 ? 'cobalt' : 'azur');
  const vs = FAMILIES[fam]!.variants;
  return vs[Math.floor(hash(col * 5.1 + row * 2.3) * vs.length) % vs.length]!;
}

function isoWeek(d = new Date()) {
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const dayNum = (date.getUTCDay() + 6) % 7;
  date.setUTCDate(date.getUTCDate() - dayNum + 3);
  const ft = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
  const fdn = (ft.getUTCDay() + 6) % 7;
  ft.setUTCDate(ft.getUTCDate() - fdn + 3);
  const week = 1 + Math.round((date.getTime() - ft.getTime()) / (7 * 86400000));
  return { year: date.getUTCFullYear(), week };
}

async function main() {
  const { year, week } = isoWeek();
  const id = `w${year}-${String(week).padStart(2, '0')}`;

  const cells = [];
  for (let row = 0; row < ROWS; row++) {
    for (let col = 0; col < COLS; col++) {
      const variant = variantAt(col, row);
      cells.push({ i: row * COLS + col, col, row, family: familyOf(variant), variant });
    }
  }

  await pool.query(
    `INSERT INTO artworks (id, title_fr, title_en, artist, year_, description_fr, description_en,
                           source_license, cols, rows, cells, status, iso_year, iso_week)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,'active',$12,$13)
     ON CONFLICT (id) DO UPDATE SET cells=$11::jsonb, status='active', iso_year=$12, iso_week=$13`,
    [id, 'Le Semeur au soleil couchant', 'The Sower at Sunset', 'Vincent van Gogh', 1888,
      'Huile sur toile, Kröller-Müller Museum.', 'Oil on canvas, Kröller-Müller Museum.',
      'Domaine public — Wikimedia Commons', COLS, ROWS, JSON.stringify(cells), year, week],
  );

  await pool.query(`DELETE FROM color_families WHERE artwork_id = $1`, [id]);
  for (const [key, f] of Object.entries(FAMILIES)) {
    await pool.query(
      `INSERT INTO color_families (artwork_id, key, day_, name_fr, name_en) VALUES ($1,$2,$3,$4,$5)`,
      [id, key, f.day, f.fr, f.en],
    );
    for (const v of f.variants) {
      await pool.query(
        `INSERT INTO color_variants (artwork_id, key, family_key, name_fr, name_en, hex)
         VALUES ($1,$2,$3,$4,$5,$6)
         ON CONFLICT (artwork_id, key) DO UPDATE SET family_key=$3, name_fr=$4, name_en=$5, hex=$6`,
        [id, v, key, VNAMES[v]![0], VNAMES[v]![1], PIG[v]],
      );
    }
  }

  console.log(`Seeded artwork ${id} (active) — ${cells.length} cells.`);
  await pool.end();
}

main().catch(e => { console.error(e); process.exit(1); });
