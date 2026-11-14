import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/profile_store.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'profile_pages.dart';

String monthYear(BuildContext c, DateTime d) {
  final en = c.read<ProfileStore>().isEnglish;
  return DateFormat('MMMM yyyy', en ? 'en_US' : 'id_ID').format(d);
}

// ============================================================
// BADGE
// ============================================================
class ProfileBadgeIcon extends StatelessWidget {
  final AchBadge b;
  final bool earned;
  final double size;
  const ProfileBadgeIcon(this.b, this.earned, {super.key, this.size = 56});

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
        color: earned ? null : (isDark(context) ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB)),
        boxShadow: earned
            ? [BoxShadow(color: b.color.withAlpha(100), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Icon(earned ? b.icon : Icons.lock_outline, size: size * .5, color: earned ? Colors.white : Colors.grey),
    );
  }
}

/// Detail badge: syarat, progres, dan tanggal diperoleh.
void showBadgeDetail(BuildContext context, AchBadge b) {
  final s = context.read<AppState>();
  final u = s.user;
  if (u == null) return;
  final status = s.badgeStatus(u.id, b);
  final value = s.achValue(u.id, b.metric);
  final shown = value > b.target ? b.target : value;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ProfileBadgeIcon(b, status.earned, size: 84),
          const SizedBox(height: 14),
          Text(b.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(tx(ctx, 'Syarat: ${b.desc}', 'Requirement: ${b.desc}'),
              textAlign: TextAlign.center, style: TextStyle(color: muted(ctx), fontSize: 13, height: 1.35)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.achProgress(u.id, b),
              minHeight: 8,
              backgroundColor: AppColors.primary.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(status.earned ? AppColors.success : AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text('${fmtNum(shown)} / ${fmtNum(b.target)}', style: TextStyle(fontSize: 12, color: muted(ctx))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (status.earned ? AppColors.success : Colors.grey).withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              !status.earned
                  ? tx(ctx, '🔒 Badge masih terkunci', '🔒 Badge is still locked')
                  : (status.date != null
                      ? '${tx(ctx, '✅ Diperoleh pada', '✅ Earned on')} ${fmtLongDate(status.date!)}'
                      : tx(ctx, '✅ Diperoleh sebelum pencatatan riwayat', '✅ Earned before history tracking')),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: status.earned ? AppColors.success : muted(ctx)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tx(ctx, 'Tutup', 'Close'))),
        ]),
      ),
    ),
  );
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    final earnedCount = u == null ? 0 : kAchBadges.where((b) => s.achEarned(u.id, b)).length;

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Semua Pencapaian', 'All Achievements'))),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '$earnedCount ${tx(context, 'dari', 'of')} ${kAchBadges.length} ${tx(context, 'badge terbuka', 'badges unlocked')}',
                          style: TextStyle(fontSize: 13, color: muted(context)),
                        ),
                      ),
                    ),
                    for (final b in kAchBadges)
                      Builder(builder: (_) {
                        final st = s.badgeStatus(u.id, b);
                        return PCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () => showBadgeDetail(context, b),
                          child: Row(children: [
                            ProfileBadgeIcon(b, st.earned, size: 54),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(b.desc, style: TextStyle(fontSize: 11.5, color: muted(context))),
                                const SizedBox(height: 4),
                                Text(
                                  !st.earned
                                      ? tx(context, 'Terkunci', 'Locked')
                                      : (st.date != null
                                          ? '${tx(context, 'Diperoleh', 'Earned')} ${fmtDate(st.date!)}'
                                          : tx(context, 'Diperoleh sebelum pencatatan', 'Earned before tracking')),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: st.earned ? AppColors.success : muted(context)),
                                ),
                              ]),
                            ),
                            Icon(st.earned ? Icons.check_circle : Icons.lock_outline,
                                color: st.earned ? AppColors.success : Colors.grey),
                          ]),
                        );
                      }),
                  ]),
                ),
              ),
            ]),
    );
  }
}

