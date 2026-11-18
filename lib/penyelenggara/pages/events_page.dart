import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../widgets/common.dart';
import '../org_widgets.dart';
import '../organizer_shell.dart';
import '../organizer_store.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    OrgNav.createRequest.addListener(_onCreate);
    OrgNav.query.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onCreate());
  }

  @override
  void dispose() {
    OrgNav.createRequest.removeListener(_onCreate);
    OrgNav.query.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onCreate() {
    if (!mounted || !OrgNav.pendingCreate) return;
    OrgNav.pendingCreate = false;
    showEventForm(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final q = OrgNav.query.value.trim().toLowerCase();
    final all = org.myEvents(s, u.id);
    final list = all.where((e) {
      final st = org.statusOf(e);
      if (_filter == 'all' ? st == 'archived' : st != _filter) return false;
      if (q.isNotEmpty && !('${e.title} ${e.location} ${e.category}'.toLowerCase().contains(q))) return false;
      return true;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHead('Kelola Event', 'Buat, ubah, terbitkan, dan arsipkan kegiatan organisasimu', actions: [
        ElevatedButton.icon(onPressed: () => showEventForm(context, null), style: redBtn(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Tambah Event')),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in const ['all', 'draft', 'published', 'ongoing', 'completed', 'cancelled', 'archived'])
          ChoiceChip(
            label: Text(f == 'all' ? 'Semua (${all.where((e) => org.statusOf(e) != 'archived').length})' : '${kStatusLabel[f]} (${all.where((e) => org.statusOf(e) == f).length})'),
            selected: _filter == f,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: _filter == f ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12.5),
            onSelected: (_) => setState(() => _filter = f),
          ),
        if (q.isNotEmpty) ActionChip(avatar: const Icon(Icons.close, size: 16), label: Text('Pencarian: "$q"'), onPressed: () => OrgNav.query.value = ''),
      ]),
      const SizedBox(height: 14),
      if (list.isEmpty)
        const OrgCard(child: EmptyBox(Icons.event_busy_rounded, 'Belum ada event pada kategori ini'))
      else
        Grid([for (final e in list) _card(context, s, org, e)], minWidth: 300),
    ]);
  }

  Widget _card(BuildContext context, AppState s, OrgStore org, EventModel e) {
    final st = org.statusOf(e);
    final cat = categoryInfo(e.category);
    final n = s.participants(e);
    final hasRegs = org.activeRegsOf(s, e.id).isNotEmpty;
    return OrgCard(
      padding: EdgeInsets.zero,
      onTap: () => showEventDetail(context, e),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          EventImage(e, width: double.infinity, height: 140, radius: 20),
          Positioned(left: 10, top: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor(st), borderRadius: BorderRadius.circular(9)), child: Text(kStatusLabel[st] ?? st, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
          Positioned(
            right: 4, top: 4,
            child: PopupMenuButton<String>(
              icon: const CircleAvatar(radius: 15, backgroundColor: Colors.white, child: Icon(Icons.more_vert_rounded, size: 18, color: Colors.black87)),
              onSelected: (v) => _act(context, s, org, e, v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'detail', child: Text('Lihat detail')),
                if (st != 'completed' && st != 'cancelled' && st != 'archived') const PopupMenuItem(value: 'edit', child: Text('Edit event')),
                if (st == 'draft') const PopupMenuItem(value: 'publish', child: Text('Terbitkan')),
                if (st == 'published' || st == 'ongoing') const PopupMenuItem(value: 'cancel', child: Text('Batalkan event')),
                if (st == 'completed' || st == 'cancelled') const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
                if (st == 'archived') const PopupMenuItem(value: 'restore', child: Text('Pulihkan')),
                if (!hasRegs) const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: AppColors.danger))),
              ],
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: cat.color.withOpacity(.12), borderRadius: BorderRadius.circular(7)), child: Text(e.category, style: TextStyle(color: cat.color, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(height: 8),
            Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
            const SizedBox(height: 6),
            _line(Icons.calendar_today_outlined, '${fmtDate(e.date)} • ${e.time}'),
            _line(Icons.place_outlined, e.location),
            _line(Icons.payments_outlined, e.priceText),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: e.quota == 0 ? 0 : (n / e.quota).clamp(0.0, 1.0).toDouble(), minHeight: 8, color: AppColors.primary, backgroundColor: kOrgLine)),
            const SizedBox(height: 5),
            Text('$n / ${e.quota} relawan', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
          ]),
        ),
      ]),
    );
  }

  Widget _line(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(children: [Icon(i, size: 14, color: Colors.black45), const SizedBox(width: 6), Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)))]),
      );

  Future<void> _act(BuildContext context, AppState s, OrgStore org, EventModel e, String v) async {
    switch (v) {
      case 'detail':
        return showEventDetail(context, e);
      case 'edit':
        return showEventForm(context, e);
      case 'publish':
        org.saveEvent(s, e, org.metaOf(e), publish: true);
        return toast(context, 'Event diterbitkan dan tampil di aplikasi relawan');
      case 'archive':
        final er = org.setArchived(s, e, true);
        return toast(context, er ?? 'Event diarsipkan');
      case 'restore':
        org.setArchived(s, e, false);
        return toast(context, 'Event dipulihkan');
      case 'cancel':
        if (await _confirm(context, 'Batalkan event?', 'Relawan yang sudah mendaftar akan mendapat notifikasi pembatalan. Tindakan ini tidak dapat diurungkan.')) {
          org.cancelEvent(s, e);
          if (context.mounted) toast(context, 'Event dibatalkan, relawan diberi notifikasi');
        }
        return;
      case 'delete':
        if (await _confirm(context, 'Hapus event?', '"${e.title}" akan dihapus permanen.')) {
          final er = org.deleteEvent(s, e);
          if (context.mounted) toast(context, er ?? 'Event dihapus');
        }
        return;
    }
  }
}

