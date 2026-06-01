// screens1.jsx — Onboarding + Daily
const { useState, useRef, useEffect } = React;

function OnboardingScreen({ onJoin }) {
  const [code, setCode] = useState('');
  const [pseudo, setPseudo] = useState('');
  const inputRef = useRef(null);
  const cells = 6;
  const clean = code.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, cells);

  return (
    <Screen>
      <div style={{ padding:'4px 28px 0', display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
        <img src="assets/app-icon.svg" width="76" height="76"
          style={{ borderRadius:'22.5%', boxShadow:'var(--shadow-md)' }} alt="" />
        <h1 style={{ fontFamily:'var(--font-serif)', fontSize:30, fontWeight:500, margin:'10px 0 0',
          color:'var(--fg1)', textAlign:'center', letterSpacing:'-0.01em' }}>Mémoire de l'art</h1>
        <p style={{ fontFamily:'var(--font-serif)', fontStyle:'italic', fontSize:16, color:'var(--fg2)',
          margin:0, textAlign:'center' }}>Une couleur par jour, une œuvre par mois.</p>
      </div>

      {/* blurred teaser */}
      <div style={{ margin:'26px 28px 0', position:'relative', borderRadius:'var(--r-lg)', overflow:'hidden',
        border:'1px solid var(--line)', boxShadow:'var(--shadow-md)' }}>
        <div style={{ filter:'blur(11px) saturate(1.1)', transform:'scale(1.12)' }}>
          <Mosaic filledZones={new Set(['skyDeep','sky','halo','sun','hills'])} gap={2} radius={3} pulse={false} />
        </div>
        <div style={{ position:'absolute', inset:0, display:'flex', flexDirection:'column',
          alignItems:'center', justifyContent:'center', gap:7,
          background:'linear-gradient(to bottom, rgba(251,248,241,0.30), rgba(251,248,241,0.62))' }}>
          <Icon name="lock" size={22} stroke="var(--fg1)" />
          <span style={{ fontFamily:'var(--font-serif)', fontSize:18, color:'var(--fg1)' }}>L'œuvre de mai</span>
          <Overline>Rejoins une instance pour la révéler</Overline>
        </div>
      </div>

      {/* code input */}
      <div style={{ padding:'30px 28px 0', display:'flex', flexDirection:'column', gap:10 }}>
        <Overline>Code d'instance</Overline>
        <div style={{ position:'relative' }} onClick={() => inputRef.current && inputRef.current.focus()}>
          <div style={{ display:'flex', gap:9 }}>
            {Array.from({ length: cells }).map((_, i) => {
              const ch = clean[i];
              const focused = i === clean.length;
              return (
                <div key={i} style={{ flex:1, aspectRatio:'0.82', borderRadius:'var(--r-sm)',
                  border:`1.5px solid ${ch ? 'var(--accent)' : focused ? 'var(--line-strong)' : 'var(--line)'}`,
                  background:'var(--surface)', display:'flex', alignItems:'center', justifyContent:'center',
                  fontFamily:'var(--font-serif)', fontSize:26, color:'var(--fg1)' }}>
                  {ch || <span style={{ color:'var(--fg3)' }}>·</span>}
                </div>
              );
            })}
          </div>
          <input ref={inputRef} value={clean} onChange={e => setCode(e.target.value)}
            inputMode="text" autoCapitalize="characters" spellCheck="false"
            style={{ position:'absolute', inset:0, opacity:0, cursor:'pointer', fontSize:16 }} />
        </div>
        <span style={{ fontFamily:'var(--font-sans)', fontSize:13, color:'var(--fg3)' }}>
          Demande le code à la personne qui a créé l'instance.
        </span>
      </div>

      {/* pseudo */}
      <div style={{ padding:'18px 28px 0', display:'flex', flexDirection:'column', gap:10 }}>
        <Overline>Pseudonyme · facultatif</Overline>
        <input value={pseudo} onChange={e => setPseudo(e.target.value)} placeholder="Camille"
          style={{ height:50, borderRadius:'var(--r-md)', border:'1.5px solid var(--line)',
            background:'var(--surface)', padding:'0 16px', fontSize:16, fontFamily:'var(--font-sans)',
            color:'var(--fg1)', outline:'none' }} />
      </div>

      <div style={{ padding:'28px 28px 0', marginTop:'auto' }}>
        <Btn full disabled={clean.length < 4} onClick={() => onJoin(pseudo || 'Toi')}>Rejoindre l'instance</Btn>
      </div>
    </Screen>
  );
}

function DailyScreen({ state, onNav, onCapture }) {
  const { filledZones, todayZone, todayDone, instance } = state;
  const z = ZONES[todayZone];
  return (
    <Screen tabbar label="daily">
      <TopBar overline={`Mai · Instance ${instance}`} title="Aujourd'hui"
        right={<button className="mda-tap" onClick={() => onNav('settings')} style={{ background:'none',
          border:'none', cursor:'pointer', padding:6, color:'var(--fg2)' }}><Icon name="settings" size={23} /></button>} />

      {/* artwork vignette */}
      <div style={{ margin:'4px 20px 0', padding:14, borderRadius:'var(--r-lg)', background:'var(--surface)',
        border:'1px solid var(--line)', boxShadow:'var(--shadow-md)' }}>
        <Mosaic filledZones={filledZones} todayZone={todayDone ? null : todayZone} gap={2.5} radius={3} />
        <div style={{ marginTop:14 }}>
          <ProgressBar value={12} total={30} />
        </div>
      </div>

      {!todayDone && (
        <div style={{ marginTop:18 }}>
          <Banner icon="camera" onClick={() => onNav('camera')}>Ta couleur du jour t'attend — {z.name}</Banner>
        </div>
      )}
      {todayDone && (
        <div style={{ marginTop:18 }}>
          <Banner icon="checkCircle">C'est fait pour aujourd'hui. À demain !</Banner>
        </div>
      )}

      <div style={{ padding:'22px 20px 0', display:'flex', flexDirection:'column', gap:18 }}>
        <PigBadge pig={z.pig} name={z.name} />
        <Btn full icon="camera" onClick={() => onNav('camera')}>
          {todayDone ? 'Reprendre ma photo' : 'Photographier ma couleur'}
        </Btn>
      </div>
    </Screen>
  );
}

Object.assign(window, { OnboardingScreen, DailyScreen });
