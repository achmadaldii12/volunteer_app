import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/community.dart';
import '../../providers/app_state.dart';
import '../../providers/community_logic.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';
import '../../screens/organizer_profile_screen.dart' show OrganizerInbox, OrgContactMsg; // BARU: pesan dari relawan
import '../../providers/activity_store.dart' show ActivityStore, ComplaintEntry; // BARU: laporan kendala

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
  String _cpFilter = 'all'; // BARU: filter laporan kendala (all | sent | processing | done)
  // ---- Komunitas relawan ----
  final _commTitle = TextEditingController(), _commBody = TextEditingController();
  String _room = 'umum';
  bool _official = false, _important = false;

  @override
  void initState() {
    super.initState();
    OrganizerInbox.instance.load(); // BARU: muat pesan dari relawan
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _commTitle.dispose();
    _commBody.dispose();
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

  /// Mengirim pesan ke ruang Komunitas relawan, atau membuat pengumuman resmi Komunitas.
  void _sendComm(AppState s) {
    final body = _commBody.text.trim();
    if (body.isEmpty) return toast(context, 'Isi pesan wajib diisi');
    String? err;
    if (_official) {
      if (_commTitle.text.trim().isEmpty) return toast(context, 'Judul pengumuman wajib diisi');
      s.commAdmins.add(s.user!.id); // penyelenggara berhak membuat pengumuman resmi
      err = s.createAnnouncement(title: _commTitle.text, body: body, important: _important);
    } else {
      err = s.sendRoomMessage(roomId: _room, text: body);
    }
    if (err != null) return toast(context, err);
    _commTitle.clear();
    _commBody.clear();
    toast(context, _official ? 'Pengumuman resmi terkirim ke Komunitas relawan.' : 'Pesan terkirim ke ruang ${roomById(_room).name}.');
  }

  // ------------------------------------------------ BARU: laporan kendala relawan
  Color _cpColor(String x) =>
      x == 'done' ? AppColors.success : (x == 'processing' ? AppColors.warning : const Color(0xFF2563EB));
  String _cpText(String x) => x == 'done' ? 'Selesai' : (x == 'processing' ? 'Diproses' : 'Baru');

  void _cpSet(AppState s, ActivityStore st, ComplaintEntry en, String status) {
    final ok = st.setComplaintStatus(en.userId, en.complaint.id, status);
    if (!ok) return toast(context, 'Laporan tidak ditemukan');
    final cp = en.complaint;
    final ev = cp.eventId.isEmpty ? '' : ' (${s.eventById(cp.eventId)?.title ?? 'kegiatan'})';
    s.orgReplyToVolunteer(
      en.userId,
      status == 'done' ? 'Laporan kendalamu sudah selesai ditangani' : 'Laporan kendalamu sedang diproses',
      'Laporan "${cp.category}"$ev kini berstatus ${_cpText(status)}.',
    );
    toast(context, 'Status laporan diubah menjadi ${_cpText(status)}. Relawan mendapat notifikasi.');
  }

  Widget _complaintTile(AppState s, ActivityStore st, ComplaintEntry en) {
    final cp = en.complaint;
    final who = s.userById(en.userId)?.name ?? 'Relawan';
    final ev = cp.eventId.isEmpty ? 'Umum (tanpa kegiatan)' : (s.eventById(cp.eventId)?.title ?? 'Kegiatan');
    final col = _cpColor(cp.status);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cp.status == 'sent' ? const Color(0xFFFFEDED) : const Color(0xFFFFF8F8),
        border: Border.all(color: cp.status == 'sent' ? AppColors.primary.withAlpha(120) : kOrgLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(cp.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: col.withAlpha(30), borderRadius: BorderRadius.circular(10)),
            child: Text(_cpText(cp.status), style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 3),
        Text('Pelapor: $who  •  $ev', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        Text(fmtDateTime(cp.createdAt), style: const TextStyle(fontSize: 11, color: Colors.black45)),
        const SizedBox(height: 8),
        Text(cp.description, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
        if (cp.status != 'done') ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.end, children: [
            if (cp.status == 'sent')
              OutlinedButton.icon(
                onPressed: () => _cpSet(s, st, en, 'processing'),
                icon: const Icon(Icons.hourglass_top_rounded, size: 16),
                label: const Text('Tandai Diproses'),
              ),
            ElevatedButton.icon(
              style: redBtn(small: true),
              onPressed: () => _cpSet(s, st, en, 'done'),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Tandai Selesai'),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _complaintSection(AppState s, ActivityStore st, Set<String> eventIds) {
    const filters = <(String, String)>[
      ('all', 'Semua'),
      ('sent', 'Baru'),
      ('processing', 'Diproses'),
      ('done', 'Selesai'),
    ];
    final ids = s.users.where((u) => u.role != kOrgRole).map((u) => u.id);
    // laporan untuk kegiatan milik penyelenggara ini + laporan umum
    final all = st
        .complaintsOf(ids)
        .where((en) => en.complaint.eventId.isEmpty || eventIds.contains(en.complaint.eventId))
        .toList();
    final shown = _cpFilter == 'all' ? all : all.where((en) => en.complaint.status == _cpFilter).toList();
    final fresh = all.where((en) => en.complaint.status == 'sent').length;

    return OrgSection(
      title: fresh > 0 ? 'Laporan Kendala Relawan ($fresh baru)' : 'Laporan Kendala Relawan (${all.length})',
      icon: Icons.report_problem_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in filters)
            ChoiceChip(
              label: Text(f.$2),
              selected: _cpFilter == f.$1,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: _cpFilter == f.$1 ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12.5),
              onSelected: (_) => setState(() => _cpFilter = f.$1),
            ),
        ]),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          const EmptyBox(Icons.inbox_outlined, 'Belum ada laporan kendala')
        else
          for (final en in shown) _complaintTile(s, st, en),
      ]),
    );
  }

  // ---------------------------------------------------- BARU: pesan dari relawan
  Future<void> _reply(AppState s, OrgContactMsg m) async {
    final who = s.userById(m.userId)?.name ?? 'Relawan';
    final c = TextEditingController(text: m.reply);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Balas $who'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: c,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            decoration: fieldDeco('Balasan', icon: Icons.reply_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: redBtn(small: true),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Kirim Balasan'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    final err = s.orgReplyToVolunteer(m.userId, 'Balasan dari ${m.org}', text);
    if (err != null) {
      if (mounted) toast(context, err);
      return;
    }
    await OrganizerInbox.instance.reply(m.id, text);
    if (!mounted) return;
    toast(context, 'Balasan terkirim. Muncul di Notifikasi relawan.');
  }

  Widget _inboxTile(AppState s, OrgContactMsg m) {
    final who = s.userById(m.userId)?.name ?? 'Relawan';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: m.read ? const Color(0xFFFFF8F8) : const Color(0xFFFFEDED),
        border: Border.all(color: m.read ? kOrgLine : AppColors.primary.withAlpha(120)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary.withAlpha(30),
            child: Text(who.trim().isEmpty ? '?' : who.trim()[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(who, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              Text('${m.subject}  •  untuk ${m.org}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
            ]),
          ),
          if (!m.read)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Text('Baru', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
        ]),
        if (m.eventTitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Terkait kegiatan: ${m.eventTitle}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 6),
        Text(m.body, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
        const SizedBox(height: 6),
        Text(fmtDateTime(m.createdAt), style: const TextStyle(fontSize: 11, color: Colors.black45)),
        if (m.reply.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kOrgLine)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Balasanmu', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(m.reply, style: const TextStyle(fontSize: 12.5, height: 1.35)),
            ]),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.end, children: [
          if (!m.read)
            TextButton.icon(
              onPressed: () => OrganizerInbox.instance.markRead(m.id),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Tandai dibaca'),
            ),
          ElevatedButton.icon(
            style: redBtn(small: true),
            onPressed: () => _reply(s, m),
            icon: const Icon(Icons.reply_rounded, size: 16),
            label: Text(m.reply.isEmpty ? 'Balas' : 'Balas Lagi'),
          ),
        ]),
      ]),
    );
  }

  Widget _inbox(AppState s, Set<String> names) {
    return AnimatedBuilder(
      animation: OrganizerInbox.instance,
      builder: (context, _) {
        final list = OrganizerInbox.instance.forOrganizer(names);
        final unread = list.where((m) => !m.read).length;
        return OrgSection(
          title: unread > 0 ? 'Pesan dari Relawan ($unread baru)' : 'Pesan dari Relawan (${list.length})',
          icon: Icons.mark_email_unread_rounded,
          child: list.isEmpty
              ? const EmptyBox(Icons.inbox_outlined, 'Belum ada pesan dari relawan')
              : Column(children: [for (final m in list) _inboxTile(s, m)]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final st = context.watch<ActivityStore>(); // BARU: laporan kendala
    final events = org.myEvents(s, u.id).where((e) => org.metaOf(e).status != 'draft').toList();
    final history = org.messages.where((m) => m.ownerId == u.id).toList();
    final needsEvent = _kind != 'announcement';

    // BARU: nama penyelenggara yang pesannya masuk ke akun ini
    final names = <String>{
      org.profileOf(u).name.trim().toLowerCase(),
      ...org.myEvents(s, u.id).map((e) => e.organizer.trim().toLowerCase()),
    };
    final inbox = _inbox(s, names);
    final complaints = _complaintSection(s, st, org.myEvents(s, u.id).map((e) => e.id).toSet());

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

    final comm = OrgSection(
      title: 'Kirim ke Komunitas Relawan',
      icon: Icons.forum_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: const Text('Jadikan pengumuman resmi', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          subtitle: const Text('Tampil di tab Pengumuman Komunitas & notifikasi relawan', style: TextStyle(fontSize: 11.5)),
          value: _official,
          onChanged: (v) => setState(() => _official = v),
        ),
        if (!_official)
          DropdownButtonFormField<String>(
            value: _room,
            isExpanded: true,
            decoration: fieldDeco('Ruang diskusi', icon: Icons.groups_rounded),
            items: [for (final r in kRooms) DropdownMenuItem<String>(value: r.id, child: Text(r.name))],
            onChanged: (v) => setState(() => _room = v ?? 'umum'),
          ),
        if (_official) ...[
          TextField(controller: _commTitle, decoration: fieldDeco('Judul pengumuman', icon: Icons.title_rounded)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text('Tandai penting', style: TextStyle(fontSize: 13)),
            value: _important,
            onChanged: (v) => setState(() => _important = v),
          ),
        ],
        const SizedBox(height: 12),
        TextField(controller: _commBody, minLines: 3, maxLines: 6, decoration: fieldDeco(_official ? 'Isi pengumuman' : 'Pesan', icon: Icons.notes_rounded)),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: () => _sendComm(s), style: redBtn(), icon: const Icon(Icons.send_rounded, size: 17), label: const Text('Kirim ke Komunitas'))),
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
        if (c.maxWidth < 900) return Column(children: [inbox, const SizedBox(height: 16), complaints, const SizedBox(height: 16), compose, const SizedBox(height: 16), comm, const SizedBox(height: 16), hist]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 5, child: Column(children: [compose, const SizedBox(height: 16), comm])), const SizedBox(width: 16), Expanded(flex: 5, child: Column(children: [inbox, const SizedBox(height: 16), complaints, const SizedBox(height: 16), hist]))]);
      }),
    ]);
  }
}