Future<bool> _confirm(BuildContext c, String t, String m) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (d) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(m),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Kembali')), ElevatedButton(style: redBtn(small: true), onPressed: () => Navigator.pop(d, true), child: const Text('Ya, lanjutkan'))],
    ),
  );
  return r ?? false;
}

// ============================================================== DETAIL
void showEventDetail(BuildContext context, EventModel e) {
  showDialog(
    context: context,
    builder: (dc) {
      final s = dc.watch<AppState>();
      final org = dc.watch<OrgStore>();
      final m = org.metaOf(e);
      final st = org.statusOf(e);
      final regs = org.regsFor(s, [e.id]);
      int c(String x) => regs.where((r) => org.regState(s, r) == x).length;
      Widget row(String k, String v) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.black54, fontSize: 12.5))), Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))]),
          );
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EventImage(e, width: double.infinity, height: 190, radius: 24),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(e.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))), StatusPill(kStatusLabel[st] ?? st, statusColor(st))]),
                  const SizedBox(height: 10),
                  Text(e.description, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                  const Divider(height: 26),
                  row('Kategori', e.category),
                  row('Lokasi', e.location),
                  row('Tanggal', fmtDate(e.date)),
                  row('Waktu', e.time),
                  row('Deadline', m.deadline == null ? '' : fmtDate(m.deadline!)),
                  row('Kuota', '${s.participants(e)} / ${e.quota} relawan'),
                  row('Biaya', e.priceText),
                  row('Persetujuan', m.requireApproval ? 'Perlu persetujuan penyelenggara' : 'Otomatis diterima'),
                  row('Persyaratan', m.requirements),
                  row('Kontak', m.contact),
                  row('Tugas', e.tasks.join(', ')),
                  const Divider(height: 26),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    StatusPill('Pending ${c('pending')}', statusColor('pending')),
                    StatusPill('Diterima ${c('accepted')}', statusColor('accepted')),
                    StatusPill('Hadir ${c('completed')}', statusColor('completed')),
                    StatusPill('Ditolak ${c('rejected')}', statusColor('rejected')),
                  ]),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Tutup'))),
                ]),
              ),
            ]),
          ),
        ),
      );
    },
  );
}

// ================================================================ FORM
void showEventForm(BuildContext context, EventModel? e) {
  showDialog(context: context, barrierDismissible: false, builder: (_) => _EventForm(parent: context, event: e));
}