// ============================================================
// STATISTIK AKTIVITAS (dengan grafik bulanan)
// ============================================================
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _metric = 'events'; // events | hours | points

  Widget _tile(BuildContext context, IconData icon, Color color, String value, String label) {
    return PCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(fontSize: 11.5, color: muted(context))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final stats = s.monthlyStats(u.id, months: 6);
    int val(MonthStat m) => _metric == 'events' ? m.events : (_metric == 'hours' ? m.hours : m.points);
    var maxV = 1;
    for (final m in stats) {
      if (val(m) > maxV) maxV = val(m);
    }
    final followed = u.pastEvents + s.regs.where((r) => r.userId == u.id && r.status != RegStatus.cancelled).length;

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Statistik Aktivitas', 'Activity Statistics'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _tile(context, Icons.event_available, const Color(0xFFDC2626), fmtNum(followed),
                      tx(context, 'Event diikuti', 'Events joined')),
                  _tile(context, Icons.schedule, const Color(0xFF7C3AED), fmtNum(s.totalHours),
                      tx(context, 'Jam kontribusi', 'Contribution hours')),
                  _tile(context, Icons.task_alt, const Color(0xFF15803D), fmtNum(s.totalEvents),
                      tx(context, 'Kegiatan selesai', 'Completed activities')),
                  _tile(context, Icons.groups, const Color(0xFF2563EB), fmtNum(s.totalImpact),
                      tx(context, 'Penerima manfaat', 'Beneficiaries')),
                ],
              ),
              const SizedBox(height: 12),
              PCard(
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fmtNum(s.totalPoints),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      Text(tx(context, 'Total poin diperoleh', 'Total points earned'),
                          style: TextStyle(fontSize: 11.5, color: muted(context))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PSectionHeader(Icons.bar_chart_rounded,
                      tx(context, 'Perkembangan 6 Bulan Terakhir', 'Last 6 Months Progress')),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    for (final m in const ['events', 'hours', 'points'])
                      ChoiceChip(
                        label: Text(m == 'events'
                            ? tx(context, 'Event', 'Events')
                            : (m == 'hours' ? tx(context, 'Jam', 'Hours') : tx(context, 'Poin', 'Points'))),
                        selected: _metric == m,
                        selectedColor: AppColors.primary,
                        showCheckmark: false,
                        labelStyle: TextStyle(color: _metric == m ? Colors.white : null, fontSize: 12),
                        onSelected: (_) => setState(() => _metric = m),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (final m in stats)
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('${val(m)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 22,
                              height: val(m) == 0 ? 4 : 120 * val(m) / maxV,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(DateFormat('MMM', context.read<ProfileStore>().isEnglish ? 'en_US' : 'id_ID')
                                .format(m.month),
                                style: TextStyle(fontSize: 10.5, color: muted(context))),
                          ]),
                        ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(children: [
                  for (final m in stats.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        Expanded(
                          child: Text(monthYear(context, m.month),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                        Text('${m.events} ${tx(context, 'event', 'events')}  •  ${m.hours} ${tx(context, 'jam', 'h')}  •  ${fmtNum(m.points)} ${tx(context, 'poin', 'pts')}',
                            style: TextStyle(fontSize: 11.5, color: muted(context))),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              Text(
                tx(context, 'Grafik dihitung dari poin yang sudah diverifikasi panitia.',
                    'Charts are calculated from points verified by the organizers.'),
                style: TextStyle(fontSize: 11, color: muted(context)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// RIWAYAT KEGIATAN (pencarian + filter)
// ============================================================
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _q = '';
  int _filter = 0; // 0 semua, 1 terdaftar, 2 selesai, 3 dibatalkan

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final key = _q.trim().toLowerCase();
    final list = s.myRegs.where((r) {
      if (_filter == 1 && r.status != RegStatus.registered) return false;
      if (_filter == 2 && r.status != RegStatus.attended) return false;
      if (_filter == 3 && r.status != RegStatus.cancelled) return false;
      final e = s.eventById(r.eventId);
      if (e == null) return false;
      if (key.isEmpty) return true;
      return e.title.toLowerCase().contains(key) ||
          e.category.toLowerCase().contains(key) ||
          e.location.toLowerCase().contains(key);
    }).toList();

    Widget chip(String label, int i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: _filter == i,
            selectedColor: AppColors.primary,
            showCheckmark: false,
            labelStyle: TextStyle(color: _filter == i ? Colors.white : null, fontSize: 12),
            onSelected: (_) => setState(() => _filter = i),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Riwayat Kegiatan', 'Activity History'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: tx(context, 'Cari kegiatan...', 'Search activities...'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: softOf(context),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              chip(tx(context, 'Semua', 'All'), 0),
              chip(tx(context, 'Terdaftar', 'Registered'), 1),
              chip(tx(context, 'Selesai', 'Completed'), 2),
              chip(tx(context, 'Dibatalkan', 'Cancelled'), 3),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? EmptyState(Icons.event_busy, tx(context, 'Tidak ada kegiatan', 'No activities'),
                  tx(context, 'Coba ubah kata kunci atau filter.', 'Try changing the keyword or filter.'))
              : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 20), children: [
                  if (u.pastEvents > 0 && _filter == 0 && key.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${tx(context, 'Riwayat sebelum pencatatan', 'History before tracking')}: ${u.pastEvents} ${tx(context, 'kegiatan', 'activities')}',
                        style: TextStyle(fontSize: 11.5, color: muted(context)),
                      ),
                    ),
                  for (final r in list)
                    Builder(builder: (_) {
                      final e = s.eventById(r.eventId)!;
                      var pts = 0;
                      for (final p in s.pointEntries) {
                        if (p.userId == u.id && p.verified && p.eventId == e.id) pts += p.points;
                      }
                      final Color sc;
                      final String sl;
                      if (r.status == RegStatus.registered) {
                        sc = AppColors.success;
                        sl = tx(context, 'Terdaftar', 'Registered');
                      } else if (r.status == RegStatus.attended) {
                        sc = AppColors.primary;
                        sl = tx(context, 'Selesai', 'Completed');
                      } else {
                        sc = Colors.grey;
                        sl = tx(context, 'Dibatalkan', 'Cancelled');
                      }
                      return PCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
                        child: Row(children: [
                          EventImage(e, width: 64, height: 64, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 3),
                              Text('${fmtDate(e.date)} • ${e.category}',
                                  style: TextStyle(fontSize: 11, color: muted(context))),
                              const SizedBox(height: 4),
                              Text(
                                r.status == RegStatus.attended
                                    ? '+$pts ${tx(context, 'poin', 'points')}'
                                    : (r.status == RegStatus.registered
                                        ? tx(context, 'Poin menunggu verifikasi', 'Points pending verification')
                                        : '-'),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: r.status == RegStatus.attended ? AppColors.success : muted(context)),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: sc.withAlpha(28), borderRadius: BorderRadius.circular(10)),
                            child: Text(sl, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: sc)),
                          ),
                        ]),
                      );
                    }),
                ]),
        ),
      ]),
    );
  }
}

