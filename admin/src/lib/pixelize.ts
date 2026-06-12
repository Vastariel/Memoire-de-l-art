// pixelize.ts — client-side image → grid cells mapped to the 21 pigments.

import { nearestVariant, VARIANTS } from './palette';

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