class _EventForm extends StatefulWidget {
  final BuildContext parent;
  final EventModel? event;
  const _EventForm({required this.parent, this.event});
  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _desc, _loc, _quota, _price, _req, _contact, _tasks, _pts, _hrs, _imp;
  String _cat = kCategories.first.name, _poster = '';
  DateTime? _date, _deadline;
  TimeOfDay _t1 = const TimeOfDay(hour: 8, minute: 0), _t2 = const TimeOfDay(hour: 12, minute: 0);
  bool _free = true, _approval = true;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final org = OrgStore.instance;
    final m = e == null ? null : org.metaOf(e);
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _loc = TextEditingController(text: e?.location ?? '');
    _quota = TextEditingController(text: '${e?.quota ?? 50}');
    _price = TextEditingController(text: (e != null && e.price > 0) ? '${e.price}' : '');
    _req = TextEditingController(text: m?.requirements ?? '');
    _contact = TextEditingController(text: m?.contact ?? '');
    _tasks = TextEditingController(text: e?.tasks.join('\n') ?? '');
    _pts = TextEditingController(text: '${e?.points ?? 100}');
    _hrs = TextEditingController(text: '${e?.hours ?? 4}');
    _imp = TextEditingController(text: '${e?.impact ?? 100}');
    if (e != null) {
      _cat = e.category;
      _poster = e.image;
      _date = e.date;
      _deadline = m?.deadline;
      _free = e.price == 0;
      _approval = m?.requireApproval ?? false;
      final t = RegExp(r'(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})').firstMatch(e.time);
      if (t != null) {
        _t1 = TimeOfDay(hour: int.parse(t.group(1)!), minute: int.parse(t.group(2)!));
        _t2 = TimeOfDay(hour: int.parse(t.group(3)!), minute: int.parse(t.group(4)!));
      }
    } else {
      _approval = org.defaultApproval;
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _loc, _quota, _price, _req, _contact, _tasks, _pts, _hrs, _imp]) {
      c.dispose();
    }
    super.dispose();
  }

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickPoster() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 70);
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() => _poster = 'data:image/jpeg;base64,${base64Encode(b)}');
    } catch (_) {
      if (mounted) toast(context, 'Gagal memilih gambar');
    }
  }

  Future<void> _pickDate(bool deadline) async {
    final now = DateTime.now();
    final init = (deadline ? _deadline : _date) ?? now;
    final d = await showDatePicker(context: context, initialDate: init.isBefore(now) ? now : init, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 5));
    if (d != null) setState(() => deadline ? _deadline = d : _date = d);
  }

  void _submit(bool publish) {
    final s = widget.parent.read<AppState>();
    final org = OrgStore.instance;
    if (!_key.currentState!.validate()) return;
    if (_date == null) return toast(context, 'Tanggal pelaksanaan wajib diisi');
    if (publish && _deadline != null && _deadline!.isAfter(_date!)) return toast(context, 'Deadline pendaftaran harus sebelum tanggal kegiatan');
    final old = widget.event;
    final quota = int.tryParse(_quota.text) ?? 0;
    if (old != null && quota < s.participants(old)) return toast(context, 'Kuota tidak boleh lebih kecil dari jumlah relawan saat ini (${s.participants(old)})');
    final u = s.user!;
    final prof = org.profileOf(u);
    final tasks = _tasks.text.split('\n').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    final ev = EventModel(
      id: old?.id ?? 'org_${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _cat,
      organizer: prof.name.isEmpty ? u.name : prof.name,
      location: _loc.text.trim(),
      description: _desc.text.trim().isEmpty ? 'Kegiatan ${_cat.toLowerCase()} bersama relawan.' : _desc.text.trim(),
      image: _poster,
      time: '${_hhmm(_t1)} - ${_hhmm(_t2)} WIB',
      date: _date!,
      quota: quota,
      baseParticipants: old?.baseParticipants ?? 0,
      points: int.tryParse(_pts.text) ?? 100,
      hours: int.tryParse(_hrs.text) ?? 4,
      impact: int.tryParse(_imp.text) ?? 100,
      tasks: tasks.isEmpty ? ['Membantu pelaksanaan kegiatan'] : tasks,
      price: _free ? 0 : (int.tryParse(_price.text) ?? 0),
    );
    final meta = old == null ? EventMeta(ownerId: u.id) : org.metaOf(old);
    meta
      ..ownerId = old == null ? u.id : org.ownerOf(old)
      ..deadline = _deadline
      ..requirements = _req.text.trim()
      ..contact = _contact.text.trim()
      ..requireApproval = _approval;
    org.saveEvent(s, ev, meta, publish: publish);
    Navigator.pop(context);
    toast(widget.parent, publish ? 'Event diterbitkan dan tampil di Cari Event relawan' : 'Event disimpan sebagai draft');
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.event != null;
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
    String? num_(String? v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Isi angka > 0' : null;

    Widget field(TextEditingController c, String l, {IconData? i, int lines = 1, String? Function(String?)? v, TextInputType? k, String? hint}) =>
        TextFormField(controller: c, minLines: lines, maxLines: lines, validator: v, keyboardType: k, decoration: fieldDeco(l, icon: i, hint: hint));

    Widget picker(String l, String v, IconData i, VoidCallback f) => InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: f,
          child: InputDecorator(decoration: fieldDeco(l, icon: i), child: Text(v, style: TextStyle(fontSize: 14, color: v.startsWith('Pilih') ? Colors.black45 : Colors.black87))),
        );

    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 760),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 12, 6),
            child: Row(children: [
              const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(editing ? 'Edit Event' : 'Tambah Event Baru', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _key,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Poster
                  GestureDetector(
                    onTap: _pickPoster,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(18), border: Border.all(color: kOrgLine)),
                      child: _poster.isEmpty
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 34, color: AppColors.primary), SizedBox(height: 6), Text('Upload poster kegiatan', style: TextStyle(fontWeight: FontWeight.w700)), Text('JPG/PNG, otomatis dikompres', style: TextStyle(fontSize: 11.5, color: Colors.black45))])
                          : Stack(fit: StackFit.expand, children: [
                              dataImage(_poster) != null ? Image(image: dataImage(_poster)!, fit: BoxFit.cover) : Image.asset(_poster, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                              Positioned(right: 8, bottom: 8, child: ElevatedButton.icon(onPressed: _pickPoster, style: softBtn(small: true), icon: const Icon(Icons.swap_horiz, size: 16), label: const Text('Ganti'))),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  field(_title, 'Nama event', i: Icons.title_rounded, v: req),
                  const SizedBox(height: 12),
                  const Text('Kategori', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final k in kCategories)
                      ChoiceChip(
                        avatar: Icon(k.icon, size: 16, color: _cat == k.name ? Colors.white : k.color),
                        label: Text(k.name),
                        selected: _cat == k.name,
                        selectedColor: k.color,
                        labelStyle: TextStyle(color: _cat == k.name ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                        onSelected: (_) => setState(() => _cat = k.name),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  field(_desc, 'Deskripsi kegiatan', i: Icons.notes_rounded, lines: 3),
                  const SizedBox(height: 12),
                  field(_loc, 'Lokasi kegiatan', i: Icons.place_outlined, v: req),
                  const SizedBox(height: 12),
                  Grid([
                    picker('Tanggal pelaksanaan', _date == null ? 'Pilih tanggal' : fmtDate(_date!), Icons.calendar_today_outlined, () => _pickDate(false)),
                    picker('Deadline pendaftaran', _deadline == null ? 'Pilih tanggal' : fmtDate(_deadline!), Icons.event_busy_outlined, () => _pickDate(true)),
                    picker('Waktu mulai', _hhmm(_t1), Icons.schedule_rounded, () async {
                      final t = await showTimePicker(context: context, initialTime: _t1);
                      if (t != null) setState(() => _t1 = t);
                    }),
                    picker('Waktu selesai', _hhmm(_t2), Icons.schedule_rounded, () async {
                      final t = await showTimePicker(context: context, initialTime: _t2);
                      if (t != null) setState(() => _t2 = t);
                    }),
                  ], minWidth: 240, gap: 12),
                  const SizedBox(height: 12),
                  Grid([
                    field(_quota, 'Kuota relawan', i: Icons.groups_outlined, v: num_, k: TextInputType.number),
                    Row(children: [
                      Expanded(child: SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Gratis')), ButtonSegment(value: false, label: Text('Berbayar'))], selected: {_free}, onSelectionChanged: (v) => setState(() => _free = v.first))),
                    ]),
                  ], minWidth: 240, gap: 12),
                  if (!_free) ...[
                    const SizedBox(height: 12),
                    field(_price, 'Biaya pendaftaran (Rp)', i: Icons.payments_outlined, k: TextInputType.number, v: num_),
                  ],
                  const SizedBox(height: 12),
                  field(_req, 'Persyaratan peserta', i: Icons.rule_rounded, lines: 2, hint: 'Contoh: usia min. 17 tahun, membawa tumbler'),
                  const SizedBox(height: 12),
                  field(_contact, 'Kontak penyelenggara', i: Icons.phone_outlined, hint: 'No. WhatsApp / email'),
                  const SizedBox(height: 12),
                  field(_tasks, 'Tugas relawan (satu per baris)', i: Icons.checklist_rounded, lines: 3),
                  const SizedBox(height: 12),
                  Grid([
                    field(_pts, 'Poin', i: Icons.stars_rounded, k: TextInputType.number),
                    field(_hrs, 'Durasi (jam)', i: Icons.timer_outlined, k: TextInputType.number),
                    field(_imp, 'Estimasi dampak (orang)', i: Icons.favorite_border_rounded, k: TextInputType.number),
                  ], minWidth: 180, gap: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: const Text('Perlu persetujuan penyelenggara', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Jika aktif, pendaftar berstatus Pending sampai kamu menerima/menolak.', style: TextStyle(fontSize: 12)),
                    value: _approval,
                    onChanged: (v) => setState(() => _approval = v),
                  ),
                ]),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 8, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              if (!editing || _orgIsDraft(widget.event!)) ElevatedButton(onPressed: () => _submit(false), style: softBtn(), child: const Text('Simpan Draft')),
              ElevatedButton(onPressed: () => _submit(true), style: redBtn(), child: Text(editing && !_orgIsDraft(widget.event!) ? 'Simpan Perubahan' : 'Terbitkan')),
            ]),
          ),
        ]),
      ),
    );
  }

  bool _orgIsDraft(EventModel e) => OrgStore.instance.metaOf(e).status == 'draft';
}