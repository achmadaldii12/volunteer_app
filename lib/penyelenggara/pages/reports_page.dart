import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';
import '../pdf_exports.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final prof = org.profileOf(u);
    final live = org.myEvents(s, u.id).where((e) => org.metaOf(e).status != 'draft').toList();
    final regs = org.regsFor(s, live.map((e) => e.id));
    int c(String st) => regs.where((r) => org.regState(s, r) == st).length;
    final pendaftar = regs.length;
    final diterima = c('accepted') + c('completed');
    final hadir = c('completed');
    final rate = diterima == 0 ? 0.0 : hadir / diterima * 100;
    final top = [...live]..sort((a, b) => s.participants(b).compareTo(s.participants(a)));
    final maxP = top.isEmpty ? 1 : s.participants(top.first);

    // pertumbuhan kumulatif per bulan (12 bulan sejak event pertama)
    final now = DateTime.now();
    var start = DateTime(now.year, now.month);
    if (live.isNotEmpty) {
      final f = live.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      start = DateTime(f.year, f.month);
    }
    final labels = <String>[], vals = <double>[];
    for (var i = 0; i < 8; i++) {
      final m = DateTime(start.year, start.month + i);
      labels.add(DateFormat('MMM', 'id_ID').format(m));
      vals.add(live.where((e) => !DateTime(e.date.year, e.date.month).isAfter(m)).length.toDouble());
    }

    final summary = <List<String>>[
      ['Total event', '${live.length}'],
      ['Total pendaftar', '$pendaftar'],
      ['Relawan diterima', '$diterima'],
      ['Relawan hadir', '$hadir'],
      ['Tingkat kehadiran', '${rate.toStringAsFixed(1)}%'],
    ];
    final header = ['Event', 'Kategori', 'Tanggal', 'Status', 'Terdaftar', 'Kuota'];
    final rows = [for (final e in top) [e.title, e.category, fmtDate(e.date), kStatusLabel[org.statusOf(e)] ?? '', '${s.participants(e)}', '${e.quota}']];

    Widget stat(String t, String v, IconData i, Color col) => OrgCard(
          child: Row(children: [
            CircleAvatar(radius: 21, backgroundColor: col.withOpacity(.12), child: Icon(i, color: col, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), Text(t, style: const TextStyle(fontSize: 12, color: Colors.black54))])),
          ]),
        );

    final cats = OrgSection(
      title: 'Event berdasarkan Kategori',
      icon: Icons.pie_chart_rounded,
      child: Column(children: [
        for (final k in kCategories) HBar(k.name, live.where((e) => e.category == k.name).length.toDouble(), live.length.toDouble(), k.color, '${live.where((e) => e.category == k.name).length} event'),
      ]),
    );
    final growth = OrgSection(title: 'Perkembangan Kegiatan', icon: Icons.show_chart_rounded, child: LineChart(a: vals, labels: labels, height: 190));
    final popular = OrgSection(
      title: 'Event Paling Diminati',
      icon: Icons.local_fire_department_rounded,
      child: top.isEmpty
          ? const EmptyBox(Icons.event_busy_rounded, 'Belum ada data event')
          : Column(children: [for (final e in top.take(5)) HBar(e.title, s.participants(e).toDouble(), maxP.toDouble(), AppColors.primary, '${s.participants(e)}')]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHead('Laporan', 'Ringkasan kinerja kegiatan dan relawan', actions: [
        ElevatedButton.icon(
          style: softBtn(),
          icon: const Icon(Icons.table_chart_rounded, size: 18),
          label: const Text('Export Excel'),
          onPressed: () {
            final b = StringBuffer();
            for (final r in summary) {
              b.writeln(r.join('\t'));
            }
            b.writeln();
            b.writeln(header.join('\t'));
            for (final r in rows) {
              b.writeln(r.join('\t'));
            }
            Clipboard.setData(ClipboardData(text: b.toString()));
            toast(context, 'Data disalin (format tab). Buka Excel lalu Paste (Ctrl+V).');
          },
        ),
        ElevatedButton.icon(
          style: redBtn(),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
          label: const Text('Export PDF'),
          onPressed: () => shareReportPdf(
            orgName: prof.name,
            generatedAt: DateFormat('d MMM yyyy', 'id_ID').format(DateTime.now()),
            summary: summary,
            eventHeader: header,
            eventRows: rows,
          ),
        ),
      ]),
      Grid([
        stat('Total event', '${live.length}', Icons.calendar_month_rounded, AppColors.primary),
        stat('Total pendaftar', fmtNum(pendaftar), Icons.how_to_reg_rounded, const Color(0xFF2563EB)),
        stat('Relawan diterima', fmtNum(diterima), Icons.check_circle_rounded, const Color(0xFF16A34A)),
        stat('Relawan hadir', fmtNum(hadir), Icons.verified_rounded, const Color(0xFF7C3AED)),
        stat('Tingkat kehadiran', '${rate.toStringAsFixed(1)}%', Icons.percent_rounded, const Color(0xFFF59E0B)),
      ], minWidth: 200),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (_, w) {
        if (w.maxWidth < 900) return Column(children: [cats, const SizedBox(height: 16), growth, const SizedBox(height: 16), popular]);
        return Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: cats), const SizedBox(width: 16), Expanded(child: popular)]),
          const SizedBox(height: 16),
          growth,
        ]);
      }),
    ]);
  }
}
