import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'registration_success_screen.dart';

class MyActivitiesScreen extends StatelessWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.myRegs;
    final done = s.attendedRegs;
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text('Aktivitas Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const TabBar(tabs: [Tab(text: 'Mengikuti'), Tab(text: 'Selesai')]),
        Expanded(
          child: TabBarView(children: [
            _RegList(all, 'Belum ada kegiatan', 'Daftar kegiatan pertamamu dan mulai berkontribusi.'),
            _RegList(done, 'Belum ada kegiatan selesai', 'Kegiatan yang sudah kamu hadiri akan muncul di sini.'),
          ]),
        ),
      ]),
    );
  }
}

class _RegList extends StatelessWidget {
  final List<Registration> items;
  final String emptyTitle, emptySub;
  const _RegList(this.items, this.emptyTitle, this.emptySub);

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    if (items.isEmpty) {
      return EmptyState(Icons.event_busy, emptyTitle, emptySub,
          actionText: 'Cari Kegiatan', onAction: () => s.openSearch('Semua'));
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final r in items) _RegTile(r),
    ]);
  }
}

class _RegTile extends StatelessWidget {
  final Registration r;
  const _RegTile(this.r);

  void _actions(BuildContext context, EventModel e) {
    final s = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Lihat Detail Event'),
            onTap: () {
              Navigator.pop(sheet);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e)));
            },
          ),
          if (r.status != RegStatus.cancelled)
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Lihat Tiket'),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationSuccessScreen(r)));
              },
            ),
          if (r.status == RegStatus.registered) ...[
            ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: const Text('Simulasikan Hadir (demo)'),
              subtitle: const Text('Mencatat kehadiran, menambah poin & badge'),
              onTap: () {
                Navigator.pop(sheet);
                s.markAttended(r.id);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Kehadiran tercatat, +${e.points} poin')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              title: const Text('Batalkan Pendaftaran', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheet);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Batalkan pendaftaran?'),
                    content: Text('Pendaftaran untuk ${e.title} akan dibatalkan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, batalkan')),
                    ],
                  ),
                );
                if (ok == true) s.cancelReg(r.id);
              },
            ),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final e = s.eventById(r.eventId);
    if (e == null) return const SizedBox.shrink();
    final label = r.status == RegStatus.registered
        ? 'Terdaftar'
        : r.status == RegStatus.attended
            ? 'Selesai'
            : 'Dibatalkan';
    final color = r.status == RegStatus.registered
        ? AppColors.success
        : r.status == RegStatus.attended
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      onTap: () => _actions(context, e),
      child: Row(children: [
        EventImage(e, width: 62, height: 62),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(fmtDate(e.date), style: TextStyle(fontSize: 11, color: muted(context))),
          ]),
        ),
        StatusChip(label, color),
      ]),
    );
  }
}
