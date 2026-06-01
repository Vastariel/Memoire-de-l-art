// mosaic.jsx — the "œuvre du mois" engine + renderer
// Exports: PIG, ARTWORK, shade, Mosaic, ZoneOverlay
// The artwork is a sunset landscape expressed as irregular pigment zones.
// Each zone has a target pigment and (once contributed) a contributor.

const PIG = {
  vermillion:'#D7472F', sienna:'#9C5A33', ochre:'#D69A3C', saffron:'#E8B53C',
  olive:'#7E8B3F', viridian:'#2E7D5B', teal:'#2A8C8A', cobalt:'#2D5FA6',
  ultramarine:'#34408C', aubergine:'#6E3A6B', rose:'#C45B7C', slate:'#4A5763',
};

// shade a hex by pct (-1..1); + lighter, - darker
function shade(hex, pct) {
  const n = parseInt(hex.slice(1), 16);
  let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  const t = pct < 0 ? 0 : 255, p = Math.abs(pct);
  r = Math.round((t - r) * p + r);
  g = Math.round((t - g) * p + g);
  b = Math.round((t - b) * p + b);
  return '#' + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

// deterministic per-cell jitter so filled zones read like a photo mosaic
function hash(i) { const x = Math.sin(i * 127.1) * 43758.5453; return x - Math.floor(x); }

const COLS = 14, ROWS = 18;

// zone definitions: pigment + display name + (optional) contributor
const ZONES = {
  skyDeep:   { pig:'ultramarine', name:'Bleu outremer',  by:{ pseudo:'Naomi',   date:'2 mai'  } },
  sky:       { pig:'cobalt',      name:'Cobalt',         by:{ pseudo:'Lucas',   date:'5 mai'  } },
  halo:      { pig:'ochre',       name:'Ocre',           by:{ pseudo:'Inès',    date:'7 mai'  } },
  sun:       { pig:'saffron',     name:'Safran',         by:{ pseudo:'Camille', date:'9 mai'  } },
  hills:     { pig:'viridian',    name:'Vert véronèse',  by:{ pseudo:'Théo',    date:'11 mai' } },
  fieldGreen:{ pig:'olive',       name:'Olive',          by:null },   // empty
  earth:     { pig:'sienna',      name:'Terre de Sienne',by:null },   // <- today's target
  soil:      { pig:'vermillion',  name:'Vermillon',      by:null },   // empty
};

function zoneOf(col, row) {
  if (row < 9) {
    const dx = col - 9.3, dy = (row - 3.4) * 1.15, d = Math.sqrt(dx*dx + dy*dy);
    if (d < 2.1) return 'sun';
    if (d < 3.3) return 'halo';
    if (row < 3) return 'skyDeep';
    return 'sky';
  }
  if (row < 11) return 'hills';
  if (row < 13) return 'fieldGreen';
  if (row < 15) return 'earth';
  return 'soil';
}

// build the cell grid once
function buildArtwork() {
  const cells = [];
  for (let row = 0; row < ROWS; row++) {
    for (let col = 0; col < COLS; col++) {
      const z = zoneOf(col, row);
      cells.push({ i: row * COLS + col, col, row, zone: z, pig: ZONES[z].pig });
    }
  }
  return { cols: COLS, rows: ROWS, cells, zones: ZONES };
}
const ARTWORK = buildArtwork();

// Render a filled cell's background — pigment with photographic jitter
function fillStyle(hex, i) {
  const j = (hash(i) - 0.5) * 0.22;          // lightness jitter
  const base = shade(hex, j);
  const hi = shade(hex, j + 0.16);
  const lo = shade(hex, j - 0.14);
  return `linear-gradient(${135 + Math.round(hash(i+9)*90)}deg, ${hi}, ${base} 55%, ${lo})`;
}

// Mosaic component
// props: filledZones (Set of zone keys), todayZone (key|null), revealAll (bool),
//        gap, radius, onTapCell(zoneKey), pulse (bool for today)
function Mosaic({ filledZones, todayZone = null, revealAll = false, gap = 3, radius = 4,
                 onTapCell = null, pulse = true, revealZone = null, stagger = false, style = {} }) {
  const A = ARTWORK;
  let revealIdx = 0;
  const needsReveal = stagger || !!revealZone;
  const [played, setPlayed] = React.useState(!needsReveal);
  React.useEffect(() => {
    if (!needsReveal) return;
    setPlayed(false);
    const t = setTimeout(() => setPlayed(true), 60);
    return () => clearTimeout(t);
  }, [needsReveal, revealZone, stagger]);
  return (
    <div style={{
      display:'grid',
      gridTemplateColumns:`repeat(${A.cols}, 1fr)`,
      gap, width:'100%', aspectRatio:`${A.cols} / ${A.rows}`, ...style,
    }}>
      {A.cells.map(c => {
        const isFilled = revealAll || filledZones.has(c.zone);
        const isToday = !isFilled && c.zone === todayZone;
        const hex = PIG[c.pig];
        let bg, boxShadow, animProps = {};
        if (isFilled) {
          bg = fillStyle(hex, c.i);
          boxShadow = 'inset 0 0 0 0.5px rgba(0,0,0,0.10)';
          let d = null;
          if (stagger) d = c.i * 0.014;
          else if (revealZone && c.zone === revealZone) d = revealIdx++ * 0.045;
          if (d !== null) animProps = {
            opacity: played ? 1 : 0,
            transform: played ? 'scale(1)' : 'scale(0.55)',
            transitionProperty: 'opacity, transform',
            transitionDuration: '0.5s',
            transitionTimingFunction: 'cubic-bezier(0.22,1,0.36,1)',
            transitionDelay: `${d}s`,
          };
        } else if (isToday) {
          bg = `${hex}33`;
          boxShadow = `inset 0 0 0 1.5px ${hex}`;
          if (pulse) animProps = {
            animationName:'mdaPulse', animationDuration:'1.8s',
            animationTimingFunction:'cubic-bezier(0.65,0,0.35,1)',
            animationIterationCount:'infinite',
          };
        } else {
          bg = 'var(--mosaic-empty)';
          boxShadow = 'inset 0 0 0 1px var(--line)';
        }
        return (
          <div key={c.i}
            onClick={onTapCell ? () => onTapCell(c.zone, isFilled) : undefined}
            style={{
              borderRadius: radius, background: bg, boxShadow, ...animProps,
              cursor: onTapCell ? 'pointer' : 'default',
            }} />
        );
      })}
    </div>
  );
}

Object.assign(window, { PIG, ARTWORK, ZONES: ARTWORK.zones, shade, fillStyle, Mosaic });
