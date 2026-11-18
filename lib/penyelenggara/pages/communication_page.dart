import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';

const _kinds = <(String, String, IconData)>[
  ('announcement', 'Pengumuman', Icons.campaign_rounded),
  ('private', 'Pesan Peserta', Icons.mark_email_unread_rounded),
  ('reminder', 'Pengingat', Icons.alarm_rounded),
  ('schedule', 'Perubahan Jadwal', Icons.update_rounded),
];

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});
  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  final _title = TextEditingController(), _body = TextEditingController();
  String _kind = 'announcement';
  String? _event;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _send(AppState s, OrgStore org, String ownerId) {
    final needsEvent = _kind != 'announcement';
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return toast(context, 'Judul dan isi pesan wajib diisi');
    if (needsEvent && _event == null) return toast(context, 'Pilih event tujuan terlebih dahulu');
    final target = needsEvent ? _event : _event; // pengumuman boleh ke semua (null) atau event tertentu
    final prefix = _kind == 'reminder' ? 'Pengingat: ' : (_kind == 'schedule' ? 'Perubahan jadwal: ' : '');
    final n = org.send(s, ownerId: ownerId, kind: _kind, title: '$prefix${_title.text.trim()}', body: _body.text.trim(), eventId: target);
    _title.clear();
    _body.clear();
    toast(context, n == 0 ? 'Tidak ada penerima untuk target ini' : 'Terkirim ke $n relawan. Muncul di Notifikasi relawan.');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final events = org.myEvents(s, u.id).where((e) => org.metaOf(e).status != 'draft').toList();
    final history = org.messages.where((m) => m.ownerId == u.id).toList();
    final needsEvent = _kind != 'announcement';

    final compose = OrgSection(
      title: 'Kirim Pesan',
      icon: Icons.send_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in _kinds)
            ChoiceChip(
              avatar: Icon(k.$3, size: 16, color: _kind == k.$1 ? Colors.white : AppColors.primary),
              label: Text(k.$2),
              selected: _kind == k.$1,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: _kind == k.$1 ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12.5),
              onSelected: (_) => setState(() {
                _kind = k.$1;
                if (_kind != 'announcement' && _event == null && events.isNotEmpty) _event = events.first.id;
              }),
            ),
        ]),
        const SizedBox(height: 14),
        DropdownButtonFormField<String?>(
          value: events.any((e) => e.id == _event) ? _event : null,
          isExpanded: true,
          decoration: fieldDeco('Penerima', icon: Icons.groups_rounded),
          items: [
            if (!needsEvent) const DropdownMenuItem<String?>(value: null, child: Text('Seluruh relawan')),
            for (final e in events) DropdownMenuItem<String?>(value: e.id, child: Text('Peserta: ${e.title}', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _event = v),
        ),
        const SizedBox(height: 12),
        TextField(controller: _title, decoration: fieldDeco('Judul', icon: Icons.title_rounded)),
        const SizedBox(height: 12),
        TextField(controller: _body, minLines: 4, maxLines: 6, decoration: fieldDeco('Isi pesan', icon: Icons.notes_rounded)),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => _send(s, org, u.id), style: redBtn(), icon: const Icon(Icons.send_rounded, size: 17), label: const Text('Kirim'))),
      ]),
    );

    final hist = OrgSection(
      title: 'Riwayat Pesan (${history.length})',
      icon: Icons.history_rounded,
      child: history.isEmpty
          ? const EmptyBox(Icons.mark_chat_unread_outlined, 'Belum ada pesan terkirim')
          : Column(children: [
              for (final m in history)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8F8), border: Border.all(color: kOrgLine), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(_kinds.firstWhere((k) => k.$1 == m.kind, orElse: () => _kinds.first).$3, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    ]),
                    const SizedBox(height: 4),
                    Text(m.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('${fmtDateTime(m.createdAt)}  •  ${m.count} penerima${m.eventId == null ? ' (semua relawan)' : ''}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ]),
                ),
            ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHead('Komunikasi', 'Kirim pengumuman, pesan, pengingat, dan info perubahan jadwal'),
      LayoutBuilder(builder: (_, c) {
        if (c.maxWidth < 900) return Column(children: [compose, const SizedBox(height: 16), hist]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 5, child: compose), const SizedBox(width: 16), Expanded(flex: 5, child: hist)]);
      }),
    ]);
  }
}
