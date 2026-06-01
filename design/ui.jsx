// ui.jsx — shared primitives for the Mémoire de l'art kit
// Exports: Icon, Btn, Overline, PigBadge, Chip, ProgressBar, Ring, TabBar, TopBar, Avatar, Sheet

const ICONS = {
  sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
  grid:'<rect width="7" height="7" x="3" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="14" rx="1.5"/><rect width="7" height="7" x="3" y="14" rx="1.5"/>',
  users:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  user:'<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  camera:'<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/>',
  image:'<rect width="18" height="18" x="3" y="3" rx="2.5"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.1-3.1a2 2 0 0 0-2.8 0L6 21"/>',
  right:'<path d="m9 18 6-6-6-6"/>',
  left:'<path d="m15 18-6-6 6-6"/>',
  back:'<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
  x:'<path d="M18 6 6 18M6 6l12 12"/>',
  check:'<path d="M20 6 9 17l-5-5"/>',
  checkCircle:'<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
  share:'<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m8.6 13.5 6.8 4M15.4 6.5l-6.8 4"/>',
  bell:'<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  clock:'<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  settings:'<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
  down:'<path d="m6 9 6 6 6-6"/>',
  up:'<path d="m18 15-6-6-6 6"/>',
  info:'<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
  trash:'<path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
  sparkles:'<path d="M9.94 15.5A2 2 0 0 0 8.5 14.06l-6.14-1.58a.5.5 0 0 1 0-.96L8.5 9.94A2 2 0 0 0 9.94 8.5l1.58-6.14a.5.5 0 0 1 .96 0L14.06 8.5A2 2 0 0 0 15.5 9.94l6.14 1.58a.5.5 0 0 1 0 .96L15.5 14.06a2 2 0 0 0-1.44 1.44l-1.58 6.14a.5.5 0 0 1-.96 0z"/>',
  refresh:'<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/>',
  lock:'<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
};

function Icon({ name, size = 24, stroke = 'currentColor', sw = 1.75, style = {} }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke}
      strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"
      style={{ display:'block', flexShrink:0, ...style }}
      dangerouslySetInnerHTML={{ __html: ICONS[name] || '' }} />
  );
}

function Btn({ children, onClick, variant = 'primary', icon, full, style = {}, disabled }) {
  const base = {
    fontFamily:'var(--font-sans)', fontWeight:600, fontSize:16, cursor:'pointer',
    border:'none', borderRadius:'var(--r-pill)', padding:'15px 24px',
    display:'inline-flex', alignItems:'center', justifyContent:'center', gap:9,
    width: full ? '100%' : undefined, opacity: disabled ? 0.45 : 1,
  };
  const variants = {
    primary:{ background:'var(--accent)', color:'var(--on-accent)', boxShadow:'var(--shadow-sm)' },
    secondary:{ background:'var(--surface)', color:'var(--fg1)', border:'1px solid var(--line-strong)' },
    ghost:{ background:'transparent', color:'var(--accent)', boxShadow:'none' },
    dark:{ background:'rgba(255,255,255,0.16)', color:'#fff', backdropFilter:'blur(10px)' },
  };
  return (
    <button className="mda-btn" onClick={disabled ? undefined : onClick}
      style={{ ...base, ...variants[variant], ...style }}>
      {icon && <Icon name={icon} size={19} />}{children}
    </button>
  );
}

function Overline({ children, style = {} }) {
  return <span style={{ fontFamily:'var(--font-sans)', fontWeight:600, fontSize:12,
    letterSpacing:'0.14em', textTransform:'uppercase', color:'var(--fg2)', ...style }}>{children}</span>;
}

// the hero "couleur du jour" badge
function PigBadge({ pig, name, size = 56 }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:14, background:'var(--surface)',
      border:'1px solid var(--line)', borderRadius:'var(--r-lg)', padding:'12px 18px 12px 12px',
      boxShadow:'var(--shadow-md)' }}>
      <div style={{ width:size, height:size, borderRadius:14, background:PIG[pig],
        boxShadow:'inset 0 0 0 1px rgba(0,0,0,0.08)' }} />
      <div style={{ display:'flex', flexDirection:'column', gap:3 }}>
        <Overline>Couleur du jour</Overline>
        <span style={{ fontFamily:'var(--font-serif)', fontSize:24, color:'var(--fg1)', lineHeight:1.1 }}>{name}</span>
      </div>
    </div>
  );
}

function Chip({ children, color, active, onClick }) {
  return (
    <span className="mda-tap" onClick={onClick} style={{ display:'inline-flex', alignItems:'center', gap:8,
      padding:'8px 14px', borderRadius:'var(--r-pill)', fontSize:13, fontWeight:600,
      fontFamily:'var(--font-sans)', cursor: onClick?'pointer':'default',
      background: active ? 'var(--fg1)' : 'var(--cream-200)', color: active ? 'var(--paper)' : 'var(--fg1)' }}>
      {color && <span style={{ width:13, height:13, borderRadius:4, background:color }} />}
      {children}
    </span>
  );
}

