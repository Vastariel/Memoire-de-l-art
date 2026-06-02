import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../services/session_manager.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../theme/typography.dart';
import '../../widgets/instance_badge.dart';
import '../../widgets/overline.dart';
import '../../widgets/top_bar.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onDeleteData;
  final List<SavedInstance> instances;
  final int currentIdx;
  final void Function(int) onSwitchInstance;
  final void Function(int) onLeaveInstance;
  final VoidCallback onAddInstance;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
    required this.onDeleteData,
    required this.instances,
    required this.currentIdx,
    required this.onSwitchInstance,
    required this.onLeaveInstance,
    required this.onAddInstance,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _TestState { idle, loading, ok, error }

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _notifTime  = const TimeOfDay(hour: 8, minute: 30);
  bool _notifEnabled    = true;
  bool _showAdvanced    = false;
  final _serverCtrl     = TextEditingController();
  bool _loading         = true;
  _TestState _testState = _TestState.idle;
  String _testMessage   = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p     = await NotificationService.instance.loadPrefs();
    final prefs = await SharedPreferences.getInstance();
    final url   = prefs.getString('custom_server_url') ?? '';
    if (!mounted) return;
    setState(() {
      _notifTime    = TimeOfDay(hour: p.hour, minute: p.minute);
      _notifEnabled = p.enabled;
      _serverCtrl.text = url;
      _loading      = false;
    });
  }

  Future<void> _saveServerUrl(String url) async {
    final trimmed = url.trim();
    setState(() { _testState = _TestState.loading; _testMessage = ''; });

    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove('custom_server_url');
      ApiClient.reset();
      if (!mounted) return;
      setState(() { _testState = _TestState.idle; _testMessage = 'Serveur par défaut restauré.'; });
      return;
    }

    await prefs.setString('custom_server_url', trimmed);
    ApiClient.reset();

    final ok = await ApiClient.testConnection(trimmed);
    if (!mounted) return;
    setState(() {
      _testState   = ok ? _TestState.ok : _TestState.error;
      _testMessage = ok ? 'Serveur joignable ✓' : 'Serveur inaccessible ou incompatible ✗';
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _notifTime,
      helpText: 'Heure du rappel quotidien',
    );
    if (t == null || !mounted) return;
    setState(() => _notifTime = t);
    if (_notifEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: t.hour, minute: t.minute);
    }
  }

  Future<void> _confirmLeave(BuildContext ctx, int idx, String name) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Quitter l\'instance ?'),
        content: Text('Tu vas quitter "${name.isNotEmpty ? name : 'cette instance'}". Tes contributions restent visibles.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Quitter', style: TextStyle(color: MdaColors.error))),
        ],
      ),
    );
    if (confirm == true) widget.onLeaveInstance(idx);
  }

  Future<void> _toggleNotif(bool v) async {
    setState(() => _notifEnabled = v);
    if (v) {
      final granted = await NotificationService.instance.requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _notifEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission refusée — active les notifications dans les réglages.')),
        );
        return;
      }
      await NotificationService.instance.scheduleDailyReminder(
        hour: _notifTime.hour, minute: _notifTime.minute);
    } else {
      await NotificationService.instance.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final paper   = isDark ? MdaDark.paper   : MdaLight.paper;
    final surface = isDark ? MdaDark.surface : MdaLight.surface;
    final fg1     = isDark ? MdaDark.fg1     : MdaLight.fg1;
    final fg2     = isDark ? MdaDark.fg2     : MdaLight.fg2;
    final fg3     = isDark ? MdaDark.fg3     : MdaLight.fg3;
    final line    = isDark ? MdaDark.line    : MdaLight.line;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            const MdaTopBar(overline: 'Réglages', title: 'Paramètres'),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 112),
                  children: [

                    // ── Notification ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                      child: MdaOverline('Notification quotidienne'),
                    ),
                    _Card(surface: surface, line: line, children: [
                      _Row(
                        icon: Icons.notifications_outlined,
                        fg1: fg1, fg2: fg2,
                        label: 'Rappel activé',
                        trailing: _Switch(
                          on: _notifEnabled,
                          onChange: _toggleNotif,
                        ),
                      ),
                      _Row(
                        icon: Icons.schedule_outlined,
                        fg1: _notifEnabled ? fg1 : fg3,
                        fg2: fg2,
                        label: 'Heure du rappel',
                        last: true,
                        onTap: _notifEnabled ? _pickTime : null,
                        trailing: Text(
                          _notifTime.toHHMM(),
                          style: TextStyle(
                            fontFamily: MdaFonts.serif,
                            fontSize: 22,
                            color: _notifEnabled ? fg1 : fg3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ]),

                    // ── Appearance ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                      child: MdaOverline('Apparence'),
                    ),
                    _Card(surface: surface, line: line, children: [
                      _Row(
                        icon: Icons.wb_sunny_outlined,
                        fg1: fg1, fg2: fg2,
                        label: 'Mode sombre',
                        last: true,
                        trailing: _Switch(
                          on: widget.isDark,
                          onChange: widget.onThemeChanged,
                        ),
                      ),
                    ]),

                    // ── Instances ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                      child: MdaOverline('Instances'),
                    ),
                    _Card(
                      surface: surface, line: line,
                      children: [
                        ...widget.instances.asMap().entries.map((entry) {
                          final idx  = entry.key;
                          final inst = entry.value;
                          final isCurrent = idx == widget.currentIdx;
                          final badges = instanceBadges(
                            isSolo:    inst.isSolo,
                            isOnline:  !inst.isSolo && inst.token != null,
                            isCreator: inst.isCreator,
                          );
                          return _Row(
                            icon: isCurrent
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            fg1: isCurrent ? (isDark ? MdaDark.accent : MdaLight.accent) : fg1,
                            fg2: fg2,
                            label: inst.name.isNotEmpty ? inst.name : inst.code,
                            sublabel: badges.isEmpty ? null : badges,
                            onTap: isCurrent ? null : () => widget.onSwitchInstance(idx),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(inst.code,
                                    style: TextStyle(fontFamily: MdaFonts.serif,
                                        fontSize: 15, color: fg3)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _confirmLeave(context, idx, inst.name),
                                  child: Icon(Icons.logout_rounded, size: 18,
                                      color: MdaColors.error),
                                ),
                              ],
                            ),
                          );
                        }),
                        _Row(
                          icon: Icons.add_rounded,
                          fg1: isDark ? MdaDark.accent : MdaLight.accent,
                          fg2: fg2,
                          label: 'Rejoindre une autre instance',
                          last: true,
                          onTap: widget.onAddInstance,
                          trailing: Icon(Icons.chevron_right_rounded, size: 18, color: fg3),
                        ),
                      ],
                    ),

                    // ── Account ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                      child: MdaOverline('Compte'),
                    ),
                    _Card(surface: surface, line: line, children: [
                      _Row(
                        icon: Icons.delete_outline_rounded,
                        fg1: MdaColors.error,
                        fg2: fg2,
                        label: 'Supprimer mes données',
                        last: true,
                        onTap: widget.onDeleteData,
                        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: fg3),
                      ),
                    ]),

                    // ── Advanced ──────────────────────────────────────
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _showAdvanced
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18, color: fg2,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Avancé',
                                    style: MdaType.bodySm(color: fg2)
                                        .copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          if (_showAdvanced)
                            AnimatedContainer(
                              duration: MdaDuration.std,
                              curve: MdaCurve.easeOut,
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: MdaRadius.bMd,
                                border: Border.all(color: line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const MdaOverline('Serveur personnalisé'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _serverCtrl,
                                          style: MdaType.body(color: fg1).copyWith(fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: 'Laisser vide pour le serveur par défaut',
                                            hintStyle: MdaType.body(color: fg3).copyWith(fontSize: 13),
                                          ),
                                          keyboardType: TextInputType.url,
                                          onSubmitted: _saveServerUrl,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _testState == _TestState.loading
                                            ? null
                                            : () => _saveServerUrl(_serverCtrl.text),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? MdaDark.accent : MdaLight.accent,
                                            borderRadius: MdaRadius.bSm,
                                          ),
                                          child: _testState == _TestState.loading
                                              ? const SizedBox(width: 18, height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                              : Text('OK',
                                                  style: TextStyle(color: Colors.white,
                                                    fontFamily: MdaFonts.sans, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_testMessage.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          _testState == _TestState.ok
                                              ? Icons.check_circle_outline_rounded
                                              : _testState == _TestState.error
                                                  ? Icons.error_outline_rounded
                                                  : Icons.info_outline_rounded,
                                          size: 14,
                                          color: _testState == _TestState.ok
                                              ? MdaColors.ok
                                              : _testState == _TestState.error
                                                  ? MdaColors.error
                                                  : fg3,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(_testMessage,
                                          style: MdaType.caption(
                                            color: _testState == _TestState.ok
                                                ? MdaColors.ok
                                                : _testState == _TestState.error
                                                    ? MdaColors.error
                                                    : fg3)),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Laisse vide pour utiliser mda.vastariel.fr.',
                                      style: MdaType.caption(color: fg3),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────

class _Card extends StatelessWidget {
  final Color surface, line;
  final List<Widget> children;
  const _Card({required this.surface, required this.line, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: MdaRadius.bMd,
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color fg1, fg2;
  final String label;
  final List<Widget>? sublabel;
  final Widget? trailing;
  final bool last;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.fg1,
    required this.fg2,
    required this.label,
    this.sublabel,
    this.trailing,
    this.last = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(
                  color: isDark ? MdaDark.line : MdaLight.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg1),
            const SizedBox(width: 12),
            Expanded(
              child: sublabel != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: MdaType.body(color: fg1)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: sublabel!,
                        ),
                      ],
                    )
                  : Text(label, style: MdaType.body(color: fg1)),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChange;
  const _Switch({required this.on, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!on),
      child: AnimatedContainer(
        duration: MdaDuration.std,
        curve: MdaCurve.easeOut,
        width: 50, height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: MdaRadius.bPill,
          color: on ? MdaColors.ok : MdaColors.cream300,
        ),
        child: AnimatedAlign(
          duration: MdaDuration.std,
          curve: MdaCurve.easeOut,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(
                color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

