import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../data/leaderboard_seed.dart';
import '../models/models.dart';
import '../providers/activity_store.dart';
import '../providers/app_state.dart';
import '../providers/community_logic.dart';
import '../providers/profile_store.dart';
import '../widgets/common.dart';
import 'activity_pages.dart';
import 'profile_pages.dart';

// ============================================================
// E. PENGINGAT KEGIATAN
// ============================================================
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _demoRegId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runReminders(context.read<AppState>(), context.read<ActivityStore>());
    });
  }

  void _notify(AppState s, String uid, String title, String body) {
    s.notifs.insert(
      0,
      Notif(id: s.newId('n'), userId: uid, title: title, body: body, kind: 'register', createdAt: DateTime.now()),
    );
    s.commitCommunity();
  }

  Future<void> _simulateChange(AppState s, Registration r) async {
    final e = s.eventById(r.eventId);
    final u = s.user;
    if (e == null || u == null) return;
    final ok = await confirmAct(context, 'Simulasi perubahan jadwal',
        'Notifikasi perubahan jadwal dari panitia akan dikirim (simulasi). Jadwal asli event tidak diubah.',
        yes: 'Kirim');
    if (!ok || !mounted) return;
    final w = s.eventWindow(e);
    _notify(s, u.id, 'Perubahan jadwal kegiatan',
        'Panitia mengubah waktu mulai ${e.title} menjadi pukul ${actHm(w.start.add(const Duration(hours: 1)))} (simulasi).');
    pSnack(context, 'Notifikasi perubahan jadwal terkirim');
  }

  Future<void> _simulateCancel(AppState s, Registration r) async {
    final e = s.eventById(r.eventId);
    final u = s.user;
    if (e == null || u == null) return;
    final ok = await confirmAct(context, 'Simulasi pembatalan oleh penyelenggara',
        'Pendaftaranmu untuk ${e.title} akan dibatalkan oleh penyelenggara (simulasi).',
        yes: 'Batalkan', danger: true);
    if (!ok || !mounted) return;
    r.status = RegStatus.cancelled;
    _notify(s, u.id, 'Pendaftaran dibatalkan penyelenggara',
        'Penyelenggara membatalkan pendaftaranmu untuk ${e.title}. Silakan pilih kegiatan lain.');
    setState(() => _demoRegId = '');
    pSnack(context, 'Pendaftaran dibatalkan oleh penyelenggara (simulasi)');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final regs = s.myRegs.where((r) => r.status == RegStatus.registered).toList();
    regs.sort((a, b) {
      final ea = s.eventById(a.eventId);
      final eb = s.eventById(b.eventId);
      if (ea == null || eb == null) return 0;
      return s.eventWindow(ea).start.compareTo(s.eventWindow(eb).start);
    });
    final demoReg = regs.where((r) => r.id == _demoRegId).isEmpty ? null : regs.firstWhere((r) => r.id == _demoRegId);

    Widget toggle(String key, IconData icon, String title, String sub) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: kActPink, shape: BoxShape.circle),
              child: Icon(icon, color: kActRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(sub, style: TextStyle(fontSize: 11, color: muted(context))),
              ]),
            ),
            Switch(
              value: st.remindOn(u.id, key),
              activeColor: kActRed,
              onChanged: (v) => st.setRemind(u.id, key, v),
            ),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat Kegiatan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.event_available, 'Jadwal Kegiatan Terdekat'),
                  const SizedBox(height: 12),
                  if (regs.isEmpty)
                    Text('Belum ada kegiatan yang kamu ikuti.', style: TextStyle(color: muted(context), fontSize: 13)),
                  for (final r in regs)
                    Builder(builder: (_) {
                      final e = s.eventById(r.eventId);
                      if (e == null) return const SizedBox.shrink();
                      final w = s.eventWindow(e);
                      final on = st.remindEvent(u.id, r.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: softOf(context), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 3),
                              Text('${actDate(e.date)} • ${actHm(w.start)} - ${actHm(w.end)}',
                                  style: TextStyle(fontSize: 11, color: muted(context))),
                              const SizedBox(height: 5),
                              StatusPill(s.startsInText(e), kActRed, icon: Icons.schedule),
                            ]),
                          ),
                          IconButton(
                            tooltip: on ? 'Matikan pengingat' : 'Aktifkan pengingat',
                            icon: Icon(on ? Icons.notifications_active : Icons.notifications_off_outlined,
                                color: on ? kActRed : Colors.grey),
                            onPressed: () {
                              st.setRemindEvent(u.id, r.id, !on);
                              pSnack(context, on ? 'Pengingat dimatikan' : 'Pengingat diaktifkan');
                            },
                          ),
                        ]),
                      );
                    }),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.tune, 'Pengaturan Pengingat'),
                  const SizedBox(height: 8),
                  toggle('h3', Icons.looks_3_outlined, 'Pengingat H-3', '3 hari sebelum kegiatan'),
                  toggle('h1', Icons.looks_one_outlined, 'Pengingat H-1', '1 hari sebelum kegiatan'),
                  toggle('start', Icons.alarm, 'Jam dimulainya event', '1 jam sebelum kegiatan dimulai'),
                  toggle('change', Icons.update, 'Perubahan jadwal & pembatalan', 'Info dari panitia / penyelenggara'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: actOutlineStyle(),
                      icon: const Icon(Icons.notifications_none, size: 18),
                      label: const Text('Cek Pengingat Sekarang'),
                      onPressed: () {
                        runReminders(s, st);
                        pSnack(context, 'Pengingat diperiksa. Pengingat yang sudah waktunya masuk ke Notifikasi.');
                      },
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                color: kActPink,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.science_outlined, 'Simulasi Panitia (demo)'),
                  const SizedBox(height: 6),
                  Text(
                    'Karena belum ada server, perubahan jadwal dan pembatalan dari penyelenggara disimulasikan di sini.',
                    style: TextStyle(fontSize: 11.5, color: muted(context), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  actDropdown(
                    label: 'Pilih kegiatan',
                    icon: Icons.event,
                    value: demoReg == null ? '' : demoReg.id,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Pilih kegiatan')),
                      for (final r in regs)
                        DropdownMenuItem(
                          value: r.id,
                          child: Text(s.eventById(r.eventId)?.title ?? 'Event', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _demoRegId = v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(
                      style: actOutlineStyle(),
                      onPressed: demoReg == null ? null : () => _simulateChange(s, demoReg),
                      child: const Text('Ubah Jadwal'),
                    ),
                    ElevatedButton(
                      style: actFilledStyle(),
                      onPressed: demoReg == null ? null : () => _simulateCancel(s, demoReg),
                      child: const Text('Batalkan oleh Penyelenggara'),
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
// H. RIWAYAT KEHADIRAN
// ============================================================
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final items = <(Registration, EventModel, AttendanceInfo)>[];
    for (final r in s.myRegs) {
      final e = s.eventById(r.eventId);
      if (e == null) continue;
      items.add((r, e, s.attendanceInfo(st, r, e)));
    }
    var hadir = 0;
    var dur = Duration.zero;
    for (final it in items) {
      if (it.$3.status == 'Hadir') {
        hadir++;
        dur += it.$3.duration ?? Duration.zero;
      }
    }
    final list = items.where((it) => _filter == 'Semua' || it.$3.status == _filter).toList();

    Color color(String x) => x == 'Hadir' ? AppColors.success : (x == 'Tidak Hadir' ? Colors.grey : AppColors.warning);

    Widget chip(String l) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(l),
            selected: _filter == l,
            selectedColor: kActRed,
            showCheckmark: false,
            labelStyle: TextStyle(color: _filter == l ? Colors.white : null, fontSize: 12),
            onSelected: (_) => setState(() => _filter = l),
          ),
        );

    Widget line(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(icon, size: 14, color: muted(context)),
            const SizedBox(width: 6),
            Text('$label: ', style: TextStyle(fontSize: 11.5, color: muted(context))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Kehadiran')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(children: [
              PCard(
                child: Row(children: [
                  Expanded(
                    child: Column(children: [
                      Text('$hadir', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kActRed)),
                      Text('Kali hadir', style: TextStyle(fontSize: 11, color: muted(context))),
                    ]),
                  ),
                  Expanded(
                    child: Column(children: [
                      Text(actDuration(dur),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kActRed)),
                      Text('Total durasi kontribusi', style: TextStyle(fontSize: 11, color: muted(context))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(children: [chip('Semua'), chip('Hadir'), chip('Menunggu Verifikasi'), chip('Tidak Hadir')]),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const EmptyState(Icons.how_to_reg_outlined, 'Belum ada data kehadiran',
                    'Daftar kegiatan dan hadiri untuk melihat riwayat kehadiranmu.')
              else
                for (final it in list)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text(it.$2.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                        ),
                        StatusPill(it.$3.status, color(it.$3.status)),
                      ]),
                      const SizedBox(height: 6),
                      line(Icons.event, 'Tanggal', actDate(it.$3.date)),
                      line(Icons.login, 'Check-in', it.$3.checkIn == null ? '-' : '${actHm(it.$3.checkIn!)} WIB'),
                      line(Icons.logout, 'Check-out', it.$3.checkOut == null ? '-' : '${actHm(it.$3.checkOut!)} WIB'),
                      line(Icons.timer_outlined, 'Durasi kontribusi',
                          it.$3.duration == null ? '-' : actDuration(it.$3.duration!)),
                      line(Icons.verified_outlined, 'Verifikasi', it.$3.verification),
                      if (it.$3.verifiedAt != null)
                        line(Icons.schedule, 'Diverifikasi pada', fmtDateTime(it.$3.verifiedAt!)),
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
// I. PENGADUAN DAN KENDALA
// ============================================================
class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  void _form(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: kPSheetShape,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _ComplaintForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final list = st.complaints(u.id);

    Color color(String x) => x == 'done' ? AppColors.success : (x == 'processing' ? AppColors.warning : const Color(0xFF2563EB));
    String text(String x) => x == 'done' ? 'Selesai' : (x == 'processing' ? 'Diproses' : 'Terkirim');

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaduan & Kendala')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kActRed,
        foregroundColor: Colors.white,
        onPressed: () => _form(context),
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Buat Laporan'),
      ),
      body: list.isEmpty
          ? const EmptyState(Icons.support_agent, 'Belum ada laporan',
              'Laporkan kendala yang kamu alami selama mengikuti kegiatan.')
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    for (final c in list)
                      PCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(c.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            ),
                            StatusPill(text(c.status), color(c.status)),
                          ]),
                          const SizedBox(height: 3),
                          Text(
                            '${c.eventId.isEmpty ? 'Umum' : (s.eventById(c.eventId)?.title ?? 'Kegiatan')} • ${fmtDateTime(c.createdAt)}',
                            style: TextStyle(fontSize: 11, color: muted(context)),
                          ),
                          const SizedBox(height: 8),
                          Text(c.description, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                          if (c.status != 'done') ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: actOutlineStyle(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                              icon: const Icon(Icons.fast_forward, size: 16),
                              label: const Text('Simulasikan tindak lanjut admin (demo)'),
                              onPressed: () {
                                st.advanceComplaint(u.id, c.id);
                                pSnack(context, 'Status laporan diperbarui');
                              },
                            ),
                          ],
                        ]),
                      ),
                    Text(
                      'Laporan tersimpan di perangkat. Agar diterima admin, aplikasi memerlukan endpoint backend '
                      '(contoh POST /support/complaints).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: muted(context), height: 1.4),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }
}

class _ComplaintForm extends StatefulWidget {
  const _ComplaintForm();

  @override
  State<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<_ComplaintForm> {
  String _category = '';
  String _eventId = '';
  final _desc = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    final err = st.addComplaint(u.id, eventId: _eventId, category: _category, description: _desc.text);
    if (err != null) {
      pSnack(context, err);
      return;
    }
    Navigator.pop(context);
    pSnack(context, 'Laporan terkirim. Status: Terkirim');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    final seen = <String>{};
    final events = <EventModel>[];
    if (u != null) {
      for (final r in s.myRegs) {
        final e = s.eventById(r.eventId);
        if (e != null && seen.add(e.id)) events.add(e);
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Buat Laporan Kendala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        actDropdown(
          label: 'Kategori masalah',
          icon: Icons.category_outlined,
          value: _category,
          items: [
            const DropdownMenuItem(value: '', child: Text('Pilih kategori')),
            for (final c in kComplaintCategories) DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _category = v ?? ''),
        ),
        const SizedBox(height: 12),
        actDropdown(
          label: 'Kegiatan terkait (opsional)',
          icon: Icons.event,
          value: _eventId,
          items: [
            const DropdownMenuItem(value: '', child: Text('Tidak terkait kegiatan tertentu')),
            for (final e in events) DropdownMenuItem(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _eventId = v ?? ''),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _desc,
          minLines: 4,
          maxLines: 6,
          maxLength: 500,
          decoration: pInput('Deskripsi kendala', Icons.edit_note),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: actFilledStyle(),
            onPressed: _send,
            icon: const Icon(Icons.send),
            label: const Text('Kirim Laporan'),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// J. APRESIASI RELAWAN
// ============================================================
class AppreciationScreen extends StatefulWidget {
  const AppreciationScreen({super.key});

  @override
  State<AppreciationScreen> createState() => _AppreciationScreenState();
}

class _AppreciationScreenState extends State<AppreciationScreen> {
  bool _received = true;

  void _form() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: kPSheetShape,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _AppreciationForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final got = st.received(u.id);
    final sent = st.given(u.id);
    final list = _received ? got : sent;

    Widget tab(String label, int count, bool recv) {
      final sel = _received == recv;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _received = recv),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(color: sel ? kActRed : Colors.transparent, borderRadius: BorderRadius.circular(22)),
            child: Center(
              child: Text('$label ($count)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: sel ? Colors.white : muted(context))),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Apresiasi Relawan')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kActRed,
        foregroundColor: Colors.white,
        onPressed: _form,
        icon: const Icon(Icons.favorite),
        label: const Text('Beri Apresiasi'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Row(children: [
                  Expanded(
                    child: Column(children: [
                      Text('${got.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kActRed)),
                      Text('Apresiasi diterima', style: TextStyle(fontSize: 11, color: muted(context))),
                    ]),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.withAlpha(60)),
                  Expanded(
                    child: Column(children: [
                      Text('${sent.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kActRed)),
                      Text('Apresiasi diberikan', style: TextStyle(fontSize: 11, color: muted(context))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: kActPink, borderRadius: BorderRadius.circular(26)),
                child: Row(children: [tab('Diterima', got.length, true), tab('Diberikan', sent.length, false)]),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                EmptyState(Icons.favorite_border, _received ? 'Belum ada apresiasi diterima' : 'Belum ada apresiasi diberikan',
                    _received
                        ? 'Apresiasi dari relawan lain akan muncul di sini.'
                        : 'Tekan "Beri Apresiasi" untuk menyemangati relawan lain.')
              else
                for (final a in list)
                  Builder(builder: (_) {
                    final t = apprTypeOf(a.type);
                    final otherId = _received ? a.fromId : a.toId;
                    final otherName = _received ? a.fromName : a.toName;
                    final name = s.userById(otherId)?.name ?? otherName;
                    return PCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        PAvatar(otherId, name, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: Text(_received ? 'Dari $name' : 'Untuk $name',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              StatusPill(t.label, kActRed, icon: t.icon),
                            ]),
                            const SizedBox(height: 4),
                            Text(a.message, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                            const SizedBox(height: 4),
                            Text(timeAgo(a.createdAt), style: TextStyle(fontSize: 10.5, color: muted(context))),
                          ]),
                        ),
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

class _AppreciationForm extends StatefulWidget {
  const _AppreciationForm();

  @override
  State<_AppreciationForm> createState() => _AppreciationFormState();
}

class _AppreciationFormState extends State<_AppreciationForm> {
  String _toId = '';
  String _type = 'thanks';
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  void _send() {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final me = s.user;
    if (me == null) return;
    final to = s.userById(_toId);
    final err = st.sendAppreciation(
      fromId: me.id,
      fromName: me.name,
      toId: _toId,
      toName: to?.name ?? '',
      type: _type,
      message: _msg.text,
    );
    if (err != null) {
      pSnack(context, err);
      return;
    }
    // Beri tahu penerima bila ia akun nyata di perangkat ini
    if (to != null && !to.id.startsWith(kSeedUserPrefix)) {
      s.notifs.insert(
        0,
        Notif(
          id: s.newId('n'),
          userId: to.id,
          title: 'Kamu mendapat apresiasi',
          body: '${me.name} mengirim apresiasi "${apprTypeOf(_type).label}" untukmu.',
          kind: 'info',
          createdAt: DateTime.now(),
        ),
      );
      s.commitCommunity();
    }
    Navigator.pop(context);
    pSnack(context, 'Apresiasi terkirim');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.user;
    final members = s.communityMembers.where((m) => me == null || m.id != me.id).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Beri Apresiasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        actDropdown(
          label: 'Relawan yang diapresiasi',
          icon: Icons.person_outline,
          value: _toId,
          items: [
            const DropdownMenuItem(value: '', child: Text('Pilih relawan')),
            for (final m in members) DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _toId = v ?? ''),
        ),
        const SizedBox(height: 12),
        const Text('Jenis apresiasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in kApprTypes)
            ChoiceChip(
              avatar: Icon(t.icon, size: 16, color: _type == t.id ? Colors.white : kActRed),
              label: Text(t.label),
              selected: _type == t.id,
              selectedColor: kActRed,
              showCheckmark: false,
              labelStyle: TextStyle(color: _type == t.id ? Colors.white : null, fontSize: 12),
              onSelected: (_) => setState(() => _type = t.id),
            ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _msg,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
          decoration: pInput('Pesan positif', Icons.chat_bubble_outline),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: actFilledStyle(),
            onPressed: _send,
            icon: const Icon(Icons.favorite),
            label: const Text('Kirim Apresiasi'),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// K. STATISTIK RIWAYAT VOLUNTEER
// ============================================================
class ActivityStatsScreen extends StatefulWidget {
  const ActivityStatsScreen({super.key});

  @override
  State<ActivityStatsScreen> createState() => _ActivityStatsScreenState();
}

class _ActivityStatsScreenState extends State<ActivityStatsScreen> {
  String _metric = 'joined'; // joined | done | hours | points

  Widget _tile(IconData icon, String value, String label) {
    return PCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: kActPink, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kActRed, size: 20),
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
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final months = s.monthlyStats(u.id, months: 6);
    final joinedM = s.joinedPerMonth(u.id, months: 6);
    int val(int i) {
      switch (_metric) {
        case 'done':
          return months[i].events;
        case 'hours':
          return months[i].hours;
        case 'points':
          return months[i].points;
        default:
          return joinedM[i];
      }
    }

    var maxV = 1;
    for (var i = 0; i < months.length; i++) {
      if (val(i) > maxV) maxV = val(i);
    }
    final followed = u.pastEvents + s.regs.where((r) => r.userId == u.id && r.status != RegStatus.cancelled).length;
    final lang = context.read<ProfileStore>().isEnglish ? 'en_US' : 'id_ID';
    const labels = {'joined': 'Diikuti', 'done': 'Selesai', 'hours': 'Jam', 'points': 'Poin'};

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Riwayat Volunteer')),
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
                  _tile(Icons.event_available, fmtNum(followed), 'Total event diikuti'),
                  _tile(Icons.task_alt, fmtNum(s.totalEvents), 'Event diselesaikan'),
                  _tile(Icons.schedule, fmtNum(s.totalHours), 'Total jam kontribusi'),
                  _tile(Icons.star_rounded, fmtNum(s.totalPoints), 'Total poin'),
                  _tile(Icons.favorite, '${st.received(u.id).length}', 'Apresiasi diterima'),
                  _tile(Icons.volunteer_activism, '${st.given(u.id).length}', 'Apresiasi diberikan'),
                ],
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.bar_chart_rounded, 'Grafik Aktivitas 6 Bulan Terakhir'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    for (final m in labels.keys)
                      ChoiceChip(
                        label: Text(labels[m]!),
                        selected: _metric == m,
                        selectedColor: kActRed,
                        showCheckmark: false,
                        labelStyle: TextStyle(color: _metric == m ? Colors.white : null, fontSize: 12),
                        onSelected: (_) => setState(() => _metric = m),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (var i = 0; i < months.length; i++)
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('${val(i)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 22,
                              height: val(i) == 0 ? 4 : 120 * val(i) / maxV,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), kActRed],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(DateFormat('MMM', lang).format(months[i].month),
                                style: TextStyle(fontSize: 10.5, color: muted(context))),
                          ]),
                        ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.calendar_month, 'Kegiatan Diikuti Setiap Bulan'),
                  const SizedBox(height: 10),
                  for (var i = months.length - 1; i >= 0; i--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(
                          child: Text(DateFormat('MMMM yyyy', lang).format(months[i].month),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                        Text('${joinedM[i]} diikuti • ${months[i].events} selesai',
                            style: TextStyle(fontSize: 11.5, color: muted(context))),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              Text(
                'Grafik dihitung dari pendaftaranmu dan poin yang sudah diverifikasi panitia.',
                style: TextStyle(fontSize: 11, color: muted(context)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}