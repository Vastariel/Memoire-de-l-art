// pixelize.ts — client-side image → grid cells mapped to the 21 pigments.

import { hexToRgb, nearestVariant, VARIANTS, type VariantDef } from './palette';

export interface Cell {
  i: number;
  col: number;
  row: number;
  family: string;
  variant: string;
}

export interface CropParams {
  zoom: number; // 1..3
  offsetX: number; // -1..1 (fraction of slack)
  offsetY: number; // -1..1
}

/// Draw a 3:4 crop of [img] into [canvas] sized cols×rows (nearest sampling).
export function drawCrop(
  img: HTMLImageElement,
  canvas: HTMLCanvasElement,
  cols: number,
  rows: number,
  crop: CropParams,
): void {
  canvas.width = cols;
  canvas.height = rows;
  const ctx = canvas.getContext('2d')!;
  ctx.imageSmoothingEnabled = true;

  // Largest 3:4 region that fits the source, then zoom in and pan.
  const target = 3 / 4;
  const srcRatio = img.width / img.height;
  let cw: number, ch: number;
  if (srcRatio > target) {
    ch = img.height;
    cw = ch * target;
  } else {
    cw = img.width;
    ch = cw / target;
  }
  cw /= crop.zoom;
  ch /= crop.zoom;
  const slackX = img.width - cw;
  const slackY = img.height - ch;
  const sx = (slackX / 2) * (1 + crop.offsetX);
  const sy = (slackY / 2) * (1 + crop.offsetY);

  ctx.clearRect(0, 0, cols, rows);
  ctx.drawImage(img, sx, sy, cw, ch, 0, 0, cols, rows);
}

/// Read the grid canvas → cells mapped to the nearest pigment.
export function cellsFromCanvas(canvas: HTMLCanvasElement, cols: number, rows: number): Cell[] {
  const ctx = canvas.getContext('2d')!;
  const data = ctx.getImageData(0, 0, cols, rows).data;
  const cells: Cell[] = [];
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const p = (row * cols + col) * 4;
      const v = nearestVariant(data[p], data[p + 1], data[p + 2]);
      cells.push({ i: row * cols + col, col, row, family: v.familyKey, variant: v.key });
    }
  }
  return cells;
}

/// Re-balance family assignments so each family covers a quota proportional to
/// the day it is mapped to (day-1 = few cells, day-7 = many). The quotas form
/// weights 1..7 normalized to the total cell count. We then reassign cells in
/// order of "regret" (how much worse their second-best family would be) to the
/// best family that still has free quota.
export function rebalanceByDay(
  canvas: HTMLCanvasElement,
  cols: number,
  rows: number,
  dayByFamily: Record<string, number>,
): Cell[] {
  const ctx = canvas.getContext('2d')!;
  const data = ctx.getImageData(0, 0, cols, rows).data;
  const total = cols * rows;

  const families = Array.from(new Set(VARIANTS.map(v => v.familyKey)));
  const variantsByFamily: Record<string, VariantDef[]> = {};
  for (const v of VARIANTS) (variantsByFamily[v.familyKey] ??= []).push(v);

  // Quota per family ∝ day (1..7). Round + adjust so the sum equals total.
  const weights = families.map(f => dayByFamily[f] ?? 1);
  const sumW = weights.reduce((a, b) => a + b, 0);
  const quota: Record<string, number> = {};
  let assigned = 0;
  families.forEach((f, k) => {
    quota[f] = Math.floor((weights[k] / sumW) * total);
    assigned += quota[f];
  });
  // Distribute the rounding leftover to families with the highest day first.
  const order = [...families].sort((a, b) => (dayByFamily[b] ?? 0) - (dayByFamily[a] ?? 0));
  for (let i = 0; assigned < total; i++, assigned++) quota[order[i % order.length]]++;

  // For each cell: distance to every family (nearest variant in that family).
  interface CellScore { i: number; col: number; row: number; dists: Record<string, number>; bestFamily: string; regret: number; }
  const scores: CellScore[] = [];
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const p = (row * cols + col) * 4;
      const r = data[p], g = data[p + 1], b = data[p + 2];
      const dists: Record<string, number> = {};
      for (const f of families) {
        let best = Infinity;
        for (const v of variantsByFamily[f]) {
          const [vr, vg, vb] = hexToRgb(v.hex);
          const dr = vr - r, dg = vg - g, db = vb - b;
          const d = dr * dr + dg * dg + db * db;
          if (d < best) best = d;
        }
        dists[f] = best;
      }
      const sorted = families.slice().sort((a, b) => dists[a] - dists[b]);
      const bestFamily = sorted[0];
      const regret = dists[sorted[1]] - dists[sorted[0]]; // higher = stronger preference
      scores.push({ i: row * cols + col, col, row, dists, bestFamily, regret });
    }
  }

  // Greedy by regret: cells with the strongest preference are placed first.
  scores.sort((a, b) => b.regret - a.regret);

  const cells: Cell[] = new Array(total);
  for (const s of scores) {
    const ranked = families.slice().sort((a, b) => s.dists[a] - s.dists[b]);
    const family = ranked.find(f => quota[f] > 0) ?? ranked[0];
    quota[family]--;
    // Pick the closest variant inside the chosen family.
    let bestV = variantsByFamily[family][0];
    let bestD = Infinity;
    const p = (s.row * cols + s.col) * 4;
    const r = data[p], g = data[p + 1], b = data[p + 2];
    for (const v of variantsByFamily[family]) {
      const [vr, vg, vb] = hexToRgb(v.hex);
      const dr = vr - r, dg = vg - g, db = vb - b;
      const d = dr * dr + dg * dg + db * db;
      if (d < bestD) { bestD = d; bestV = v; }
    }
    cells[s.i] = { i: s.i, col: s.col, row: s.row, family, variant: bestV.key };
  }
  return cells;
}

/// Render a flat preview of cells onto a (larger) display canvas.
export function renderPreview(canvas: HTMLCanvasElement, cells: Cell[], cols: number, rows: number, px = 22): void {
  canvas.width = cols * px;
  canvas.height = rows * px;
  const ctx = canvas.getContext('2d')!;
  const hex: Record<string, string> = {};
  for (const v of VARIANTS) hex[v.key] = v.hex;
  const gap = Math.max(1, Math.round(px * 0.08));
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  for (const c of cells) {
    ctx.fillStyle = hex[c.variant] ?? '#999';
    ctx.fillRect(c.col * px, c.row * px, px - gap, px - gap);
  }
}