function ProgressBar({ value, total, label }) {
  const pct = Math.round((value/total)*100);
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
        <Overline>{label || 'Progression du mois'}</Overline>
        <span style={{ fontFamily:'var(--font-serif)', fontSize:17, color:'var(--fg1)',
          fontVariantNumeric:'tabular-nums' }}>jour {value} / {total}</span>
      </div>
      <div style={{ height:8, borderRadius:999, background:'var(--cream-200)', overflow:'hidden' }}>
        <div style={{ height:'100%', width:pct+'%', background:'var(--accent)', borderRadius:999,
          transition:'width var(--dur-slow) var(--ease-out)' }} />
      </div>
    </div>
  );
}

function Avatar({ pig = 'cobalt', initial = 'C', size = 44 }) {
  return (
    <div style={{ width:size, height:size, borderRadius:'50%', flexShrink:0,
      background:`linear-gradient(140deg, ${shade(PIG[pig],0.18)}, ${PIG[pig]} 60%, ${shade(PIG[pig],-0.18)})`,
      display:'flex', alignItems:'center', justifyContent:'center',
      color:'#fff', fontFamily:'var(--font-serif)', fontSize:size*0.42,
      boxShadow:'inset 0 1px 1px rgba(255,255,255,0.25)' }}>{initial}</div>
  );
}

// bottom tab bar (sits above home indicator)
function TabBar({ active, onNav }) {
  const tabs = [
    { id:'daily', icon:'sun', label:"Aujourd'hui" },
    { id:'artwork', icon:'grid', label:"L'œuvre" },
    { id:'group', icon:'users', label:'Groupe' },
    { id:'profile', icon:'user', label:'Profil' },
  ];
  return (
    <div style={{ position:'absolute', left:0, right:0, bottom:0, zIndex:40,
      paddingBottom:30, paddingTop:10,
      background:'linear-gradient(to top, var(--paper) 62%, transparent)',
      display:'flex', justifyContent:'space-around', alignItems:'center' }}>
      {tabs.map(t => {
        const on = active === t.id;
        return (
          <button key={t.id} className="mda-tap" onClick={() => onNav(t.id)}
            style={{ background:'none', border:'none', cursor:'pointer',
              display:'flex', flexDirection:'column', alignItems:'center', gap:4,
              color: on ? 'var(--accent)' : 'var(--fg3)', fontFamily:'var(--font-sans)',
              fontSize:11, fontWeight:600 }}>
            <Icon name={t.icon} size={23} sw={on?2:1.75} />{t.label}
          </button>
        );
      })}
    </div>
  );
}

// gallery-style screen header
function TopBar({ overline, title, left, right, dark }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'8px 20px 14px' }}>
      {left}
      <div style={{ flex:1, display:'flex', flexDirection:'column', gap:2 }}>
        {overline && <Overline style={dark?{color:'rgba(255,255,255,0.7)'}:{}}>{overline}</Overline>}
        {title && <span style={{ fontFamily:'var(--font-serif)', fontSize:26, lineHeight:1.05,
          color: dark?'#fff':'var(--fg1)' }}>{title}</span>}
      </div>
      {right}
    </div>
  );
}

function Sheet({ children, onClose, height = 'auto' }) {
  return (
    <div onClick={onClose} style={{ position:'absolute', inset:0, zIndex:70,
      background:'rgba(28,24,19,0.42)', backdropFilter:'blur(2px)',
      display:'flex', alignItems:'flex-end', animation:'mdaFade .24s ease' }}>
      <div onClick={e=>e.stopPropagation()} style={{ width:'100%', height,
        background:'var(--surface)', borderRadius:'24px 24px 0 0', padding:'12px 20px 40px',
        boxShadow:'var(--shadow-lg)', animation:'mdaSheet .32s var(--ease-out)' }}>
        <div style={{ width:40, height:5, borderRadius:999, background:'var(--cream-300)',
          margin:'0 auto 16px' }} />
        {children}
      </div>
    </div>
  );
}

// scrollable safe-area screen wrapper
function Screen({ children, tabbar, dark, bg, pad = true, label }) {
  return (
    <div data-screen-label={label} style={{ height:'100%', overflow:'auto', WebkitOverflowScrolling:'touch',
      background: bg || (dark ? 'var(--paper)' : 'var(--paper)'),
      paddingTop:56, paddingBottom: tabbar ? 112 : 40,
      display:'flex', flexDirection:'column' }}>
      <div style={{ padding: pad ? '0 0' : 0, display:'flex', flexDirection:'column', flex:1 }}>
        {children}
      </div>
    </div>
  );
}

// gentle notification banner
function Banner({ icon = 'bell', children, onClick }) {
  return (
    <div className="mda-tap" onClick={onClick} style={{ display:'flex', alignItems:'center', gap:12,
      margin:'0 20px', padding:'13px 16px', borderRadius:'var(--r-md)',
      background:'var(--clay-100)', color:'var(--clay-600)', cursor: onClick?'pointer':'default' }}>
      <Icon name={icon} size={20} sw={1.9} />
      <span style={{ fontFamily:'var(--font-sans)', fontSize:14, fontWeight:600, flex:1 }}>{children}</span>
      <Icon name="right" size={18} />
    </div>
  );
}

Object.assign(window, { Icon, Btn, Overline, PigBadge, Chip, ProgressBar, Avatar, TabBar, TopBar, Sheet, Screen, Banner });
