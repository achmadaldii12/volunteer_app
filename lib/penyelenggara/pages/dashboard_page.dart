import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../widgets/common.dart';
import '../org_widgets.dart';
import '../organizer_shell.dart';
import '../organizer_store.dart';
import 'volunteers_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _months = 6;
  bool _relawan = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final prof = org.profileOf(u);
    final events = org.myEvents(s, u.id);
    final live = events.where((e) => org.metaOf(e).status != 'draft').toList();
    final done = live.where((e) => org.statusOf(e) == 'completed').length;
    final volunteers = live.fold<int>(0, (a, e) => a + s.participants(e));
    final titles = live.map((e) => e.title).toSet();
    final fb = s.feedbacks.where((f) => titles.contains(f.eventTitle)).toList();
    final rating = fb.isEmpty ? null : fb.fold<int>(0, (a, f) => a + f.rating) / fb.length;
    final pending = org.regsFor(s, live.map((e) => e.id)).where((r) => org.regState(s, r) == 'pending').toList();

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1080;
      final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stats(events.length, volunteers, done, rating, fb.length),
        const SizedBox(height: 16),
        _chartCard(live, org),
        const SizedBox(height: 16),
        _myEvents(live, s, org),
      ]);
      final right = Column(children: [
        _pendingCard(context, s, org, pending),
        const SizedBox(height: 16),
        _quick(),
      ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _banner(prof.name, c.maxWidth),
        const SizedBox(height: 16),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 16), SizedBox(width: 370, child: right)])
        else ...[left, const SizedBox(height: 16), right],
      ]);
    });
  }

  Widget _banner(String name, double w) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFFFE4E6), Color(0xFFFFC9CE)]),
        boxShadow: const [BoxShadow(color: Color(0x1ADC2626), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Stack(children: [
        if (w > 720)
          Positioned(
            right: 0, top: 0, bottom: 0, width: w * .42,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: [Colors.transparent, Colors.black], stops: [0, .45]).createShader(r),
              blendMode: BlendMode.dstIn,
              child: Image.asset('assets/image/volunteer_banner.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $name! 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF7F1D1D))),
            const SizedBox(height: 6),
            ConstrainedBox(constraints: BoxConstraints(maxWidth: w > 720 ? w * .5 : w), child: const Text('Terima kasih telah menjadi bagian dari perubahan positif bersama Volunteer.', style: TextStyle(fontSize: 14, color: Colors.black87))),
            const SizedBox(height: 4),
            const Text('"Bersama, kita bisa lebih banyak memberi arti."', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: OrgNav.create, style: redBtn(), icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: const Text('Buat Event Sekarang')),
          ]),
        ),
      ]),
    );
  }

  Widget _stats(int total, int vol, int done, double? rating, int nFb) {
    Widget card(IconData i, String v, String l, String sub, Color col) => OrgCard(
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: col.withOpacity(.12), child: Icon(i, color: col, size: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text(l, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ]),
            ),
          ]),
        );
    return Grid([
      card(Icons.calendar_month_rounded, '$total', 'Total Event', 'semua status', AppColors.primary),
      card(Icons.groups_rounded, fmtNum(vol), 'Total Relawan', 'terdaftar di event', const Color(0xFFEF4444)),
      card(Icons.check_circle_rounded, '$done', 'Event Selesai', 'sudah terlaksana', const Color(0xFFDC2626)),
      card(Icons.star_rounded, rating == null ? '-' : rating.toStringAsFixed(1), 'Rating Event', rating == null ? 'belum ada feedback' : 'dari $nFb ulasan', const Color(0xFFF59E0B)),
    ], minWidth: 200);
  }

  Widget _chartCard(List<EventModel> live, OrgStore org) {
    final now = DateTime.now();
    var start = DateTime(now.year, now.month);
    if (live.isNotEmpty) {
      final first = live.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final f = DateTime(first.year, first.month);
      if (f.isBefore(start)) start = f;
      // jika semua event ada di masa depan, mulai dari bulan event pertama
      if (live.every((e) => e.date.isAfter(DateTime(now.year, now.month + 1)))) start = f;
    }
    final labels = <String>[], evs = <double>[], vols = <double>[];
    final s = context.read<AppState>();
    for (var i = 0; i < _months; i++) {
      final m = DateTime(start.year, start.month + i);
      labels.add(DateFormat('MMM', 'id_ID').format(m));
      final upto = live.where((e) => !DateTime(e.date.year, e.date.month).isAfter(m)).toList();
      evs.add(upto.length.toDouble());
      vols.add(upto.fold<int>(0, (a, e) => a + s.participants(e)).toDouble());
    }
    final counts = [for (final cat in kCategories) live.where((e) => e.category == cat.name).length.toDouble()];
    final total = counts.fold<double>(0, (a, b) => a + b);

    return OrgSection(
      title: 'Statistik Kegiatan',
      icon: Icons.insights_rounded,
      trailing: DropdownButton<int>(
        value: _months,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(14),
        items: const [DropdownMenuItem(value: 3, child: Text('3 Bulan')), DropdownMenuItem(value: 6, child: Text('6 Bulan')), DropdownMenuItem(value: 12, child: Text('12 Bulan'))],
        onChanged: (v) => setState(() => _months = v ?? 6),
      ),
      child: LayoutBuilder(builder: (_, c) {
        final chart = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Relawan Terdaftar'), selected: _relawan, selectedColor: AppColors.soft, onSelected: (_) => setState(() => _relawan = true)),
            ChoiceChip(label: const Text('Event Dibuat'), selected: !_relawan, selectedColor: AppColors.soft, onSelected: (_) => setState(() => _relawan = false)),
          ]),
          const SizedBox(height: 10),
          LineChart(a: _relawan ? vols : evs, labels: labels),
        ]);
        final donut = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kategori Event', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            Donut(values: counts, colors: [for (final k in kCategories) k.color], center: '${total.toInt()}', size: 130),
            const SizedBox(width: 12),
            Expanded(
              child: Column(children: [
                for (var i = 0; i < kCategories.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      CircleAvatar(radius: 5, backgroundColor: kCategories[i].color),
                      const SizedBox(width: 6),
                      Expanded(child: Text(kCategories[i].name, style: const TextStyle(fontSize: 12))),
                      Text(total == 0 ? '0%' : '${(counts[i] / total * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ]);
        if (c.maxWidth < 720) return Column(children: [chart, const SizedBox(height: 18), donut]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: chart), const SizedBox(width: 20), Expanded(flex: 4, child: donut)]);
      }),
    );
  }

  Widget _myEvents(List<EventModel> live, AppState s, OrgStore org) {
    final latest = live.take(3).toList();
    return OrgSection(
      title: 'Event Saya',
      icon: Icons.event_note_rounded,
      trailing: TextButton(onPressed: () => OrgNav.go(1), child: const Text('Lihat Semua →')),
      child: latest.isEmpty
          ? const EmptyBox(Icons.event_busy_rounded, 'Belum ada event. Buat event pertamamu!')
          : Grid([
              for (final e in latest)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => OrgNav.go(1),
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: kOrgLine), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Stack(children: [
                        EventImage(e, width: double.infinity, height: 110, radius: 16),
                        Positioned(left: 8, top: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: statusColor(org.statusOf(e)), borderRadius: BorderRadius.circular(8)), child: Text(kStatusLabel[org.statusOf(e)] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)))),
                      ]),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(fmtDate(e.date), style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                          Text('${s.participants(e)} Relawan', style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ], minWidth: 200),
    );
  }

  Widget _pendingCard(BuildContext context, AppState s, OrgStore org, List<Registration> pending) {
    return OrgSection(
      title: 'Menunggu Persetujuan (${pending.length})',
      icon: Icons.hourglass_top_rounded,
      trailing: TextButton(onPressed: () => OrgNav.go(2), child: const Text('Lihat Semua →')),
      child: pending.isEmpty
          ? const EmptyBox(Icons.task_alt_rounded, 'Tidak ada pendaftar yang menunggu')
          : Column(children: [
              for (final r in pending.take(3))
                Builder(builder: (_) {
                  final e = s.eventById(r.eventId);
                  final v = s.userById(r.userId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8F8), borderRadius: BorderRadius.circular(16), border: Border.all(color: kOrgLine)),
                    child: Row(children: [
                      if (e != null) EventImage(e, width: 54, height: 54, radius: 12),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v?.name ?? 'Relawan', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(e?.title ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            _mini('Review', AppColors.primary, () => showVolunteerDetail(context, r)),
                            _mini('Terima', const Color(0xFF16A34A), () { org.decide(s, r, true); toast(context, 'Relawan diterima'); }),
                            _mini('Tolak', Colors.black54, () { org.decide(s, r, false); toast(context, 'Relawan ditolak'); }),
                          ]),
                        ]),
                      ),
                    ]),
                  );
                }),
            ]),
    );
  }

  Widget _mini(String t, Color c, VoidCallback f) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: f,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(8)), child: Text(t, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700))),
      );

  Widget _quick() {
    Widget tile(IconData i, String t, VoidCallback f) => InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(border: Border.all(color: kOrgLine), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [Icon(i, color: AppColors.primary, size: 26), const SizedBox(height: 6), Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
          ),
        );
    return OrgSection(
      title: 'Quick Actions',
      icon: Icons.bolt_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: [
          tile(Icons.event_available_rounded, 'Buat Event Baru', OrgNav.create),
          tile(Icons.groups_rounded, 'Kelola Relawan', () => OrgNav.go(2)),
          tile(Icons.bar_chart_rounded, 'Lihat Laporan', () => OrgNav.go(5)),
          tile(Icons.chat_bubble_rounded, 'Pesan Relawan', () => OrgNav.go(4)),
        ],
      ),
    );
  }
}
