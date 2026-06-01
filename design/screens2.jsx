// screens2.jsx — Camera + Confirm
function CameraScreen({ state, onNav, onCapture }) {
  const { todayZone } = state;
  const target = ZONES[todayZone];
  const scenes = {
    mur:       { label:'Mur',       color:'#B0512E', verdict:'Parfait !',            tone:'ok',   hint:'La teinte correspond à la terre de Sienne.' },
    ciel:      { label:'Ciel',      color:'#6F93C0', verdict:'Trop froid',          tone:'warn', hint:'Cherche un rouge plus chaud.' },
    feuillage: { label:'Feuillage', color:'#6D7E3F', verdict:'Manque de rouge',     tone:'warn', hint:'Trop de vert dans le cadre.' },
  };
  const [aim, setAim] = React.useState('mur');
  const s = scenes[aim];
  const toneColor = s.tone === 'ok' ? 'var(--ok)' : 'var(--warn)';

  return (
    <div data-screen-label="camera" style={{ height:'100%', background:'#0E0C0A', position:'relative',
      display:'flex', flexDirection:'column' }}>
      {/* top HUD */}
      <div style={{ position:'absolute', top:56, left:0, right:0, zIndex:5, padding:'0 18px',
        display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <button className="mda-tap" onClick={() => onNav('daily')} style={{ background:'rgba(255,255,255,0.14)',
          border:'none', borderRadius:'50%', width:40, height:40, display:'flex', alignItems:'center',
          justifyContent:'center', cursor:'pointer', backdropFilter:'blur(8px)' }}>
          <Icon name="x" size={20} stroke="#fff" />
        </button>
        <div style={{ display:'flex', alignItems:'center', gap:9, background:'rgba(255,255,255,0.14)',
          padding:'8px 14px', borderRadius:'var(--r-pill)', backdropFilter:'blur(8px)' }}>
          <span style={{ width:14, height:14, borderRadius:4, background:PIG[target.pig] }} />
          <span style={{ color:'#fff', fontFamily:'var(--font-sans)', fontSize:13, fontWeight:600 }}>
            Cible · {target.name}</span>
        </div>
        <div style={{ width:40 }} />
      </div>

      {/* square viewfinder */}
      <div style={{ flex:1, display:'flex', alignItems:'center', justifyContent:'center', padding:'0 22px' }}>
        <div style={{ width:'100%', aspectRatio:'1', borderRadius:18, overflow:'hidden', position:'relative',
          boxShadow:'0 0 0 2px rgba(255,255,255,0.9), 0 20px 50px rgba(0,0,0,0.5)' }}>
          {/* faux scene */}
          <div style={{ position:'absolute', inset:0,
            background:`radial-gradient(120% 120% at 35% 25%, ${shade(s.color,0.22)}, ${s.color} 45%, ${shade(s.color,-0.25)})` }} />
          <div style={{ position:'absolute', inset:0, background:'linear-gradient(115deg, rgba(255,255,255,0.10), transparent 40%)' }} />
          {/* match ring */}
          <div style={{ position:'absolute', top:14, left:14, display:'flex', alignItems:'center', gap:9 }}>
            <div style={{ width:30, height:30, borderRadius:'50%', background:s.color,
              boxShadow:`0 0 0 3px ${toneColor}, 0 0 0 5px rgba(255,255,255,0.25)` }} />
          </div>
          {/* verdict bandeau */}
          <div style={{ position:'absolute', left:14, right:14, bottom:14, padding:'12px 16px',
            borderRadius:14, background:'rgba(14,12,10,0.55)', backdropFilter:'blur(10px)',
            display:'flex', flexDirection:'column', gap:2 }}>
            <span style={{ color: s.tone==='ok' ? '#7BE0A0' : '#F0C679',
              fontFamily:'var(--font-serif)', fontSize:22 }}>{s.verdict}</span>
            <span style={{ color:'rgba(255,255,255,0.75)', fontFamily:'var(--font-sans)', fontSize:13 }}>{s.hint}</span>
          </div>
        </div>
      </div>

      {/* aim simulator (stands in for live camera) */}
      <div style={{ display:'flex', justifyContent:'center', gap:8, padding:'4px 22px 0' }}>
        {Object.keys(scenes).map(k => (
          <button key={k} className="mda-tap" onClick={() => setAim(k)} style={{ cursor:'pointer',
            border:'none', borderRadius:'var(--r-pill)', padding:'8px 16px', fontSize:13, fontWeight:600,
            fontFamily:'var(--font-sans)',
            background: aim===k ? '#fff' : 'rgba(255,255,255,0.14)',
            color: aim===k ? '#1C1813' : 'rgba(255,255,255,0.8)' }}>{scenes[k].label}</button>
        ))}
      </div>

      {/* controls */}
      <div style={{ padding:'20px 30px 46px', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <button className="mda-tap" onClick={() => onCapture(aim==='mur'?'ok':'warn')} style={{ background:'none', border:'none',
          cursor:'pointer', display:'flex', flexDirection:'column', alignItems:'center', gap:4,
          color:'rgba(255,255,255,0.85)' }}>
          <div style={{ width:48, height:48, borderRadius:13, background:'rgba(255,255,255,0.12)',
            display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Icon name="image" size={22} stroke="#fff" />
          </div>
          <span style={{ fontFamily:'var(--font-sans)', fontSize:11 }}>Galerie</span>
        </button>

        <button className="mda-btn" onClick={() => onCapture(aim==='mur'?'ok':'warn')} style={{ width:74, height:74,
          borderRadius:'50%', background:'#fff', border:'5px solid rgba(255,255,255,0.35)', cursor:'pointer',
          boxShadow:'0 8px 24px rgba(0,0,0,0.4)' }} aria-label="Capturer" />

        <div style={{ width:48 }} />
      </div>
    </div>
  );
}

function ConfirmScreen({ state, onNav, onDone, lastQuality }) {
  const { filledZones, todayZone } = state;
  const merged = new Set([...filledZones, todayZone]);
  const z = ZONES[todayZone];
  const good = lastQuality === 'ok';
  return (
    <Screen>
      <TopBar overline="Ta contribution" title="Bien joué" />

      <div style={{ margin:'4px 20px 0', padding:14, borderRadius:'var(--r-lg)', background:'var(--surface)',
        border:'1px solid var(--line)', boxShadow:'var(--shadow-md)' }}>
        <Mosaic filledZones={merged} revealZone={todayZone} gap={2.5} radius={3} pulse={false} />
      </div>

      <div style={{ padding:'20px 20px 0', display:'flex', flexDirection:'column', gap:16 }}>
        <div style={{ display:'flex', alignItems:'center', gap:12, padding:'14px 16px',
          borderRadius:'var(--r-md)', background:'var(--surface)', border:'1px solid var(--line)' }}>
          <span style={{ width:30, height:30, borderRadius:'50%', background: good?'var(--ok)':'var(--warn)',
            display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Icon name={good?'check':'info'} size={18} stroke="#fff" sw={2.4} />
          </span>
          <div style={{ display:'flex', flexDirection:'column' }}>
            <span style={{ fontFamily:'var(--font-sans)', fontWeight:600, fontSize:15, color:'var(--fg1)' }}>
              {good ? 'Belle correspondance' : 'Correspondance correcte'}</span>
            <span style={{ fontFamily:'var(--font-sans)', fontSize:13, color:'var(--fg2)' }}>
              Ta photo rejoint la zone {z.name.toLowerCase()}.</span>
          </div>
        </div>

        <button className="mda-tap" onClick={() => onNav('group')} style={{ background:'none', border:'none',
          cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'space-between',
          padding:'4px 2px', color:'var(--fg1)' }}>
          <span style={{ display:'flex', alignItems:'center', gap:10, fontFamily:'var(--font-sans)',
            fontWeight:600, fontSize:15 }}>
            <Icon name="users" size={20} stroke="var(--accent)" /> Voir les contributions du jour</span>
          <Icon name="right" size={18} stroke="var(--fg3)" />
        </button>

        <Btn full onClick={onDone}>Terminer</Btn>
      </div>
    </Screen>
  );
}

Object.assign(window, { CameraScreen, ConfirmScreen });