// ============================================================
// MONTHLY RECAP (+ bagikan sebagai gambar dalam PDF)
// ============================================================
class MonthlyRecapScreen extends StatefulWidget {
  const MonthlyRecapScreen({super.key});

  @override
  State<MonthlyRecapScreen> createState() => _MonthlyRecapScreenState();
}

class _MonthlyRecapScreenState extends State<MonthlyRecapScreen> {
  final GlobalKey _cardKey = GlobalKey();
  int _back = 0; // 0 = bulan ini, 1 = bulan lalu, dst.

  DateTime get _month {
    final n = DateTime.now();
    return DateTime(n.year, n.month - _back);
  }

  String _summaryText(AppState s, String uid, String name, MonthStat ms, List<String> badges) {
    final en = context.read<ProfileStore>().isEnglish;
    final label = monthYear(context, _month);
    return en
        ? 'Monthly Recap $label - $name\n'
            '${ms.events} events • ${ms.hours} hours • ${fmtNum(ms.points)} points\n'
            '${badges.isEmpty ? 'Keep going!' : 'New badges: ${badges.join(', ')}'}\n'
            '#Volunteer #TogetherWeMakeAnImpact'
        : 'Monthly Recap $label - $name\n'
            '${ms.events} event • ${ms.hours} jam • ${fmtNum(ms.points)} poin\n'
            '${badges.isEmpty ? 'Terus semangat!' : 'Badge baru: ${badges.join(', ')}'}\n'
            '#Volunteer #BersamaKitaMemberiDampak';
  }

