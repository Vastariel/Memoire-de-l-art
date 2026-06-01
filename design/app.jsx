// app.jsx — navigation shell + state
function App() {
  const [screen, setScreen] = React.useState('onboarding');
  const [state, setState] = React.useState({
    filledZones: new Set(['skyDeep','sky','halo','sun','hills']),
    todayZone: 'earth',
    todayDone: false,
    instance: 'ARL8',
    pseudo: 'Camille',
    theme: 'light',
  });
  const [quality, setQuality] = React.useState('ok');

  const nav = (s) => setScreen(s);
  const setTheme = (t) => setState(st => ({ ...st, theme:t }));

  const onJoin = (pseudo) => { setState(st => ({ ...st, pseudo })); nav('daily'); };
  const onCapture = (q) => { setQuality(q); nav('confirm'); };
  const onDone = () => {
    setState(st => ({ ...st, todayDone:true, filledZones: new Set([...st.filledZones, st.todayZone]) }));
    nav('daily');
  };

  const dark = state.theme === 'dark' || screen === 'camera';
  const hasTab = ['daily','artwork','group','profile','settings'].includes(screen);

  let view;
  switch (screen) {
    case 'onboarding': view = <OnboardingScreen onJoin={onJoin} />; break;
    case 'daily':      view = <DailyScreen state={state} onNav={nav} onCapture={onCapture} />; break;
    case 'camera':     view = <CameraScreen state={state} onNav={nav} onCapture={onCapture} />; break;
    case 'confirm':    view = <ConfirmScreen state={state} onNav={nav} onDone={onDone} lastQuality={quality} />; break;
    case 'artwork':    view = <ArtworkScreen state={state} onNav={nav} />; break;
    case 'group':      view = <GroupScreen onNav={nav} />; break;
    case 'profile':    view = <ProfileScreen state={state} />; break;
    case 'reveal':     view = <RevealScreen onNav={nav} />; break;
    case 'settings':   view = <SettingsScreen state={state} setTheme={setTheme} onNav={nav} />; break;
    default:           view = <DailyScreen state={state} onNav={nav} onCapture={onCapture} />;
  }

  return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:22 }}>
      <IOSDevice dark={dark}>
        <div data-theme={state.theme} style={{ height:'100%', position:'relative' }}>
          {view}
          {hasTab && <TabBar active={screen==='settings'?null:screen} onNav={nav} />}
        </div>
      </IOSDevice>
      <ScreenRail screen={screen} onNav={nav} />
    </div>
  );
}

// external screen picker (presentation aid, not part of the app chrome)
function ScreenRail({ screen, onNav }) {
  const items = [
    ['onboarding','Onboarding'], ['daily','Daily'], ['camera','Caméra'], ['confirm','Confirmation'],
    ['artwork','Œuvre'], ['group','Groupe'], ['profile','Profil'], ['reveal','Reveal'], ['settings','Réglages'],
  ];
  return (
    <div style={{ display:'flex', flexWrap:'wrap', gap:8, justifyContent:'center', maxWidth:440 }}>
      {items.map(([id, label]) => {
        const on = screen === id;
        return (
          <button key={id} onClick={() => onNav(id)} style={{ cursor:'pointer',
            fontFamily:'var(--font-sans)', fontSize:13, fontWeight:600, padding:'8px 14px',
            borderRadius:999, border:'1px solid', transition:'all .15s',
            borderColor: on ? 'transparent' : 'rgba(28,24,19,0.16)',
            background: on ? 'var(--clay-500)' : 'rgba(255,255,255,0.7)',
            color: on ? '#FBF8F1' : 'var(--ink-700)' }}>{label}</button>
        );
      })}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
