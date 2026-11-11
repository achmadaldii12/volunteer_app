import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

// ============================================================
// WARNA HALAMAN (biru utama, merah sebagai aksen)
// ============================================================
const _blue = Color(0xFF3B5BDB);
const _blueLight = Color(0xFF5C7CFA);
const _gold = Color(0xFFFFC83D);

Color _bg(BuildContext c) => isDark(c) ? const Color(0xFF111522) : const Color(0xFFF2F5FF);
Color _card(BuildContext c) => isDark(c) ? const Color(0xFF1B2133) : Colors.white;
Color _line(BuildContext c) => isDark(c) ? const Color(0xFF2A3350) : const Color(0xFFE2E8FF);
Color _blueSoft(BuildContext c) => isDark(c) ? const Color(0xFF232C4A) : const Color(0xFFEAEFFF);
Color _textOf(BuildContext c) => Theme.of(c).colorScheme.onSurface;

/// Pengganti withOpacity (yang sudah deprecated di Flutter terbaru) agar Problems bersih.
extension _ColorOp on Color {
  Color op(double o) => withAlpha((o * 255).round().clamp(0, 255).toInt());
}

// ============================================================
// POPUP PENGHARGAAN (poin / level naik / badge baru)
// Dipanggil otomatis saat halaman ini dibuka, dan dari halaman lain
// (mis. setelah kehadiran diverifikasi) lewat showPendingCelebrations().
// ============================================================
Future<void> showPendingCelebrations(BuildContext context) async {
  final s = context.read<AppState>();
  final items = s.takeCelebrations();
  for (final c in items) {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CelebrationDialog(c),
    );
  }
}

class _CelebrationDialog extends StatelessWidget {
  final Celebration c;
  const _CelebrationDialog(this.c);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.color.op(.7), width: 2),
            boxShadow: [BoxShadow(color: c.color.op(.35), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.auto_awesome, size: 16, color: c.color.op(.7)),
              const SizedBox(width: 6),
              const Icon(Icons.auto_awesome, size: 22, color: _gold),
              const SizedBox(width: 6),
              Icon(Icons.auto_awesome, size: 16, color: c.color.op(.7)),
            ]),
            const SizedBox(height: 10),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [c.color, Color.lerp(c.color, Colors.white, .35)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: c.color.op(.5), blurRadius: 22, spreadRadius: 2)],
              ),
              child: Icon(c.icon, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 16),
            if (c.kind == CelebrationKind.points)
              _CountUp(
                value: c.points,
                prefix: '+',
                suffix: ' Poin',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _textOf(context)),
              )
            else
              Text(c.title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textOf(context))),
            const SizedBox(height: 8),
            Text(c.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: muted(context))),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Keren!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET KECIL