  Future<void> _share(String fallbackText) async {
    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('no boundary');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('no data');
      final bytes = data.buffer.asUint8List();

      final doc = pw.Document();
      final img = pw.MemoryImage(bytes);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (c) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
      ));
      await Printing.sharePdf(bytes: await doc.save(), filename: 'monthly-recap.pdf');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      if (mounted) {
        pSnack(context, txr(context, 'Berbagi gambar belum didukung di perangkat ini. Ringkasan disalin ke clipboard.',
            'Image sharing is not supported on this device. Summary copied to clipboard.'));
      }
    }
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final ms = s.monthStat(u.id, _month);
    final badges = <String>[];
    for (final b in kAchBadges) {
      final st = s.badgeStatus(u.id, b);
      final d = st.date;
      if (st.earned && d != null && d.year == _month.year && d.month == _month.month) badges.add(b.name);
    }
    final summary = _summaryText(s, u.id, u.name, ms, badges);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Recap')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _back < 5 ? () => setState(() => _back++) : null,
                ),
                Text(monthYear(context, _month), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _back > 0 ? () => setState(() => _back--) : null,
                ),
              ]),
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.volunteer_activism, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Monthly Recap',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      Text(monthYear(context, _month),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                    const SizedBox(height: 18),
                    const Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 64),
                    const SizedBox(height: 8),
                    Text(u.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(tx(context, 'Ringkasan kontribusimu bulan ini', 'Your contribution summary this month'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        _stat(Icons.event_available, '${ms.events}', tx(context, 'Event', 'Events')),
                        _stat(Icons.schedule, '${ms.hours}', tx(context, 'Jam', 'Hours')),
                        _stat(Icons.star_rounded, fmtNum(ms.points), tx(context, 'Poin', 'Points')),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${tx(context, 'Kegiatan selesai', 'Completed activities')}: ${ms.events}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badges.isEmpty
                          ? tx(context, 'Ayo kumpulkan lebih banyak poin bulan ini! 💪',
                              'Let’s collect more points this month! 💪')
                          : '${tx(context, 'Badge baru', 'New badges')}: ${badges.join(', ')} 🎉',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    const Text('Volunteer • Bersama, Kita Memberi Dampak',
                        style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _share(summary),
                  icon: const Icon(Icons.share),
                  label: Text(tx(context, 'Bagikan Recap', 'Share Recap')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: summary));
                    if (context.mounted) {
                      pSnack(context, txr(context, 'Ringkasan disalin', 'Summary copied'));
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(tx(context, 'Salin Ringkasan Teks', 'Copy Text Summary')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tx(context, 'Recap dibagikan sebagai gambar di dalam berkas PDF.',
                    'The recap is shared as an image inside a PDF file.'),
                style: TextStyle(fontSize: 11, color: muted(context)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// VOLUNTEER JOURNEY (timeline)
// ============================================================
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final joined = st.joinedAt(u.id, evidence: s.earliestActivity(u.id));
    final items = s.journeyOf(u.id, joined);
    final lv = levelOf(s.totalPoints);
    final earned = kAchBadges.where((b) => s.achEarned(u.id, b)).length;

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Perjalanan Volunteer', 'Volunteer Journey'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Row(children: [
                  PAvatar(u.id, u.name, size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('${tx(context, 'Bergabung sejak', 'Member since')} ${fmtLongDate(joined)}',
                          style: TextStyle(fontSize: 11.5, color: muted(context))),
                      const SizedBox(height: 4),
                      Text('Level ${lv.name} • $earned ${tx(context, 'badge', 'badges')} • ${fmtNum(s.totalPoints)} ${tx(context, 'poin', 'pts')}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < items.length; i++)
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 44,
                      child: Column(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: items[i].color.withAlpha(30), shape: BoxShape.circle),
                          child: Icon(items[i].icon, color: items[i].color, size: 19),
                        ),
                        if (i < items.length - 1)
                          Expanded(child: Container(width: 2, color: AppColors.primary.withAlpha(60))),
                      ]),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: PCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fmtDate(items[i].date),
                                style: TextStyle(fontSize: 10.5, color: muted(context), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(items[i].subtitle, style: TextStyle(fontSize: 11.5, color: muted(context), height: 1.3)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// PERSONAL GOAL
// ============================================================
/// Memberi notifikasi sekali per bulan ketika target pribadi tercapai.
void checkGoalNotifications(AppState s, ProfileStore st) {
  final u = s.user;
  if (u == null) return;
  final now = DateTime.now();
  final ms = s.monthStat(u.id, now);
  final month = '${now.year}-${now.month}';

  void push(String keySuffix, String body) {
    final key = '$month:$keySuffix';
    if (st.goalNotified(u.id, key)) return;
    st.markGoalNotified(u.id, key);
    s.notifs.insert(
      0,
      Notif(
        id: s.newId('n'),
        userId: u.id,
        title: st.isEnglish ? 'Goal reached! 🎯' : 'Target tercapai! 🎯',
        body: body,
        kind: 'badge',
        createdAt: DateTime.now(),
      ),
    );
    s.commitCommunity();
  }

  final ge = st.goalEvents(u.id);
  final gh = st.goalHours(u.id);
  if (ge > 0 && ms.events >= ge) {
    push('e', st.isEnglish ? 'You reached your monthly goal of $ge events.' : 'Kamu mencapai target $ge event bulan ini.');
  }
  if (gh > 0 && ms.hours >= gh) {
    push('h', st.isEnglish ? 'You reached your monthly goal of $gh hours.' : 'Kamu mencapai target $gh jam kontribusi bulan ini.');
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      checkGoalNotifications(context.read<AppState>(), context.read<ProfileStore>());
    });
  }

  Future<void> _edit() async {
    final s = context.read<AppState>();
    final st = context.read<ProfileStore>();
    final u = s.user;
    if (u == null) return;
    var e = st.goalEvents(u.id);
    var h = st.goalHours(u.id);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          Widget stepper(String label, int value, int min, int max, int step, ValueChanged<int> onChanged) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                  onPressed: value - step >= min ? () => setSt(() => onChanged(value - step)) : null,
                ),
                SizedBox(
                  width: 36,
                  child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: value + step <= max ? () => setSt(() => onChanged(value + step)) : null,
                ),
              ]),
            );
          }

          return AlertDialog(
            title: Text(tx(ctx, 'Ubah Target Bulanan', 'Edit Monthly Goals')),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              stepper(tx(ctx, 'Target event', 'Event goal'), e, 1, 30, 1, (v) => e = v),
              stepper(tx(ctx, 'Target jam', 'Hours goal'), h, 1, 200, 1, (v) => h = v),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx(ctx, 'Batal', 'Cancel'))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text(tx(ctx, 'Simpan', 'Save')),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    st.setGoals(u.id, e, h);
    checkGoalNotifications(s, st);
    pSnack(context, txr(context, 'Target disimpan', 'Goals saved'));
  }

  Widget _goalCard(BuildContext context, IconData icon, String title, int current, int goal, String unit) {
    final pct = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0).toDouble();
    final done = goal > 0 && current >= goal;
    return PCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          if (done) const Icon(Icons.verified, color: AppColors.success),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$current', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text(' / $goal $unit', style: TextStyle(fontSize: 13, color: muted(context))),
          const Spacer(),
          Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: AppColors.primary.withAlpha(28),
            valueColor: AlwaysStoppedAnimation<Color>(done ? AppColors.success : AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done
              ? tx(context, 'Hebat! Target bulan ini tercapai 🎉', 'Great! This month’s goal is reached 🎉')
              : '${tx(context, 'Tinggal', 'Only')} ${goal - current} $unit ${tx(context, 'lagi untuk mencapai target', 'to reach your goal')}',
          style: TextStyle(fontSize: 12, color: done ? AppColors.success : muted(context)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final ms = s.monthStat(u.id, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Target Pribadi', 'Personal Goals'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(monthYear(context, DateTime.now()),
                      style: TextStyle(fontSize: 13, color: muted(context), fontWeight: FontWeight.w600)),
                ),
              ),
              _goalCard(context, Icons.event_available, tx(context, 'Target Event Bulanan', 'Monthly Event Goal'),
                  ms.events, st.goalEvents(u.id), tx(context, 'event', 'events')),
              _goalCard(context, Icons.schedule, tx(context, 'Target Jam Kontribusi', 'Contribution Hours Goal'),
                  ms.hours, st.goalHours(u.id), tx(context, 'jam', 'hours')),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(tx(context, 'Ubah Target', 'Edit Goals')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tx(context, 'Progress dihitung dari kegiatan yang sudah diverifikasi bulan ini. Kamu akan mendapat notifikasi saat target tercapai.',
                    'Progress is calculated from verified activities this month. You will get a notification when a goal is reached.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: muted(context), height: 1.4),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// RIWAYAT POIN (saldo + semua perolehan poin)
// ============================================================
class PointLedgerScreen extends StatelessWidget {
  const PointLedgerScreen({super.key});

  IconData _icon(String t) {
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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final list = s.myPointHistory;
    var pending = 0;
    for (final e in list) {
      if (!e.verified) pending += e.points;
    }

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Riwayat Poin', 'Point History'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tx(context, 'Total Saldo Poin', 'Total Point Balance'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(fmtNum(s.totalPoints),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  if (pending > 0)
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(tx(context, 'Menunggu verifikasi', 'Pending'),
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('+${fmtNum(pending)}',
                          style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w800)),
                    ]),
                ]),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                EmptyState(Icons.stars_outlined, tx(context, 'Belum ada riwayat poin', 'No point history yet'),
                    tx(context, 'Ikuti kegiatan untuk mulai mengumpulkan poin.', 'Join activities to start earning points.'))
              else
                for (final e in list)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(24), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_icon(e.type), color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('${fmtDate(e.date)} • ${e.note}',
                              style: TextStyle(fontSize: 11, color: muted(context), height: 1.3)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('+${fmtNum(e.points)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: e.verified ? AppColors.success : AppColors.warning)),
                        const SizedBox(height: 3),
                        Text(
                          e.verified ? tx(context, 'Terverifikasi', 'Verified') : tx(context, 'Menunggu', 'Pending'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: e.verified ? AppColors.success : AppColors.warning),
                        ),
                      ]),
                    ]),
                  ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// PUSAT BANTUAN
