// screens4.jsx — Profile + Reveal + Settings

function Switch({ on, onChange }) {
  return (
    <button onClick={() => onChange(!on)} style={{ width:50, height:30, borderRadius:999, border:'none',
      cursor:'pointer', padding:2, background: on ? 'var(--ok)' : 'var(--cream-300)',
      transition:'background var(--dur) var(--ease-out)', display:'flex',
      justifyContent: on ? 'flex-end' : 'flex-start' }}>
      <span style={{ width:26, height:26, borderRadius:'50%', background:'#fff',
        boxShadow:'0 1px 3px rgba(0,0,0,0.25)' }} />
    </button>
  );
}

// ───────────── Profile ─────────────
const MY_TILES = ['sienna','cobalt','viridian','ochre','saffron','sienna','olive','ultramarine','rose'];
const PAST = [
  { month:'Avril', zones:['skyDeep','sky','halo','sun','hills','fieldGreen','earth','soil'] },
  { month:'Mars',  zones:['skyDeep','sky','sun','hills','earth','soil'] },
  { month:'Février', zones:['sky','sun','hills','fieldGreen','earth'] },
];

function ProfileScreen({ state }) {
  return (
    <Screen tabbar>
      <div style={{ padding:'4px 20px 0', display:'flex', alignItems:'center', gap:14 }}>
        <Avatar pig="sienna" initial={(state.pseudo||'T')[0]} size={64} />
        <div style={{ display:'flex', flexDirection:'column', gap:3 }}>
          <span style={{ fontFamily:'var(--font-serif)', fontSize:26, color:'var(--fg1)' }}>{state.pseudo||'Toi'}</span>
          <Overline>Instance {state.instance} · 9 contributions</Overline>
        </div>
      </div>

      <div style={{ padding:'24px 20px 0' }}>
        <Overline>Mes photos de mai</Overline>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3, 1fr)', gap:6, marginTop:12 }}>
          {MY_TILES.map((p, i) => (
            <div key={i} style={{ aspectRatio:'1', borderRadius:8, position:'relative',
              background: fillStyle(PIG[p], i*3), boxShadow:'inset 0 0 0 1px rgba(0,0,0,0.06)' }}>
              <span style={{ position:'absolute', bottom:5, left:7, color:'rgba(255,255,255,0.9)',
                fontFamily:'var(--font-serif)', fontSize:12, textShadow:'0 1px 2px rgba(0,0,0,0.4)' }}>
                {i+1} mai</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding:'26px 20px 0' }}>
        <Overline>Œuvres passées</Overline>
        <div style={{ display:'flex', gap:14, marginTop:12, overflowX:'auto', paddingBottom:4 }}>
          {PAST.map((p, i) => (
            <div key={i} style={{ flex:'0 0 auto', width:96, display:'flex', flexDirection:'column', gap:7 }}>
              <div style={{ borderRadius:10, overflow:'hidden', border:'1px solid var(--line)',
                boxShadow:'var(--shadow-sm)' }}>
                <Mosaic filledZones={new Set(p.zones)} gap={1} radius={1.5} pulse={false} />
              </div>
              <span style={{ fontFamily:'var(--font-sans)', fontSize:12, fontWeight:600, color:'var(--fg2)',
                textAlign:'center' }}>{p.month}</span>
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
}

// ───────────── Reveal (fin de mois) ─────────────
function RevealScreen({ onNav }) {
  const [showLabel, setShowLabel] = React.useState(false);
  React.useEffect(() => { const t = setTimeout(() => setShowLabel(true), 1500); return () => clearTimeout(t); }, []);
  return (
    <div style={{ height:'100%', background:'var(--paper)', overflow:'auto', paddingTop:56,
      display:'flex', flexDirection:'column' }}>
      <div style={{ textAlign:'center', padding:'0 28px' }}>
        <Overline>Fin du mois · L'œuvre est complète</Overline>
      </div>
      <div style={{ margin:'18px 22px 0', borderRadius:'var(--r-md)', overflow:'hidden',
        border:'1px solid var(--line)', boxShadow:'var(--shadow-lg)' }}>
        <Mosaic filledZones={new Set()} revealAll stagger gap={2} radius={2.5} pulse={false} />
      </div>

      <div style={{ flex:1 }} />

      <div style={{ padding:'24px 28px 40px', textAlign:'center',
        opacity: showLabel ? 1 : 0, transform: showLabel ? 'translateY(0)' : 'translateY(12px)',
        transition:'opacity .7s var(--ease-out), transform .7s var(--ease-out)' }}>
        <h1 style={{ fontFamily:'var(--font-serif)', fontStyle:'italic', fontWeight:500, fontSize:30,
          margin:'0 0 6px', color:'var(--fg1)', lineHeight:1.1 }}>Le Semeur au soleil couchant</h1>
        <p style={{ fontFamily:'var(--font-serif)', fontSize:16, color:'var(--fg2)', margin:'0 0 16px' }}>
          Vincent van Gogh — Arles, 1888</p>
        <p style={{ fontFamily:'var(--font-sans)', fontSize:14, lineHeight:1.6, color:'var(--fg2)',
          margin:'0 auto 22px', maxWidth:300, textWrap:'pretty' }}>
          Peinte près d'Arles, l'œuvre oppose un immense soleil d'or à la silhouette d'un semeur —
          un hommage de Van Gogh à Millet, et à l'éternel recommencement.</p>
        <Btn icon="share" onClick={() => onNav('daily')}>Partager l'œuvre</Btn>
      </div>
    </div>
  );
}

// ───────────── Settings ─────────────
function SettingsScreen({ state, setTheme, onNav }) {
  const [time, setTime] = React.useState({ h:8, m:30 });
  const [anon, setAnon] = React.useState(true);
  const [adv, setAdv] = React.useState(false);
  const pad = n => String(n).padStart(2,'0');
  const dark = state.theme === 'dark';

  const Row = ({ children, last }) => (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'14px 16px',
      borderBottom: last ? 'none' : '1px solid var(--line)' }}>{children}</div>
  );
  const Card = ({ children }) => (
    <div style={{ margin:'10px 20px 0', background:'var(--surface)', border:'1px solid var(--line)',
      borderRadius:'var(--r-md)', overflow:'hidden' }}>{children}</div>
  );
  const Step = ({ onMinus, onPlus, label }) => (
    <div style={{ display:'flex', alignItems:'center', gap:14 }}>
      <button className="mda-tap" onClick={onMinus} style={stepBtn}>–</button>
      <span style={{ fontFamily:'var(--font-serif)', fontSize:22, minWidth:30, textAlign:'center',
        fontVariantNumeric:'tabular-nums' }}>{label}</span>
      <button className="mda-tap" onClick={onPlus} style={stepBtn}>+</button>
    </div>
  );

  return (
    <Screen tabbar>
      <TopBar overline="Réglages" title="Paramètres" />

      <Overline style={{ margin:'8px 24px 0' }}>Notification quotidienne</Overline>
      <Card>
        <Row last>
          <Icon name="clock" size={20} stroke="var(--fg2)" />
          <span style={{ flex:1, fontFamily:'var(--font-sans)', fontSize:16, color:'var(--fg1)' }}>Heure du rappel</span>
          <Step label={pad(time.h)} onMinus={() => setTime(t=>({...t,h:(t.h+23)%24}))} onPlus={() => setTime(t=>({...t,h:(t.h+1)%24}))} />
          <span style={{ fontFamily:'var(--font-serif)', fontSize:22 }}>:</span>
          <Step label={pad(time.m)} onMinus={() => setTime(t=>({...t,m:(t.m+45)%60}))} onPlus={() => setTime(t=>({...t,m:(t.m+15)%60}))} />
        </Row>
      </Card>

      <Overline style={{ margin:'22px 24px 0' }}>Apparence</Overline>
      <Card>
        <Row last>
          <Icon name="sun" size={20} stroke="var(--fg2)" />
          <span style={{ flex:1, fontFamily:'var(--font-sans)', fontSize:16, color:'var(--fg1)' }}>Mode sombre</span>
          <Switch on={dark} onChange={v => setTheme(v?'dark':'light')} />
        </Row>
      </Card>

      <Overline style={{ margin:'22px 24px 0' }}>Compte</Overline>
      <Card>
        <Row>
          <Icon name="user" size={20} stroke="var(--fg2)" />
          <span style={{ flex:1, fontFamily:'var(--font-sans)', fontSize:16, color:'var(--fg1)' }}>Rester anonyme</span>
          <Switch on={anon} onChange={setAnon} />
        </Row>
        <Row last>
          <Icon name="trash" size={20} stroke="var(--error)" />
          <span style={{ flex:1, fontFamily:'var(--font-sans)', fontSize:16, color:'var(--error)' }}>Supprimer mes données</span>
          <Icon name="right" size={18} stroke="var(--fg3)" />
        </Row>
      </Card>

      {/* Advanced — hidden by default */}
      <div style={{ margin:'22px 20px 0' }}>
        <button className="mda-tap" onClick={() => setAdv(a=>!a)} style={{ background:'none', border:'none',
          cursor:'pointer', display:'flex', alignItems:'center', gap:8, color:'var(--fg2)', padding:'4px 4px' }}>
          <Icon name={adv?'up':'down'} size={18} />
          <span style={{ fontFamily:'var(--font-sans)', fontSize:14, fontWeight:600 }}>Avancé</span>
        </button>
        {adv && (
          <div style={{ marginTop:10, background:'var(--surface)', border:'1px solid var(--line)',
            borderRadius:'var(--r-md)', padding:'14px 16px', display:'flex', flexDirection:'column', gap:8 }}>
            <Overline>Serveur personnalisé</Overline>
            <input placeholder="https://" style={{ height:46, borderRadius:'var(--r-sm)',
              border:'1.5px solid var(--line)', background:'var(--paper)', padding:'0 14px', fontSize:15,
              fontFamily:'var(--font-sans)', color:'var(--fg1)', outline:'none' }} />
            <span style={{ fontFamily:'var(--font-sans)', fontSize:12, color:'var(--fg3)' }}>
              Héberge ta propre instance. Laisse vide pour le serveur public.</span>
          </div>
        )}
      </div>
    </Screen>
  );
}
const stepBtn = { width:32, height:32, borderRadius:'50%', border:'1px solid var(--line)',
  background:'var(--surface)', cursor:'pointer', fontSize:20, color:'var(--fg1)', lineHeight:1,
  display:'flex', alignItems:'center', justifyContent:'center', fontFamily:'var(--font-sans)' };

Object.assign(window, { ProfileScreen, RevealScreen, SettingsScreen, Switch });
