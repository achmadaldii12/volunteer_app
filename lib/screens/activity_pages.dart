import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import '../providers/activity_store.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'profile_pages.dart';

// ============================================================
// KOMPONEN BERSAMA
// ============================================================
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const StatusPill(this.text, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  const StarRating({super.key, required this.value, required this.onChanged, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(i),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B), size: size),
          ),
        ),
    ]);
  }
}

Future<bool> confirmAct(BuildContext context, String title, String message, {String yes = 'Ya', bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: danger ? AppColors.danger : kActRed, foregroundColor: Colors.white),
          child: Text(yes),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Dropdown sederhana dengan gaya input aplikasi. Nilai '' berarti belum memilih.
Widget actDropdown({
  required String label,
  required IconData icon,
  required String value,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String?> onChanged,
}) {
  return InputDecorator(
    decoration: pInput(label, icon),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        isDense: true,
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

/// Menandai kehadiran terverifikasi (simulasi panitia) + mencatat jam check-in/out.
/// Poin diberikan oleh AppState.markAttended (anti dobel).
Future<bool> verifyAttendance(BuildContext context, Registration r) async {
  final s = context.read<AppState>();
  final st = context.read<ActivityStore>();
  final e = s.eventById(r.eventId);
  final gained = s.markAttended(r.id);
  if (e != null && gained > 0) {
    final w = s.eventWindow(e);
    st.recordAttendance(
      r.userId,
      AttendanceRecord(
        regId: r.id,
        checkIn: w.start.add(const Duration(minutes: 5)),
        checkOut: w.end,
        verifiedAt: DateTime.now(),
      ),
    );
  }
  if (context.mounted) {
    pSnack(context, gained > 0 ? 'Kehadiran terverifikasi, +$gained poin' : 'Poin sudah pernah diberikan');
  }
  return gained > 0;
}

String actDate(DateTime d) => fmtDate(d);
String actHm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

String actDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m menit';
  return m == 0 ? '$h jam' : '$h jam $m menit';
}

// ============================================================
// CHECK-IN QR (Scan QR)
// ============================================================
class CheckInQrScreen extends StatelessWidget {
  final Registration reg;
  const CheckInQrScreen(this.reg, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final e = s.eventById(reg.eventId);
    final status = reg.status;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in QR')),
      body: e == null
          ? const Center(child: Text('Kegiatan tidak ditemukan'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(children: [
                    PCard(
                      child: Column(children: [
                        Text(e.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${actDate(e.date)} • ${e.time}',
                            style: TextStyle(fontSize: 12, color: muted(context))),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kActPink)),
                          child: QrImageView(data: reg.code, size: 210, backgroundColor: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(reg.code,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text('Tunjukkan QR ini kepada panitia saat tiba di lokasi untuk check-in.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: muted(context), height: 1.4)),
                        const SizedBox(height: 14),
                        if (status == RegStatus.registered)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: actFilledStyle(),
                              icon: const Icon(Icons.how_to_reg_outlined),
                              label: const Text('Simulasikan Scan Panitia (demo)'),
                              onPressed: () async {
                                final ok = await confirmAct(context, 'Verifikasi kehadiran?',
                                    'Simulasi panitia memindai QR-mu. Poin akan diberikan setelah kehadiran terverifikasi.',
                                    yes: 'Verifikasi');
                                if (!ok || !context.mounted) return;
                                await verifyAttendance(context, reg);
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          )
                        else
                          StatusPill(
                            status == RegStatus.attended ? 'Kehadiran sudah terverifikasi' : 'Pendaftaran dibatalkan',
                            status == RegStatus.attended ? AppColors.success : Colors.grey,
                            icon: status == RegStatus.attended ? Icons.verified : Icons.cancel_outlined,
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
// A. PENGAJUAN KOORDINATOR
// ============================================================
class CoordinatorRequestScreen extends StatefulWidget {
  const CoordinatorRequestScreen({super.key});

  @override
  State<CoordinatorRequestScreen> createState() => _CoordinatorRequestScreenState();
}

class _CoordinatorRequestScreenState extends State<CoordinatorRequestScreen> {
  String _eventId = '';
  final _reason = TextEditingController();
  final _exp = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _exp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    final ok = await confirmAct(context, 'Kirim pengajuan?', 'Pengajuanmu akan dikirim ke panitia untuk ditinjau.',
        yes: 'Kirim');
    if (!ok || !mounted) return;
    final err = st.submitRequest(u.id, eventId: _eventId, reason: _reason.text, experience: _exp.text);
    if (err != null) {
      pSnack(context, err);
      return;
    }
    setState(() {
      _eventId = '';
      _reason.clear();
      _exp.clear();
    });
    pSnack(context, 'Pengajuan terkirim. Status: Menunggu');
  }

  Future<void> _decide(CoordRequest r, bool approve) async {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    st.decideRequest(u.id, r.id, approve);
    if (approve) {
      // Jika kehadiran sudah terverifikasi, poin koordinator (+10) ikut diberikan (anti dobel).
      for (final reg in s.regs) {
        if (reg.userId == u.id && reg.eventId == r.eventId && reg.status == RegStatus.attended) {
          s.awardCoordinator(reg.id);
        }
      }
    }
    if (mounted) pSnack(context, approve ? 'Pengajuan disetujui. Kamu kini Koordinator' : 'Pengajuan ditolak');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final joined = <String>{};
    for (final r in s.regs) {
      if (r.userId == u.id && r.status != RegStatus.cancelled) joined.add(r.eventId);
    }
    final upcoming = s.query(sort: EventSort.soonest, upcomingOnly: true);
    final events = <EventModel>[
      ...upcoming.where((e) => joined.contains(e.id)),
      ...upcoming.where((e) => !joined.contains(e.id)).take(30),
    ];
    final reqs = st.requests(u.id);
    final isCoord = st.hasCoordinatorStatus(u.id);

    Color statusColor(String x) =>
        x == 'approved' ? AppColors.success : (x == 'rejected' ? Colors.grey : AppColors.warning);
    String statusText(String x) => x == 'approved' ? 'Disetujui' : (x == 'rejected' ? 'Ditolak' : 'Menunggu');

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Menjadi Koordinator')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              if (isCoord)
                PCard(
                  color: kActPink,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Row(children: const [
                    Icon(Icons.verified, color: kActRed, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Status kamu: Koordinator. Pengajuanmu telah disetujui panitia.',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                    ),
                  ]),
                ),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.groups, 'Formulir Pengajuan'),
                  const SizedBox(height: 14),
                  actDropdown(
                    label: 'Event yang ingin dikoordinasikan',
                    icon: Icons.event,
                    value: _eventId,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Pilih event')),
                      for (final e in events)
                        DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            '${joined.contains(e.id) ? '★ ' : ''}${e.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _eventId = v ?? ''),
                  ),
                  const SizedBox(height: 4),
                  Text('★ = event yang sudah kamu daftarkan', style: TextStyle(fontSize: 11, color: muted(context))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reason,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 400,
                    decoration: pInput('Alasan pengajuan', Icons.edit_note),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _exp,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 400,
                    decoration: pInput('Pengalaman menjadi relawan', Icons.workspace_premium_outlined),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: actFilledStyle(),
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Kirim Pengajuan'),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const PSectionHeader(Icons.history, 'Riwayat Pengajuan'),
                  const SizedBox(height: 12),
                  if (reqs.isEmpty)
                    Text('Belum ada pengajuan.', style: TextStyle(color: muted(context), fontSize: 13)),
                  for (final r in reqs)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: softOf(context), borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(s.eventById(r.eventId)?.title ?? 'Event',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                          StatusPill(statusText(r.status), statusColor(r.status)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Diajukan ${fmtDateTime(r.createdAt)}',
                            style: TextStyle(fontSize: 11, color: muted(context))),
                        const SizedBox(height: 6),
                        Text(r.reason, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                        if (r.status == 'pending') ...[
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            OutlinedButton(
                              style: actOutlineStyle(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                              onPressed: () => _decide(r, false),
                              child: const Text('Tolak (demo panitia)'),
                            ),
                            ElevatedButton(
                              style: actFilledStyle(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                              onPressed: () => _decide(r, true),
                              child: const Text('Setujui (demo panitia)'),
                            ),
                          ]),
                        ],
                      ]),
                    ),
                  Text(
                    'Keputusan panitia disimulasikan lewat tombol demo karena aplikasi belum terhubung ke server.',
                    style: TextStyle(fontSize: 10.5, color: muted(context)),
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
// B. RIWAYAT PEROLEHAN POIN
// ============================================================
class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  int _filter = 0; // 0 semua, 1 poin masuk, 2 menunggu verifikasi

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

    final all = s.myPointHistory; // sudah urut terbaru -> terlama
    var plus = 0, minus = 0, pending = 0;
    for (final e in all) {
      if (!e.verified) {
        pending += e.points;
      } else if (e.points >= 0) {
        plus += e.points;
      } else {
        minus += e.points;
      }
    }
    final list = all.where((e) {
      if (_filter == 1) return e.verified;
      if (_filter == 2) return !e.verified;
      return true;
    }).toList();

    Widget chip(String l, int i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(l),
            selected: _filter == i,
            selectedColor: kActRed,
            showCheckmark: false,
            labelStyle: TextStyle(color: _filter == i ? Colors.white : null, fontSize: 12),
            onSelected: (_) => setState(() => _filter = i),
          ),
        );

    Widget sum(String label, String value, Color c) => Expanded(
          child: Column(children: [
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c)),
            Text(label, style: TextStyle(fontSize: 10.5, color: muted(context))),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Perolehan Poin')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [kActRed, Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 42),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Poin Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(fmtNum(s.totalPoints),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    StatusPill('Level ${levelOf(s.totalPoints).name}', Colors.white),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              PCard(
                child: Row(children: [
                  sum('Total Masuk', '+${fmtNum(plus)}', AppColors.success),
                  sum('Pengurangan', minus == 0 ? '0' : fmtNum(minus), kActRed),
                  sum('Menunggu', '+${fmtNum(pending)}', AppColors.warning),
                ]),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(children: [chip('Semua', 0), chip('Poin Masuk', 1), chip('Menunggu', 2)]),
              ),
              const SizedBox(height: 6),
              if (list.isEmpty)
                const EmptyState(Icons.stars_outlined, 'Belum ada riwayat poin',
                    'Ikuti kegiatan dan minta panitia memverifikasi kehadiranmu.')
              else
                for (final e in list)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: kActPink, borderRadius: BorderRadius.circular(13)),
                        child: Icon(_icon(e.type), color: kActRed, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('${fmtDateTime(e.createdAt)} • Kegiatan ${actDate(e.date)}',
                              style: TextStyle(fontSize: 10.5, color: muted(context))),
                          const SizedBox(height: 3),
                          Text('Alasan: ${e.note}', style: const TextStyle(fontSize: 11.5, height: 1.3)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(e.points >= 0 ? '+${fmtNum(e.points)}' : fmtNum(e.points),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: !e.verified
                                    ? AppColors.warning
                                    : (e.points >= 0 ? AppColors.success : kActRed))),
                        const SizedBox(height: 3),
                        StatusPill(e.verified ? 'Terverifikasi' : 'Menunggu',
                            e.verified ? AppColors.success : AppColors.warning),
                      ]),
                    ]),
                  ),
              const SizedBox(height: 6),
              Text(
                'Belum ada aturan penalti yang berlaku, sehingga saat ini tidak ada pengurangan poin. '
                'Jika aturan penalti diterapkan, pengurangan akan tampil di sini dengan tanda minus.',
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

// ============================================================
// C. EVALUASI KEGIATAN
// ============================================================
class EvaluationListScreen extends StatelessWidget {
  const EvaluationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final regs = s.attendedRegs;

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluasi Kegiatan')),
      body: regs.isEmpty
          ? const EmptyState(Icons.rate_review_outlined, 'Belum ada kegiatan selesai',
              'Evaluasi dapat diberikan setelah kehadiranmu terverifikasi.')
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    for (final r in regs)
                      Builder(builder: (_) {
                        final e = s.eventById(r.eventId);
                        if (e == null) return const SizedBox.shrink();
                        final ev = st.evalOf(u.id, e.id);
                        return PCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationFormScreen(e))),
                          child: Row(children: [
                            EventImage(e, width: 62, height: 62, radius: 12),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                const SizedBox(height: 3),
                                Text(actDate(e.date), style: TextStyle(fontSize: 11, color: muted(context))),
                                const SizedBox(height: 5),
                                if (ev != null)
                                  Row(children: [
                                    for (var i = 1; i <= 5; i++)
                                      Icon(i <= ev.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          size: 16, color: const Color(0xFFF59E0B)),
                                  ]),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              StatusPill(ev != null ? 'Sudah Memberikan Evaluasi' : 'Belum Memberikan Evaluasi',
                                  ev != null ? AppColors.success : AppColors.warning),
                              const SizedBox(height: 6),
                              Text(ev != null ? 'Ubah' : 'Nilai sekarang',
                                  style: const TextStyle(color: kActRed, fontSize: 12, fontWeight: FontWeight.w700)),
                            ]),
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

class EvaluationFormScreen extends StatefulWidget {
  final EventModel event;
  const EvaluationFormScreen(this.event, {super.key});

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  int _overall = 0, _organizer = 0, _coord = 0;
  final _comment = TextEditingController();
  final _suggestion = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u != null) {
      final ev = st.evalOf(u.id, widget.event.id);
      if (ev != null) {
        _overall = ev.rating;
        _organizer = ev.organizer;
        _coord = ev.coordination;
        _comment.text = ev.comment;
        _suggestion.text = ev.suggestion;
      }
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    _suggestion.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    final err = st.saveEval(
      u.id,
      EvalRecord(
        eventId: widget.event.id,
        rating: _overall,
        organizer: _organizer,
        coordination: _coord,
        comment: _comment.text.trim(),
        suggestion: _suggestion.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    if (err != null) {
      pSnack(context, err);
      return;
    }
    // Kirim juga sebagai feedback ke database (tabel feedbacks) + tampil di Riwayat Feedback.
    s.submitFeedback(widget.event.title, _overall, _comment.text.trim());
    final fb = await confirmAct(context, 'Terima kasih!',
        'Evaluasimu tersimpan. Ingin menyimpan komentarmu juga sebagai catatan pengalaman?',
        yes: 'Simpan Catatan');
    if (fb && mounted && _comment.text.trim().length >= 10) {
      st.saveNote(u.id, eventId: widget.event.id, experience: _comment.text.trim());
    }
    if (mounted) {
      Navigator.pop(context);
      pSnack(context, 'Evaluasi berhasil disimpan');
    }
  }

  Widget _row(String label, IconData icon, int value, ValueChanged<int> on) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Icon(icon, color: kActRed, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        StarRating(value: value, onChanged: on, size: 28),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluasi Kegiatan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(children: [
              PCard(
                child: Row(children: [
                  EventImage(e, width: 58, height: 58, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(actDate(e.date), style: TextStyle(fontSize: 11.5, color: muted(context))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _row('Rating kegiatan', Icons.star_outline_rounded, _overall, (v) => setState(() => _overall = v)),
                  _row('Penyelenggaraan event', Icons.event_available_outlined, _organizer,
                      (v) => setState(() => _organizer = v)),
                  _row('Koordinasi panitia', Icons.groups_outlined, _coord, (v) => setState(() => _coord = v)),
                  TextField(
                    controller: _comment,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 400,
                    decoration: pInput('Komentar', Icons.chat_bubble_outline),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _suggestion,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: pInput('Saran perbaikan', Icons.lightbulb_outline),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: actFilledStyle(),
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Simpan Evaluasi'),
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
// D. CATATAN PENGALAMAN VOLUNTEER
// ============================================================
class ExperienceNotesScreen extends StatelessWidget {
  const ExperienceNotesScreen({super.key});

  void _detail(BuildContext context, ExperienceNote n, String title) {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: kPSheetShape,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Diperbarui ${fmtDateTime(n.updatedAt)}', style: TextStyle(fontSize: 11, color: muted(context))),
            const SizedBox(height: 14),
            const Text('Pengalaman', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            Text(n.experience, style: const TextStyle(height: 1.45)),
            if (n.learned.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Yang dipelajari', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text(n.learned, style: const TextStyle(height: 1.45)),
            ],
            if (n.contribution.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Kontribusi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text(n.contribution, style: const TextStyle(height: 1.45)),
            ],
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                style: actOutlineStyle(),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(note: n)));
                },
              ),
              OutlinedButton.icon(
                style: actOutlineStyle(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Bagikan'),
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ShareExperienceScreen(eventId: n.eventId)));
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                onPressed: () async {
                  Navigator.pop(sheet);
                  final ok = await confirmAct(context, 'Hapus catatan?', 'Catatan pengalaman ini akan dihapus permanen.',
                      yes: 'Hapus', danger: true);
                  if (!ok || !context.mounted) return;
                  st.deleteNote(u.id, n.id);
                  pSnack(context, 'Catatan dihapus');
                },
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final notes = st.notes(u.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Pengalaman')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kActRed,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteFormScreen())),
        icon: const Icon(Icons.edit),
        label: const Text('Tulis Catatan'),
      ),
      body: notes.isEmpty
          ? const EmptyState(Icons.menu_book_outlined, 'Belum ada catatan',
              'Tulis pengalaman, hal yang kamu pelajari, dan kontribusimu setelah mengikuti kegiatan.')
          : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    for (final n in notes)
                      Builder(builder: (_) {
                        final title = s.eventById(n.eventId)?.title ?? 'Kegiatan';
                        return PCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: () => _detail(context, n, title),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.menu_book, color: kActRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                              ),
                              Text(actDate(n.updatedAt), style: TextStyle(fontSize: 10.5, color: muted(context))),
                            ]),
                            const SizedBox(height: 8),
                            Text(n.experience,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, height: 1.4)),
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

class NoteFormScreen extends StatefulWidget {
  final ExperienceNote? note;
  final String? eventId; // event yang dipilih otomatis saat membuat catatan baru
  const NoteFormScreen({super.key, this.note, this.eventId});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  String _eventId = '';
  final _exp = TextEditingController();
  final _learned = TextEditingController();
  final _contrib = TextEditingController();

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    if (n == null && widget.eventId != null) _eventId = widget.eventId!;
    if (n != null) {
      _eventId = n.eventId;
      _exp.text = n.experience;
      _learned.text = n.learned;
      _contrib.text = n.contribution;
    }
  }

  @override
  void dispose() {
    _exp.dispose();
    _learned.dispose();
    _contrib.dispose();
    super.dispose();
  }

  void _save() {
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    final err = st.saveNote(u.id,
        id: widget.note?.id,
        eventId: _eventId,
        experience: _exp.text,
        learned: _learned.text,
        contribution: _contrib.text);
    if (err != null) {
      pSnack(context, err);
      return;
    }
    Navigator.pop(context);
    pSnack(context, widget.note == null ? 'Catatan tersimpan' : 'Catatan diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final regs = s.attendedRegs;
    final seen = <String>{};
    final events = <EventModel>[];
    for (final r in regs) {
      final e = s.eventById(r.eventId);
      if (e != null && seen.add(e.id)) events.add(e);
    }
    // saat mengedit, pastikan event catatan tetap tersedia di dropdown
    if (_eventId.isNotEmpty && !seen.contains(_eventId)) {
      final e = s.eventById(_eventId);
      if (e != null) events.add(e);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.note == null ? 'Tulis Catatan' : 'Edit Catatan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: events.isEmpty
                ? const EmptyState(Icons.menu_book_outlined, 'Belum ada kegiatan selesai',
                    'Catatan hanya dapat dibuat untuk kegiatan yang kehadirannya sudah terverifikasi.')
                : PCard(
                    child: Column(children: [
                      actDropdown(
                        label: 'Kegiatan',
                        icon: Icons.event,
                        value: _eventId,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Pilih kegiatan')),
                          for (final e in events)
                            DropdownMenuItem(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => _eventId = v ?? ''),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _exp,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 600,
                        decoration: pInput('Pengalaman selama kegiatan', Icons.auto_stories_outlined),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _learned,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        decoration: pInput('Hal yang dipelajari', Icons.school_outlined),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _contrib,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        decoration: pInput('Kontribusi yang dilakukan', Icons.volunteer_activism_outlined),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            style: actOutlineStyle(),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: actFilledStyle(),
                            onPressed: _save,
                            child: const Text('Simpan'),
                          ),
                        ),
                      ]),
                    ]),
                  ),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// F. FAVORIT EVENT
// ============================================================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.events.where((e) => s.isBookmarked(e.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Event Favorit')),
      body: list.isEmpty
          ? const EmptyState(Icons.favorite_border, 'Belum ada event favorit',
              'Buka detail sebuah event lalu tekan ikon simpan (bookmark) untuk menambahkannya ke favorit.')
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    for (final e in list)
                      PCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
                        child: Row(children: [
                          EventImage(e, width: 70, height: 70, radius: 14),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                              const SizedBox(height: 3),
                              Text('${actDate(e.date)} • ${e.location}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: muted(context))),
                              const SizedBox(height: 5),
                              StatusPill(e.category, kActRed),
                            ]),
                          ),
                          IconButton(
                            tooltip: 'Hapus dari favorit',
                            icon: const Icon(Icons.favorite, color: kActRed),
                            onPressed: () {
                              s.toggleBookmark(e.id);
                              pSnack(context, 'Dihapus dari favorit');
                            },
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
// G. BAGIKAN PENGALAMAN
// ============================================================
class ShareExperienceScreen extends StatefulWidget {
  final String? eventId;
  const ShareExperienceScreen({super.key, this.eventId});

  @override
  State<ShareExperienceScreen> createState() => _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends State<ShareExperienceScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final _text = TextEditingController();
  String _eventId = '';
  bool _showPoints = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return;
    final attended = s.attendedRegs;
    if (widget.eventId != null) {
      _eventId = widget.eventId!;
    } else if (attended.isNotEmpty) {
      _eventId = attended.first.eventId;
    }
    _prefill(s, st, u.id);
  }

  void _prefill(AppState s, ActivityStore st, String uid) {
    final e = s.eventById(_eventId);
    String t = e == null ? '' : 'Seru banget ikut ${e.title}! Terima kasih sudah jadi bagian dari perubahan baik.';
    for (final n in st.notes(uid)) {
      if (n.eventId == _eventId) {
        t = n.experience;
        break;
      }
    }
    _text.text = t;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _shareText(AppState s, String uid) {
    final e = s.eventById(_eventId);
    final pts = s.pointsFromEvent(uid, _eventId);
    final b = StringBuffer();
    b.writeln('Pengalaman Volunteer: ${e?.title ?? ''}');
    b.writeln(_text.text.trim());
    if (_showPoints && pts > 0) b.writeln('Pencapaian: +$pts poin');
    b.write('#Volunteer #BersamaKitaMemberiDampak');
    return b.toString();
  }

  Future<void> _share(String fallback) async {
    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('no boundary');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('no data');
      final doc = pw.Document();
      final img = pw.MemoryImage(data.buffer.asUint8List());
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (c) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
      ));
      await Printing.sharePdf(bytes: await doc.save(), filename: 'pengalaman-volunteer.pdf');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: fallback));
      if (mounted) {
        pSnack(context, 'Fitur berbagi belum didukung di perangkat ini. Teks pengalaman disalin ke clipboard.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.read<ActivityStore>();
    final u = s.user;
    if (u == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final seen = <String>{};
    final events = <EventModel>[];
    for (final r in s.attendedRegs) {
      final e = s.eventById(r.eventId);
      if (e != null && seen.add(e.id)) events.add(e);
    }
    final e = s.eventById(_eventId);
    final pts = s.pointsFromEvent(u.id, _eventId);
    final text = _shareText(s, u.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Bagikan Pengalaman')),
      body: events.isEmpty
          ? const EmptyState(Icons.share_outlined, 'Belum ada kegiatan selesai',
              'Kamu dapat membagikan pengalaman setelah kehadiranmu terverifikasi.')
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(children: [
                    PCard(
                      child: Column(children: [
                        actDropdown(
                          label: 'Kegiatan',
                          icon: Icons.event,
                          value: seen.contains(_eventId) ? _eventId : '',
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Pilih kegiatan')),
                            for (final ev in events)
                              DropdownMenuItem(value: ev.id, child: Text(ev.title, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            setState(() => _eventId = v ?? '');
                            _prefill(s, st, u.id);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _text,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 300,
                          onChanged: (_) => setState(() {}),
                          decoration: pInput('Pengalamanmu', Icons.edit_note),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: kActRed,
                          title: const Text('Tampilkan pencapaian poin'),
                          value: _showPoints,
                          onChanged: (v) => setState(() => _showPoints = v),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    RepaintBoundary(
                      key: _cardKey,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [kActRed, Color(0xFF991B1B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: const [
                            Icon(Icons.volunteer_activism, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Pengalaman Volunteer',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          ]),
                          const SizedBox(height: 16),
                          Text(e?.title ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(e == null ? '' : '${actDate(e.date)} • ${e.location}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 14),
                          Text(_text.text.trim().isEmpty ? '...' : _text.text.trim(),
                              style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45)),
                          const SizedBox(height: 16),
                          if (_showPoints && pts > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(36), borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                                const SizedBox(width: 6),
                                Text('+$pts poin',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ]),
                            ),
                          const SizedBox(height: 14),
                          Text(u.name, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: actFilledStyle(),
                        onPressed: _eventId.isEmpty ? null : () => _share(text),
                        icon: const Icon(Icons.share),
                        label: const Text('Bagikan'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: actOutlineStyle(),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) pSnack(context, 'Teks disalin');
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Salin Teks'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Kartu dibagikan sebagai gambar di dalam berkas PDF melalui fitur share perangkat.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: muted(context))),
                  ]),
                ),
              ),
            ]),
    );
  }
}