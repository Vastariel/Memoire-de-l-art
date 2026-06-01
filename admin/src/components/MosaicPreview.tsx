import React from 'react';
import type { SegmentResult } from '../services/api';

// Same pigment palette as backend/src/services/segmentation.ts
const PIGMENT_HEX: Record<string, string> = {
  vermillion:  '#D7472F',
  sienna:      '#9C5A33',
  ochre:       '#D69A3C',
  saffron:     '#E8B53C',
  olive:       '#7E8B3F',
  viridian:    '#2E7D5B',
  teal:        '#2A8C8A',
  cobalt:      '#2D5FA6',
  ultramarine: '#34408C',
  aubergine:   '#6E3A6B',
  rose:        '#C45B7C',
  slate:       '#4A5763',
};

interface Props {
  result: SegmentResult;
  maxPx?: number;
}

export const MosaicPreview: React.FC<Props> = ({ result, maxPx = 560 }) => {
  const { cols, rows, cells, zones } = result;
  const cellPx = Math.max(2, Math.floor(Math.min(maxPx / cols, maxPx / rows)));

  const zoneMap = new Map(zones.map(z => [z.id, z.targetHex]));
  // Build a grid for quick lookup
  const grid = new Array(cols * rows).fill('#EBE3D2');
  for (const cell of cells) {
    grid[cell.row * cols + cell.col] = zoneMap.get(cell.zoneId) ?? '#EBE3D2';
  }

  return (
    <div>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${cols}, ${cellPx}px)`,
          gap: 1,
          background: '#EBE3D2',
          padding: 4,
          borderRadius: 8,
          width: 'fit-content',
          margin: '0 auto',
        }}
      >
        {grid.map((color, i) => (
          <div key={i} style={{ width: cellPx, height: cellPx, background: color, borderRadius: 2 }} />
        ))}
      </div>
      <div style={{ marginTop: 16, display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {zones.map(z => (
          <span
            key={z.id}
            style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '4px 10px', borderRadius: 20,
              background: '#f5f5f5', fontSize: 12,
            }}
          >
            <span style={{
              width: 12, height: 12, borderRadius: 3,
              background: PIGMENT_HEX[z.id] ?? z.targetHex, flexShrink: 0,
            }} />
            {z.pigment} <span style={{ color: '#999' }}>({z.cellCount} blocs)</span>
          </span>
        ))}
      </div>
    </div>
  );
};
