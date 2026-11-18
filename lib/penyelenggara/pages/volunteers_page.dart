import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';

/// Dialog profil relawan + keputusan terima/tolak. Dipakai juga oleh Dashboard.
Future<void> showVolunteerDetail(BuildContext context, Registration r) {
  return showDialog(
    context: context,
    builder: (dc) {
      final s = dc.watch<AppState>();
      final org = dc.watch<OrgStore>();
      final u = s.userById(r.userId);
      final e = s.eventById(r.eventId);
      final st = org.regState(s, r);
      Widget row(IconData i, String k, String v) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(i, size: 17, color: Colors.black45),
              const SizedBox(width: 10),
              SizedBox(width: 86, child: Text(k, style: const TextStyle(color: Colors.black54, fontSize: 12.5))),
              Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          );
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(children: [
          Avatar(initialsOf(u?.name ?? '?'), size: 46),
          const SizedBox(width: 12),
          Expanded(child: Text(u?.name ?? 'Relawan', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          StatusPill(kRegLabel[st] ?? st, statusColor(st)),
        ]),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              row(Icons.mail_outline, 'Email', u?.email ?? ''),
              row(Icons.phone_outlined, 'Telepon', u?.phone ?? ''),
              row(Icons.location_city_outlined, 'Kota', u?.city ?? ''),
              row(Icons.info_outline, 'Bio', u?.bio ?? ''),
              const Divider(height: 24),
              row(Icons.event_outlined, 'Event', e?.title ?? '-'),
              row(Icons.confirmation_number_outlined, 'Kode', r.code),
              row(Icons.schedule_rounded, 'Mendaftar', fmtDateTime(r.createdAt)),
              const Divider(height: 24),
              row(Icons.workspace_premium_outlined, 'Event diikuti', '${u == null ? 0 : s.eventsOf(u.id)} kegiatan'),
              row(Icons.stars_rounded, 'Total poin', '${u == null ? 0 : s.pointsOf(u.id)} poin'),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Tutup')),
          if (st == 'pending') ...[
            OutlinedButton(
              onPressed: () {
                org.decide(s, r, false);
                Navigator.pop(dc);
                toast(context, 'Pendaftaran ditolak. Relawan mendapat notifikasi.');
              },
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              style: redBtn(small: true),
              onPressed: () {
                org.decide(s, r, true);
                Navigator.pop(dc);
                toast(context, 'Pendaftaran diterima. Status relawan diperbarui.');
              },
              child: const Text('Terima'),
            ),
          ],
        ],
      );
    },
  );
}

class VolunteersPage extends StatefulWidget {
  const VolunteersPage({super.key});
  @override
  State<VolunteersPage> createState() => _VolunteersPageState();
}

class _VolunteersPageState extends State<VolunteersPage> {
  String _q = '', _status = 'all';
  String? _event;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final events = org.myEvents(s, u.id).where((e) => org.metaOf(e).status != 'draft').toList();
    final all = org.regsFor(s, events.map((e) => e.id));
    int count(String st) => all.where((r) => org.regState(s, r) == st).length;

    final list = all.where((r) {
      final st = org.regState(s, r);
      if (_status != 'all' && st != _status) return false;
      if (_event != null && r.eventId != _event) return false;
      if (_q.trim().isNotEmpty) {
        final k = _q.trim().toLowerCase();
        final v = s.userById(r.userId);
        final e = s.eventById(r.eventId);
        final hay = '${v?.name} ${v?.email} ${e?.title} ${r.code}'.toLowerCase();
        if (!hay.contains(k)) return false;
      }
      return true;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHead('Manajemen Relawan', 'Kelola pendaftar pada seluruh event milik organisasimu'),
      Grid([
        _stat('Total pendaftar', all.where((r) => org.regState(s, r) != 'cancelled').length, Icons.groups_rounded, AppColors.primary),
        _stat('Pending', count('pending'), Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
        _stat('Diterima', count('accepted'), Icons.check_circle_rounded, const Color(0xFF16A34A)),
        _stat('Selesai (hadir)', count('completed'), Icons.verified_rounded, const Color(0xFF2563EB)),
      ], minWidth: 180),
      const SizedBox(height: 16),
      OrgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(width: 280, child: TextField(onChanged: (v) => setState(() => _q = v), decoration: fieldDeco(null, hint: 'Cari nama, email, event, kode...', icon: Icons.search_rounded))),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                value: _event,
                isExpanded: true,
                decoration: fieldDeco('Event'),
                items: [const DropdownMenuItem<String?>(value: null, child: Text('Semua event')), for (final e in events) DropdownMenuItem<String?>(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => _event = v),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final f in const ['all', 'pending', 'accepted', 'rejected', 'completed'])
              ChoiceChip(
                label: Text(f == 'all' ? 'Semua' : kRegLabel[f]!),
                selected: _status == f,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: _status == f ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12.5),
                onSelected: (_) => setState(() => _status = f),
              ),
          ]),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const EmptyBox(Icons.person_search_rounded, 'Belum ada relawan yang sesuai filter')
          else
            for (final r in list) _row(context, s, org, r),
        ]),
      ),
    ]);
  }

  Widget _stat(String t, int n, IconData i, Color c) => OrgCard(
        child: Row(children: [
          CircleAvatar(radius: 22, backgroundColor: c.withOpacity(.12), child: Icon(i, color: c)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(t, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ]),
      );

  Widget _row(BuildContext context, AppState s, OrgStore org, Registration r) {
    final v = s.userById(r.userId);
    final e = s.eventById(r.eventId);
    final st = org.regState(s, r);
    final actions = Wrap(spacing: 6, runSpacing: 6, children: [
      OutlinedButton(onPressed: () => showVolunteerDetail(context, r), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact), child: const Text('Detail')),
      if (st == 'pending') ...[
        ElevatedButton(style: redBtn(small: true), onPressed: () { org.decide(s, r, true); toast(context, '${v?.name ?? 'Relawan'} diterima'); }, child: const Text('Terima')),
        ElevatedButton(style: softBtn(small: true), onPressed: () { org.decide(s, r, false); toast(context, '${v?.name ?? 'Relawan'} ditolak'); }, child: const Text('Tolak')),
      ],
    ]);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: kOrgLine), borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(builder: (_, c) {
        final info = Row(children: [
          Avatar(initialsOf(v?.name ?? '?')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v?.name ?? 'Relawan', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text('${e?.title ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text('Daftar ${fmtDate(r.createdAt)} • ${r.code}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ]),
          ),
        ]);
        final pill = StatusPill(kRegLabel[st] ?? st, statusColor(st));
        if (c.maxWidth < 640) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 8), Row(children: [pill, const Spacer()]), const SizedBox(height: 8), actions]);
        }
        return Row(children: [Expanded(child: info), const SizedBox(width: 10), pill, const SizedBox(width: 14), actions]);
      }),
    );
  }
}
