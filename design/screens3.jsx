// screens3.jsx — Artwork (vue complète) + Group feed
function ArtworkScreen({ state, onNav }) {
  const { filledZones } = state;
  const [sel, setSel] = React.useState(null); // {zone, filled}
  const total = ARTWORK.cells.length;
  const filledCount = ARTWORK.cells.filter(c => filledZones.has(c.zone)).length;

  return (
    <Screen tabbar>
      <TopBar overline="Instance ARL8 · mai" title="L'œuvre" />

      <div style={{ margin:'4px 20px 0', padding:14, borderRadius:'var(--r-lg)', background:'var(--surface)',
        border:'1px solid var(--line)', boxShadow:'var(--shadow-md)' }}>
        <Mosaic filledZones={filledZones} gap={2.5} radius={3} pulse={false}
          onTapCell={(zone, filled) => setSel({ zone, filled })} />
      </div>

      <div style={{ padding:'18px 20px 0', display:'flex', flexDirection:'column', gap:14 }}>
        <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
            <Overline>Progression globale</Overline>
            <span style={{ fontFamily:'var(--font-serif)', fontSize:17, fontVariantNumeric:'tabular-nums' }}>
              {filledCount} / {total} blocs</span>
          </div>
          <div style={{ height:8, borderRadius:999, background:'var(--cream-200)', overflow:'hidden' }}>
            <div style={{ height:'100%', width:`${Math.round(filledCount/total*100)}%`,
              background:'var(--accent)', borderRadius:999 }} />
          </div>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:10, color:'var(--fg2)' }}>
          <Icon name="lock" size={16} stroke="var(--fg3)" />
          <span style={{ fontFamily:'var(--font-serif)', fontStyle:'italic', fontSize:15 }}>
            Le titre de l'œuvre se révèle le 31 mai.</span>
        </div>
        <span style={{ fontFamily:'var(--font-sans)', fontSize:13, color:'var(--fg3)' }}>
          Touche un bloc rempli pour voir qui l'a peint.</span>
      </div>

      {sel && (
        <Sheet onClose={() => setSel(null)}>
          {sel.filled ? <FilledDetail zone={sel.zone} /> : <EmptyDetail zone={sel.zone} />}
        </Sheet>
      )}
    </Screen>
  );
}

function FilledDetail({ zone }) {
  const z = ZONES[zone];
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:16 }}>
      <div style={{ display:'flex', gap:14, alignItems:'center' }}>
        <div style={{ width:72, height:72, borderRadius:14, flexShrink:0,
          background: fillStyle(PIG[z.pig], 3), boxShadow:'inset 0 0 0 1px rgba(0,0,0,0.08)' }} />
        <div style={{ display:'flex', flexDirection:'column', gap:3 }}>
          <Overline>Zone · {z.name}</Overline>
          <span style={{ fontFamily:'var(--font-serif)', fontSize:22, color:'var(--fg1)' }}>
            Peinte par {z.by.pseudo}</span>
          <span style={{ fontFamily:'var(--font-sans)', fontSize:13, color:'var(--fg2)' }}>
            le {z.by.date} · photo réelle</span>
        </div>
      </div>
      <div style={{ display:'flex', alignItems:'center', gap:10, padding:'12px 14px', borderRadius:'var(--r-md)',
        background:'var(--surface-sunk)' }}>
        <Avatar pig={z.pig} initial={z.by.pseudo[0]} size={36} />
        <span style={{ fontFamily:'var(--font-sans)', fontSize:14, color:'var(--fg2)' }}>
          {z.by.pseudo} a photographié du {z.name.toLowerCase()} dans le monde réel.</span>
      </div>
    </div>
  );
}

function EmptyDetail({ zone }) {
  const z = ZONES[zone];
  return (
    <div style={{ display:'flex', flexDirection:'column', gap:14, alignItems:'flex-start' }}>
      <div style={{ display:'flex', gap:14, alignItems:'center' }}>
        <div style={{ width:72, height:72, borderRadius:14, flexShrink:0, background:'var(--cream-200)',
          boxShadow:'inset 0 0 0 1.5px var(--line)' }} />
        <div style={{ display:'flex', flexDirection:'column', gap:4 }}>
          <Overline>Zone · {z.name}</Overline>
          <span style={{ fontFamily:'var(--font-serif)', fontSize:22, color:'var(--fg1)' }}>Pas encore remplie</span>
          <span style={{ display:'inline-flex', alignItems:'center', gap:8, fontFamily:'var(--font-sans)',
            fontSize:13, color:'var(--fg2)' }}>
            <span style={{ width:12, height:12, borderRadius:4, background:PIG[z.pig] }} />
            attend une photo {z.name.toLowerCase()}</span>
        </div>
      </div>
    </div>
  );
}

const TODAY_FEED = [
  { pseudo:'Camille', pig:'sienna', name:'Terre de Sienne', time:'08:42', you:true },
  { pseudo:'Théo',    pig:'sienna', name:'Terre de Sienne', time:'09:15' },
  { pseudo:'Inès',    pig:'sienna', name:'Terre de Sienne', time:'12:30' },
  { pseudo:'Naomi',   pig:'sienna', name:'Terre de Sienne', time:'—', waiting:true },
  { pseudo:'Lucas',   pig:'sienna', name:'Terre de Sienne', time:'—', waiting:true },
];

function GroupScreen({ onNav }) {
  return (
    <Screen tabbar>
      <TopBar overline="Aujourd'hui · 9 mai" title="Le groupe" />
      <div style={{ padding:'4px 20px 0', display:'flex', flexDirection:'column', gap:10 }}>
        {TODAY_FEED.map((f, i) => (
          <div key={i} style={{ display:'flex', alignItems:'center', gap:13, padding:'12px 14px',
            borderRadius:'var(--r-md)', background:'var(--surface)', border:'1px solid var(--line)',
            opacity: f.waiting ? 0.62 : 1 }}>
            <Avatar pig={f.pig} initial={f.pseudo[0]} size={42} />
            <div style={{ flex:1, display:'flex', flexDirection:'column', gap:2 }}>
              <span style={{ fontFamily:'var(--font-sans)', fontWeight:600, fontSize:15, color:'var(--fg1)' }}>
                {f.pseudo}{f.you && <span style={{ color:'var(--fg3)', fontWeight:500 }}> · toi</span>}</span>
              <span style={{ fontFamily:'var(--font-sans)', fontSize:13, color:'var(--fg2)' }}>
                {f.waiting ? 'pas encore photographié' : `a rempli ${f.name}`}</span>
            </div>
            {f.waiting
              ? <Icon name="clock" size={20} stroke="var(--fg3)" />
              : <div style={{ width:46, height:46, borderRadius:11, background: fillStyle(PIG[f.pig], i),
                  boxShadow:'inset 0 0 0 1px rgba(0,0,0,0.08)' }} />}
          </div>
        ))}
      </div>
      <div style={{ padding:'16px 20px 0' }}>
        <span style={{ fontFamily:'var(--font-serif)', fontStyle:'italic', fontSize:14, color:'var(--fg2)' }}>
          3 personnes sur 5 ont contribué aujourd'hui.</span>
      </div>
    </Screen>
  );
}

Object.assign(window, { ArtworkScreen, GroupScreen });
