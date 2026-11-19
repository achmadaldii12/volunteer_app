import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';
import '../pdf_exports.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? _eventId;
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _hm(String? iso) => iso == null ? '-' : DateFormat('HH.mm').format(DateTime.parse(iso));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    final events = org.myEvents(s, u.id).where((e) => org.metaOf(e).status != 'draft' && org.metaOf(e).status != 'cancelled').toList();
    if (events.isEmpty) {
      return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHead('Presensi & Sertifikat', 'QR presensi, check-in/out, dan sertifikat digital'),
        OrgCard(child: EmptyBox(Icons.qr_code_2_rounded, 'Belum ada event yang dapat dipresensi. Terbitkan event terlebih dahulu.')),
      ]);
    }
    final e = events.firstWhere((x) => x.id == _eventId, orElse: () => events.first);
    final regs = org.regsFor(s, [e.id]).where((r) {
      final st = org.regState(s, r);
      return st == 'accepted' || st == 'completed';
    }).toList();
    final hadir = regs.where((r) => r.status == RegStatus.attended).length;
    final belum = regs.length - hadir;
    final st = org.statusOf(e);
    final prof = org.profileOf(u);
    final qrData = 'VOLUNTEER|EVENT|${e.id}|${e.date.millisecondsSinceEpoch}';
    final eligible = regs.where((r) => org.eligible(r) && org.certOf(r.id) == null).toList();

    Widget stat(String t, int n, Color c, IconData i) => OrgCard(
          child: Row(children: [
            CircleAvatar(radius: 21, backgroundColor: c.withOpacity(.12), child: Icon(i, color: c, size: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$n',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHead('Presensi & Sertifikat', 'Kelola kehadiran relawan dan terbitkan sertifikat digital'),
      DropdownButtonFormField<String>(
        value: e.id,
        isExpanded: true,
        decoration: fieldDeco('Pilih event', icon: Icons.event_rounded).copyWith(fillColor: Colors.white),
        items: [for (final x in events) DropdownMenuItem(value: x.id, child: Text('${x.title}  •  ${fmtDate(x.date)}', overflow: TextOverflow.ellipsis))],
        onChanged: (v) => setState(() => _eventId = v),
      ),
      const SizedBox(height: 14),
      Grid([
        stat('Peserta diterima', regs.length, AppColors.primary, Icons.groups_rounded),
        stat('Hadir (check-in)', hadir, const Color(0xFF16A34A), Icons.how_to_reg_rounded),
        stat(st == 'completed' ? 'Tidak hadir' : 'Belum hadir', belum, const Color(0xFFF59E0B), Icons.person_off_rounded),
        stat('Sertifikat terbit', regs.where((r) => org.certOf(r.id) != null).length, const Color(0xFF2563EB), Icons.workspace_premium_rounded),
      ], minWidth: 190),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (_, c) {
        final qr = OrgSection(
          title: 'QR Presensi Event',
          icon: Icons.qr_code_2_rounded,
          child: Column(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: kOrgLine), borderRadius: BorderRadius.circular(18)), child: QrImageView(data: qrData, size: 180, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryDark), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87))),
            const SizedBox(height: 10),
            const Text('Tampilkan QR ini di lokasi kegiatan atau cetak sebagai poster presensi.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: qrData)); toast(context, 'Kode QR disalin'); }, icon: const Icon(Icons.copy_rounded, size: 16), label: const Text('Salin kode QR')),
            const Divider(height: 28),
            Align(alignment: Alignment.centerLeft, child: Text('Check-in manual (kode relawan)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: fieldDeco(null, hint: 'VOL2027...', icon: Icons.confirmation_number_outlined))),
              const SizedBox(width: 8),
              ElevatedButton(
                style: redBtn(),
                onPressed: () {
                  final er = org.checkInByCode(s, _code.text, {e.id});
                  if (er == null) _code.clear();
                  toast(context, er ?? 'Check-in berhasil, poin diberikan ke relawan');
                },
                child: const Text('Check-in'),
              ),
            ]),
          ]),
        );

        final list = OrgSection(
          title: 'Daftar Peserta',
          icon: Icons.fact_check_rounded,
          trailing: eligible.isEmpty
              ? null
              : ElevatedButton.icon(
                  style: redBtn(small: true),
                  onPressed: () {
                    var n = 0;
                    for (final r in eligible) {
                      if (org.issueCertificate(s, r) == null) n++;
                    }
                    toast(context, '$n sertifikat diterbitkan');
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                  label: Text('Terbitkan (${eligible.length})'),
                ),
          child: regs.isEmpty
              ? const EmptyBox(Icons.person_search_rounded, 'Belum ada peserta yang diterima untuk event ini')
              : Column(children: [for (final r in regs) _row(context, s, org, e, r, prof.name)]),
        );
        if (c.maxWidth < 900) return Column(children: [qr, const SizedBox(height: 16), list]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 340, child: qr), const SizedBox(width: 16), Expanded(child: list)]);
      }),
      const SizedBox(height: 10),
      const Text('Ketentuan sertifikat: relawan harus check-in dan check-out. Poin kehadiran diberikan otomatis saat check-in.', style: TextStyle(fontSize: 12, color: Colors.black45)),
    ]);
  }

  Widget _row(BuildContext context, AppState s, OrgStore org, EventModel e, Registration r, String orgName) {
    final v = s.userById(r.userId);
    final cert = org.certOf(r.id);
    final inT = org.checkIns[r.id], outT = org.checkOuts[r.id];
    final attended = r.status == RegStatus.attended;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: kOrgLine), borderRadius: BorderRadius.circular(16)),
      child: Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 230,
          child: Row(children: [
            Avatar(initialsOf(v?.name ?? '?')),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v?.name ?? 'Relawan', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text(r.code, style: const TextStyle(fontSize: 11, color: Colors.black45))])),
          ]),
        ),
        Text('Masuk ${_hm(inT)}  •  Keluar ${_hm(outT)}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        StatusPill(attended ? 'Hadir' : 'Belum hadir', attended ? statusColor('accepted') : statusColor('pending')),
        if (!attended) ElevatedButton(style: redBtn(small: true), onPressed: () { final er = org.checkIn(s, r.id); toast(context, er ?? '${v?.name ?? 'Relawan'} check-in'); }, child: const Text('Check-in')),
        if (attended && outT == null && inT != null) ElevatedButton(style: softBtn(small: true), onPressed: () { final er = org.checkOut(s, r.id); toast(context, er ?? 'Check-out dicatat'); }, child: const Text('Check-out')),
        if (attended && cert == null) OutlinedButton(onPressed: () { final er = org.issueCertificate(s, r); toast(context, er ?? 'Sertifikat diterbitkan'); }, child: const Text('Terbitkan sertifikat')),
        if (cert != null)
          OutlinedButton.icon(
            onPressed: () => shareCertificatePdf(volunteer: v?.name ?? 'Relawan', eventTitle: e.title, orgName: orgName, number: cert.number, dateText: 'Diterbitkan ${fmtDate(cert.issuedAt)}', hours: e.hours),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Unduh'),
          ),
      ]),
    );
  }
}