// ============================================================
class _CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String prefix, suffix;
  const _CountUp({required this.value, required this.style, this.prefix = '', this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${fmtNum(v)}$suffix', style: style),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ring;
  const _Avatar(this.name, {this.size = 40, this.ring = false});

  static const _palette = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEC4899),
    Color(0xFF8B5CF6), Color(0xFF14B8A6), Color(0xFFEF4444), Color(0xFF6366F1),
  ];

  String get _initials {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.first.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    var h = 0;
    for (final r in name.runes) {
      h = (h * 31 + r) & 0x7fffffff;
    }
    final color = _palette[h % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: ring ? Border.all(color: Colors.white, width: 2.5) : null,
      ),
      child: Text(_initials,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * .38)),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final LevelDef lv;
  final bool small;
  const _LevelChip(this.lv, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: lv.color.op(isDark(context) ? .25 : .14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(lv.icon, size: small ? 10 : 12, color: lv.color),
        const SizedBox(width: 3),
        Text(lv.name,
            style: TextStyle(fontSize: small ? 9.5 : 11, fontWeight: FontWeight.w600, color: lv.color)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;
  final Color? color;
  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.action,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? _card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line(context)),
        boxShadow: [BoxShadow(color: _blue.op(isDark(context) ? 0 : .06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _textOf(context))),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(action!,
                    style: const TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

// ============================================================
// HALAMAN UTAMA: ACHIEVEMENT & RANKING
// ============================================================
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  RankPeriod _period = RankPeriod.weekly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showPendingCelebrations(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        title: const Text('Achievement & Ranking'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.emoji_events, color: Color(0xFFF5B301)),
          ),
        ],
      ),
      body: u == null
          ? const Center(child: Text('Silakan login untuk melihat achievement'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context, s, u),
                    _badgesSection(context, s, u),
                    _leaderboardSection(context, s),
                    _myPositionCard(context, s),
                    _vomSection(context, s),
                    _historySection(context, s),
                    _infoSection(context, s),
                  ],
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(BuildContext context, AppState s, AppUser u) {
    final pts = s.totalPoints;
    final lp = levelProgress(pts);
    final lvIndex = levelIndexOf(pts);
    final myAll = s.myRankEntry(RankPeriod.allTime);
    final pct = (lp.progress * 100).round();

    Widget stat(IconData icon, Color color, Widget value, String label) => Expanded(
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            value,
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        );

    const valueStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_blue, _blueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _blue.op(.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            _Avatar(u.name, size: 62, ring: true),
            if (myAll?.rank == 1)
              const Positioned(
                top: -15,
                left: 0,
                right: 0,
                child: Center(child: Icon(Icons.workspace_premium, color: _gold, size: 24)),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(lp.level.icon, size: 13, color: const Color(0xFF7A4B00)),
                    const SizedBox(width: 4),
                    Text(lp.level.name,
                        style: const TextStyle(
                            color: Color(0xFF7A4B00), fontWeight: FontWeight.w700, fontSize: 11.5)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('Level ${lvIndex + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Progress menuju level berikutnya',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(lp.next == null ? 'MAX' : '$pct%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: lp.progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(_gold),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            lp.next == null
                ? 'Selamat! Kamu sudah mencapai level tertinggi 🎉'
                : '${fmtNum(lp.remaining)} poin lagi menuju ${lp.next!.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white24),
        const SizedBox(height: 14),
        Row(children: [
          stat(Icons.star_rounded, _gold, _CountUp(value: pts, style: valueStyle), 'Total Poin'),
          stat(Icons.event_available, Colors.white, _CountUp(value: s.totalEvents, style: valueStyle), 'Event Diikuti'),
          stat(Icons.local_fire_department, const Color(0xFFFF8A3D),
              _CountUp(value: s.streakOf(u.id), style: valueStyle), 'Streak (minggu)'),
        ]),
      ]),
    );
  }

  // ----------------------------------------------------------------- badge
  Widget _badgesSection(BuildContext context, AppState s, AppUser u) {
    final earned = kAchBadges.where((b) => s.achEarned(u.id, b)).length;
    return _Section(
      icon: Icons.emoji_events,
      iconColor: const Color(0xFFF5B301),
      title: 'Koleksi Achievement ($earned/${kAchBadges.length})',
      action: 'Lihat Semua',
      onAction: () => _showAllBadges(context, s, u),
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kAchBadges.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final b = kAchBadges[i];
            return _BadgeTile(b, s.achEarned(u.id, b), onTap: () => _showBadgeDetail(context, s, u, b));
          },
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, AppState s, AppUser u, AchBadge b) {
    final earned = s.achEarned(u.id, b);
    final value = s.achValue(u.id, b.metric);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _BadgeIcon(b, earned, size: 84),
            const SizedBox(height: 14),
            Text(b.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _textOf(context))),
            const SizedBox(height: 6),
            Text(b.desc, textAlign: TextAlign.center, style: TextStyle(color: muted(context), fontSize: 13)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.achProgress(u.id, b),
                minHeight: 8,
                backgroundColor: _line(context),
                valueColor: AlwaysStoppedAnimation(earned ? AppColors.success : _blue),
              ),
            ),
            const SizedBox(height: 6),
            Text('${fmtNum(value > b.target ? b.target : value)} / ${fmtNum(b.target)}',
                style: TextStyle(fontSize: 12, color: muted(context))),
            const SizedBox(height: 4),
            Text(earned ? '✅ Badge sudah terbuka' : '🔒 Badge masih terkunci',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: earned ? AppColors.success : muted(context))),
            const SizedBox(height: 14),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ]),
        ),
      ),
    );
  }

  void _showAllBadges(BuildContext context, AppState s, AppUser u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .92,
        minChildSize: .4,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _line(ctx), borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 14),
            Text('Semua Achievement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textOf(ctx))),
            const SizedBox(height: 14),
            for (final b in kAchBadges)
              Builder(builder: (_) {
                final earned = s.achEarned(u.id, b);
                final v = s.achValue(u.id, b.metric);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: earned ? b.color.op(isDark(ctx) ? .15 : .08) : _bg(ctx),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: earned ? b.color.op(.5) : _line(ctx)),
                  ),
                  child: Row(children: [
                    _BadgeIcon(b, earned, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.name,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textOf(ctx))),
                        const SizedBox(height: 2),
                        Text(b.desc, style: TextStyle(fontSize: 11.5, color: muted(ctx))),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: s.achProgress(u.id, b),
                            minHeight: 6,
                            backgroundColor: _line(ctx),
                            valueColor: AlwaysStoppedAnimation(earned ? AppColors.success : _blue),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Column(children: [
                      Icon(earned ? Icons.check_circle : Icons.lock_outline,
                          color: earned ? AppColors.success : Colors.grey, size: 22),
                      const SizedBox(height: 2),
                      Text('${fmtNum(v > b.target ? b.target : v)}/${fmtNum(b.target)}',
                          style: TextStyle(fontSize: 10.5, color: muted(ctx))),
                    ]),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- leaderboard
  Widget _periodPills(BuildContext context) {
    return Row(children: [
      for (final p in RankPeriod.values)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _period = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _period == p ? _blue : _blueSoft(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(p.label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _period == p ? Colors.white : _blue)),
            ),
          ),
        ),
    ]);
  }

  Widget _leaderboardSection(BuildContext context, AppState s) {
    final entries = s.leaderboard(_period);
    final top = entries.take(10).toList();
    final hasData = entries.isNotEmpty && entries.first.points > 0;

    return _Section(
      icon: Icons.leaderboard,
      iconColor: _blue,
      title: 'Leaderboard',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: _periodPills(context)),
        const SizedBox(height: 14),
        if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text('Belum ada poin pada periode ini.',
                  style: TextStyle(color: muted(context), fontSize: 13)),
            ),
          )
        else
          for (final e in top) _RankRow(e),
        if (entries.length > 10)
          Center(
            child: TextButton(
              onPressed: () => _showAllRanks(context, entries),
              child: Text('Lihat semua (${entries.length} relawan)'),
            ),
          ),
      ]),
    );
  }

  void _showAllRanks(BuildContext context, List<RankEntry> entries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        maxChildSize: .95,
        minChildSize: .4,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _line(ctx), borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 14),
            Text('Ranking ${_period.label}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textOf(ctx))),
            const SizedBox(height: 14),
            for (final e in entries) _RankRow(e),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- posisi kamu
  Widget _myPositionCard(BuildContext context, AppState s) {
    final entries = s.leaderboard(_period);
    RankEntry? me;
    for (final e in entries) {
      if (e.isMe) me = e;
    }
    if (me == null) return const SizedBox.shrink();

    String msg;
    if (me.points == 0 && _period != RankPeriod.allTime) {
      msg = 'Belum ada poin ${_period.label.toLowerCase()}. Ikuti kegiatan untuk naik peringkat!';
    } else if (me.rank == 1) {
      msg = 'Kamu berada di peringkat pertama! 🎉';
    } else {
      final above = entries[me.rank - 2];
      final need = above.points - me.points + 1;
      msg = '${fmtNum(need)} poin lagi untuk naik ke peringkat #${me.rank - 1}';
    }
    if (me.rank > 10) msg = 'Di luar 10 besar • $msg';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blueSoft(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.op(.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 6),
          Text('Posisi Kamu',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textOf(context))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _blue.op(.15), borderRadius: BorderRadius.circular(8)),
            child: Text(_period.label,
                style: const TextStyle(fontSize: 10.5, color: _blue, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _Avatar(me.user.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text('#${me.rank} ${me.user.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textOf(context))),
                ),
                if (me.rank == 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.workspace_premium, color: Color(0xFFF5B301), size: 18),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(msg, style: TextStyle(fontSize: 11.5, color: muted(context), height: 1.3)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _CountUp(
                value: me.points,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _blue)),
            Text('Poin', style: TextStyle(fontSize: 11, color: muted(context))),
          ]),
        ]),
      ]),
    );
  }

  // -------------------------------------------------- volunteer of the month
  Widget _vomSection(BuildContext context, AppState s) {
    final board = s.monthlyBoard();
    final w = board.winner;
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(board.month);

    return _Section(
      icon: Icons.workspace_premium,
      iconColor: const Color(0xFFF5B301),
      title: 'Volunteer of The Month',
      action: 'Lihat Detail',
      onAction: () => _showVomDetail(context, board, monthLabel),
      color: isDark(context) ? const Color(0xFF2E2713) : const Color(0xFFFFF8E1),
      child: w == null
          ? Text('Belum ada aktivitas pada bulan ini.',
              style: TextStyle(color: muted(context), fontSize: 13))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  _Avatar(w.user.name, size: 58, ring: true),
                  const Positioned(
                    top: -13,
                    left: 0,
                    right: 0,
                    child: Center(child: Icon(Icons.workspace_premium, color: Color(0xFFF5B301), size: 22)),
                  ),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.isMe ? '${w.user.name} (Kamu)' : w.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _textOf(context))),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5B301)),
                      const SizedBox(width: 3),
                      Text('${fmtNum(w.points)} Poin',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _textOf(context))),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.event_available, size: 14, color: muted(context)),
                      const SizedBox(width: 4),
                      Text('${w.events} Kegiatan • $monthLabel',
                          style: TextStyle(fontSize: 11.5, color: muted(context))),
                    ]),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _card(context).op(.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  w.isMe
                      ? 'Selamat! Kamu relawan paling aktif bulan ini 🎉'
                      : 'Terima kasih atas kontribusimu untuk masyarakat! 💙',
                  style: TextStyle(fontSize: 12, color: muted(context)),
                ),
              ),
            ]),
    );
  }

  void _showVomDetail(BuildContext context, MonthlyBoard board, String monthLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _line(ctx), borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 14),
            Text('Volunteer of The Month',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textOf(ctx))),
            Text(monthLabel, style: TextStyle(fontSize: 12.5, color: muted(ctx))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _blueSoft(ctx), borderRadius: BorderRadius.circular(14)),
              child: Text(
                'Penilaian: poin yang diperoleh bulan ini (sudah mencakup jumlah event yang '
                'diselesaikan dan kontribusi koordinator / apresiasi) ditambah 20 poin untuk setiap '
                'minggu aktif sebagai nilai konsistensi.',
                style: TextStyle(fontSize: 12, height: 1.45, color: _textOf(ctx)),
              ),
            ),
            const SizedBox(height: 14),
            if (board.stars.isEmpty)
              Text('Belum ada aktivitas.', style: TextStyle(color: muted(ctx)))
            else
              for (var i = 0; i < board.stars.length && i < 5; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFFF5B301).op(.12) : _bg(ctx),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: board.stars[i].isMe ? AppColors.primary.op(.5) : _line(ctx)),
                  ),
                  child: Row(children: [
                    Text('#${i + 1}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textOf(ctx))),
                    const SizedBox(width: 10),
                    _Avatar(board.stars[i].user.name, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(board.stars[i].isMe ? '${board.stars[i].user.name} (Kamu)' : board.stars[i].user.name,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _textOf(ctx))),
                        Text(
                            '${board.stars[i].events} kegiatan • ${board.stars[i].activeWeeks} minggu aktif'
                            '${board.stars[i].contribution > 0 ? ' • +${board.stars[i].contribution} kontribusi' : ''}',
                            style: TextStyle(fontSize: 11, color: muted(ctx))),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${fmtNum(board.stars[i].points)} Poin',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: _blue)),
                      Text('Skor ${board.stars[i].score}', style: TextStyle(fontSize: 10.5, color: muted(ctx))),
                    ]),
                  ]),
                ),
          ]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- riwayat poin
  Widget _historySection(BuildContext context, AppState s) {
    final all = s.myPointHistory;
    final latest = all.take(5).toList();
    return _Section(
      icon: Icons.history,
      iconColor: _blue,
      title: 'Riwayat Perolehan Poin',
      action: 'Lihat Semua',
      onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointHistoryScreen())),
      child: latest.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Belum ada riwayat poin. Ikuti kegiatan untuk mulai mengumpulkan poin!',
                  style: TextStyle(color: muted(context), fontSize: 13)),
            )
          : Column(children: [for (final e in latest) _HistoryTile(e)]),
    );
  }

  // ----------------------------------------------------- level & aturan poin
  Widget _infoSection(BuildContext context, AppState s) {
    final cur = levelIndexOf(s.totalPoints);
    Widget rule(IconData icon, String pts, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: _blue),
            const SizedBox(width: 10),
            SizedBox(
              width: 38,
              child: Text(pts,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.success)),
            ),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.35, color: _textOf(context)))),
          ]),
        );

    return _Section(
      icon: Icons.trending_up,
      iconColor: AppColors.primary,
      title: 'Level & Cara Mendapat Poin',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < kLevels.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: i == cur ? kLevels[i].color.op(.18) : _bg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: i == cur ? kLevels[i].color : _line(context), width: i == cur ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(kLevels[i].icon, size: 14, color: kLevels[i].color),
                const SizedBox(width: 5),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kLevels[i].name,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _textOf(context))),
                  Text(kLevels[i].rangeText, style: TextStyle(fontSize: 9.5, color: muted(context))),
                ]),
              ]),
            ),
        ]),
        const SizedBox(height: 16),
        rule(Icons.event_available, '+$kPointsPerEvent', 'Mengikuti dan menyelesaikan 1 event'),
        rule(Icons.groups, '+$kPointsCoordinator', 'Menjadi koordinator kegiatan'),
        rule(Icons.card_giftcard, '+$kPointsBonus5Events', 'Bonus setiap kelipatan 5 event yang diselesaikan'),
        rule(Icons.thumb_up_alt_outlined, '+$kPointsAppreciation', 'Mendapat apresiasi dari panitia'),
        Text('Poin hanya diberikan setelah kehadiran diverifikasi panitia, bukan saat mendaftar.',
            style: TextStyle(fontSize: 11, color: muted(context), fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

// ============================================================
// BADGE
// ============================================================
class _BadgeIcon extends StatelessWidget {
  final AchBadge b;
  final bool earned;
  final double size;
  const _BadgeIcon(this.b, this.earned, {this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned
            ? LinearGradient(
                colors: [b.color, Color.lerp(b.color, Colors.white, .35)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: earned ? null : (isDark(context) ? const Color(0xFF2A3350) : const Color(0xFFE5E7EB)),
        boxShadow: earned ? [BoxShadow(color: b.color.op(.4), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Icon(
        earned ? b.icon : Icons.lock_outline,
        size: size * .5,
        color: earned ? Colors.white : Colors.grey,
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchBadge b;
  final bool earned;
  final VoidCallback onTap;
  const _BadgeTile(this.b, this.earned, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: earned ? b.color.op(isDark(context) ? .15 : .08) : _bg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? b.color.op(.45) : _line(context)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _BadgeIcon(b, earned),
          const SizedBox(height: 8),
          Text(b.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: earned ? _textOf(context) : muted(context))),
        ]),
      ),
    );
  }
}

// ============================================================
// BARIS LEADERBOARD
// ============================================================
class _RankRow extends StatelessWidget {
  final RankEntry e;
  const _RankRow(this.e);

  Widget _badge(BuildContext context) {
    Color? c;
    if (e.rank == 1) c = const Color(0xFFFFB300);
    if (e.rank == 2) c = const Color(0xFF9AA5B1);
    if (e.rank == 3) c = const Color(0xFFCD7F32);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c ?? (isDark(context) ? const Color(0xFF2A3350) : const Color(0xFFE8ECF8)),
      ),
      child: Text('${e.rank}',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: c != null ? Colors.white : muted(context))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lv = levelOf(e.totalPoints);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: e.isMe ? (isDark(context) ? const Color(0x33DC2626) : const Color(0xFFFFF1F1)) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: e.isMe ? AppColors.primary.op(.45) : Colors.transparent),
      ),
      child: Row(children: [
        _badge(context),
        const SizedBox(width: 10),
        _Avatar(e.user.name, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(e.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _textOf(context))),
              ),
              if (e.isMe)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Kamu',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 3),
            _LevelChip(lv, small: true),
          ]),
        ),
        Text('${fmtNum(e.points)} Poin',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: _blue)),
      ]),
    );
  }
}