// ============================================================
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final en = st.isEnglish;
    final u = s.user;

    final faqs = <(String, String, String, String)>[
      ('Bagaimana cara mendaftar kegiatan?', 'How do I register for an activity?',
          'Buka tab Event, pilih kegiatan, lalu tekan "Daftar Relawan". Isi biodata, dan jika berbayar lanjut ke pembayaran.',
          'Open the Event tab, choose an activity and press "Daftar Relawan". Fill in your details and continue to payment if it is paid.'),
      ('Bagaimana cara mendapatkan poin?', 'How do I earn points?',
          'Poin diberikan setelah kehadiranmu diverifikasi panitia: +40 per event, bonus +50 setiap 5 event, +10 koordinator, dan +10 apresiasi.',
          'Points are given after your attendance is verified: +40 per event, +50 bonus every 5 events, +10 coordinator and +10 appreciation.'),
      ('Kapan sertifikat tersedia?', 'When is my certificate available?',
          'Sertifikat tersedia di menu Sertifikat Saya setelah kegiatan selesai dan kehadiranmu terverifikasi.',
          'Certificates are available in My Certificates after the activity is finished and your attendance is verified.'),
      ('Bagaimana cara membatalkan pendaftaran?', 'How do I cancel a registration?',
          'Buka tab Riwayat, pilih kegiatan, lalu pilih "Batalkan Pendaftaran".',
          'Open the History tab, choose the activity and select "Batalkan Pendaftaran".'),
      ('Bagaimana cara naik level?', 'How do I level up?',
          'Kumpulkan poin dari kegiatan. Level: Beginner, Cool (1.000), Master (2.500), Brilliant (5.000), Expert (10.000).',
          'Collect points from activities. Levels: Beginner, Cool (1,000), Master (2,500), Brilliant (5,000), Expert (10,000).'),
      ('Bagaimana mengganti foto profil?', 'How do I change my profile photo?',
          'Tekan ikon kamera pada foto profilmu atau buka Edit Profil, lalu pilih foto dari galeri.',
          'Tap the camera icon on your photo or open Edit Profile, then choose a photo from the gallery.'),
      ('Apakah data saya aman?', 'Is my data safe?',
          'Data akunmu disimpan di perangkat ini. Email dan nomor telepon tidak ditampilkan kepada anggota lain.',
          'Your account data is stored on this device. Your email and phone number are never shown to other members.'),
    ];

    final guide = <(String, String)>[
      ('1. Buat akun dan lengkapi profilmu di menu Profil.', '1. Create an account and complete your profile in the Profile menu.'),
      ('2. Cari kegiatan di tab Event lalu daftar sebagai relawan.', '2. Find activities in the Event tab and register as a volunteer.'),
      ('3. Hadiri kegiatan dan tunjukkan tiket QR kepada panitia.', '3. Attend the activity and show your QR ticket to the organizers.'),
      ('4. Setelah diverifikasi, poin dan sertifikat masuk otomatis.', '4. Once verified, points and certificates are added automatically.'),
      ('5. Ikuti ruang diskusi di tab Komunitas dan ajak teman.', '5. Join discussion rooms in the Community tab and invite friends.'),
      ('6. Pantau levelmu, ranking, dan target pribadi di Profil.', '6. Track your level, ranking and personal goals in Profile.'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Pusat Bantuan', 'Help Center'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Column(children: [
                  PMenuTile(
                    icon: Icons.support_agent,
                    color: AppColors.primary,
                    title: tx(context, 'Hubungi Admin', 'Contact Admin'),
                    subtitle: 'support@volunteer.local',
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const FeedbackFormScreen('contact'))),
                  ),
                  PMenuTile(
                    icon: Icons.report_problem_outlined,
                    color: const Color(0xFFEA580C),
                    title: tx(context, 'Laporkan Masalah', 'Report a Problem'),
                    subtitle: tx(context, 'Beri tahu kami jika ada kendala', 'Tell us if something goes wrong'),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const FeedbackFormScreen('report'))),
                  ),
                  PMenuTile(
                    icon: Icons.lightbulb_outline,
                    color: const Color(0xFF7C3AED),
                    title: tx(context, 'Kirim Saran & Masukan', 'Send Suggestions & Feedback'),
                    subtitle: tx(context, 'Bantu kami menjadi lebih baik', 'Help us get better'),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const FeedbackFormScreen('suggestion'))),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PSectionHeader(Icons.help_outline, tx(context, 'Pertanyaan Umum (FAQ)', 'Frequently Asked Questions')),
                  const SizedBox(height: 6),
                  for (final f in faqs)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 10),
                        expandedAlignment: Alignment.centerLeft,
                        title: Text(en ? f.$2 : f.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        children: [Text(en ? f.$4 : f.$3, style: TextStyle(fontSize: 12, color: muted(context), height: 1.4))],
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PSectionHeader(Icons.menu_book_outlined, tx(context, 'Panduan Penggunaan Aplikasi', 'App User Guide')),
                  const SizedBox(height: 10),
                  for (final g in guide)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(en ? g.$2 : g.$1, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                    ),
                ]),
              ),
              if (u != null) ...[
                const SizedBox(height: 14),
                _TicketHistory(userId: u.id, kind: null),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TicketHistory extends StatelessWidget {
  final String userId;
  final String? kind;
  const _TicketHistory({required this.userId, required this.kind});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<ProfileStore>();
    final list = st.tickets(userId).where((t) => kind == null || t['type'] == kind).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    String label(String t) {
      if (t == 'report') return tx(context, 'Masalah', 'Problem');
      if (t == 'suggestion') return tx(context, 'Saran', 'Suggestion');
      return tx(context, 'Pesan ke admin', 'Message to admin');
    }

    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.history, tx(context, 'Riwayat Laporanmu', 'Your Report History')),
        const SizedBox(height: 10),
        for (final t in list.take(10))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${label(t['type'] as String)} • ${fmtDateTime(DateTime.fromMillisecondsSinceEpoch((t['at'] as num).toInt()))}',
                style: TextStyle(fontSize: 10.5, color: muted(context), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(t['text'] as String, style: const TextStyle(fontSize: 12.5, height: 1.35)),
            ]),
          ),
      ]),
    );
  }
}

