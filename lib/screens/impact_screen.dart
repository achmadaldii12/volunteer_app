import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import '../models/gamification.dart.dart';

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Jumlah kegiatan per kategori (dari kegiatan yang sudah dihadiri di aplikasi)
    final perCat = <String, int>{};
    for (final r in s.attendedRegs) {
      final e = s.eventById(r.eventId);
      if (e != null) perCat[e.category] = (perCat[e.category] ?? 0) + 1;
    }
    final maxCat = perCat.values.fold<int>(1, (a, b) => b > a ? b : a);

    return Scaffold(
      appBar: AppBar(title: const Text('Dampak Saya')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          StatTile(Icons.verified_user_outlined, '${s.totalEvents}', 'Kegiatan'),
          StatTile(Icons.timer_outlined, '${s.totalHours} Jam', 'Kontribusi'),
          StatTile(Icons.people_outline, fmtNum(s.totalImpact), 'Orang\nTerbantu'),
        ]),
        const SizedBox(height: 22),
        const Text('Dampak Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset('assets/image/volunteer_team.jpg', height: 190, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 12),
        const Center(
            child: Text('Bersama kita telah membantu\nlebih banyak orang!',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500))),
        if (perCat.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('Kegiatan per Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          for (final en in perCat.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(width: 92, child: Text(en.key, style: const TextStyle(fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: en.value / maxCat, minHeight: 10,
                        color: categoryInfo(en.key).color, backgroundColor: softOf(context)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${en.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
        ],
      ]),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final done = s.attendedRegs;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Kegiatan')),
      body: done.isEmpty
          ? const EmptyState(Icons.history, 'Belum ada riwayat', 'Kegiatan yang sudah selesai akan tercatat di sini.')
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in done)
                if (s.eventById(r.eventId) != null)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      EventImage(s.eventById(r.eventId)!, width: 60, height: 60),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.eventById(r.eventId)!.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                               '${fmtDate(s.eventById(r.eventId)!.date)} - ${s.eventById(r.eventId)!.hours} jam - +$kPointsPerEvent poin',
                              style: TextStyle(fontSize: 11, color: muted(context))),
                        ]),
                      ),
                    ]),
                  ),
            ]),
    );
  }
}