// ============================================================
// RIWAYAT POIN
// ============================================================
IconData _typeIcon(String t) {
  switch (t) {
    case PointType.coordinator:
      return Icons.groups;
    case PointType.bonus:
      return Icons.card_giftcard;
    case PointType.appreciation:
      return Icons.thumb_up_alt;
    case PointType.opening:
      return Icons.history;
    default:
      return Icons.event_available;
  }
}

Color _typeColor(String t) {
  switch (t) {
    case PointType.coordinator:
      return const Color(0xFF8B5CF6);
    case PointType.bonus:
      return const Color(0xFFF59E0B);
    case PointType.appreciation:
      return const Color(0xFFEC4899);
    case PointType.opening:
      return const Color(0xFF64748B);
    default:
      return _blue;
  }
}

class _HistoryTile extends StatelessWidget {
  final PointEntry e;
  const _HistoryTile(this.e);

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(e.type);
    final statusColor = e.verified ? AppColors.success : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line(context)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color.op(.14), borderRadius: BorderRadius.circular(11)),
          child: Icon(_typeIcon(e.type), color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _textOf(context))),
            const SizedBox(height: 2),
            Text('${fmtDate(e.date)} • ${e.note}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: muted(context), height: 1.3)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+${fmtNum(e.points)} Poin',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: statusColor)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: statusColor.op(.14), borderRadius: BorderRadius.circular(6)),
            child: Text(e.verified ? 'Terverifikasi' : 'Menunggu',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
      ]),
    );
  }
}