class FeedbackFormScreen extends StatefulWidget {
  final String kind; // 'report' | 'suggestion' | 'contact'
  const FeedbackFormScreen(this.kind, {super.key});

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final u = context.read<AppState>().user;
    if (u == null) return;
    final t = _ctrl.text.trim();
    if (t.length < 10) {
      pSnack(context, txr(context, 'Tulis minimal 10 karakter', 'Please write at least 10 characters'));
      return;
    }
    context.read<ProfileStore>().addTicket(u.id, widget.kind, t);
    _ctrl.clear();
    FocusScope.of(context).unfocus();
    pSnack(context, txr(context, 'Tersimpan di perangkat. Terima kasih atas masukanmu!', 'Saved on this device. Thank you for your feedback!'));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().user;
    final title = widget.kind == 'report'
        ? tx(context, 'Laporkan Masalah', 'Report a Problem')
        : (widget.kind == 'suggestion'
            ? tx(context, 'Kirim Saran & Masukan', 'Send Suggestions & Feedback')
            : tx(context, 'Hubungi Admin', 'Contact Admin'));
    final hint = widget.kind == 'report'
        ? tx(context, 'Jelaskan masalah yang kamu alami...', 'Describe the problem you experienced...')
        : (widget.kind == 'suggestion'
            ? tx(context, 'Tulis saran atau masukanmu...', 'Write your suggestion or feedback...')
            : tx(context, 'Tulis pesan untuk admin...', 'Write a message for the admin...'));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: _ctrl,
                    minLines: 5,
                    maxLines: 8,
                    maxLength: 600,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                      label: Text(tx(context, 'Kirim', 'Send')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tx(context,
                        'Catatan: aplikasi ini belum terhubung ke server admin, sehingga pesanmu disimpan di perangkat ini. '
                            'Agar sampai ke admin, aplikasi memerlukan endpoint backend (misalnya POST /support/tickets).',
                        'Note: this app is not connected to an admin server yet, so your message is stored on this device. '
                            'To reach the admin, the app needs a backend endpoint (for example POST /support/tickets).'),
                    style: TextStyle(fontSize: 11, color: muted(context), height: 1.4),
                  ),
                ]),
              ),
              if (u != null) ...[
                const SizedBox(height: 14),
                _TicketHistory(userId: u.id, kind: widget.kind),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}