class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  int _filter = 0; // 0 semua, 1 terverifikasi, 2 menunggu

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.myPointHistory;
    final verified = all.where((e) => e.verified).fold<int>(0, (a, e) => a + e.points);
    final pending = all.where((e) => !e.verified).fold<int>(0, (a, e) => a + e.points);
    final list = all.where((e) {
      if (_filter == 1) return e.verified;
      if (_filter == 2) return !e.verified;
      return true;
    }).toList();

    Widget chip(String label, int i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: _filter == i,
            selectedColor: _blue,
            showCheckmark: false,
            labelStyle: TextStyle(color: _filter == i ? Colors.white : null, fontSize: 12),
            onSelected: (_) => setState(() => _filter = i),
          ),
        );

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(backgroundColor: _bg(context), title: const Text('Riwayat Poin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, _blueLight]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Poin Terverifikasi',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                      const SizedBox(height: 4),
                      Text(fmtNum(verified),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Menunggu verifikasi', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('+${fmtNum(pending)}',
                        style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [chip('Semua', 0), chip('Terverifikasi', 1), chip('Menunggu', 2)]),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Tidak ada riwayat pada filter ini.', style: TextStyle(color: muted(context))),
                  ),
                )
              else
                for (final e in list) _HistoryTile(e),
            ],
          ),
        ],
      ),
    );
  }
}