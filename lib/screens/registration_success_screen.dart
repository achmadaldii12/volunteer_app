import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final Registration reg;
  final bool fresh;      // true: baru saja mendaftar
  final bool fromDetail; // true: dibuka dari halaman detail event
  const RegistrationSuccessScreen(this.reg, {super.key, this.fresh = false, this.fromDetail = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final e = s.eventById(reg.eventId);
    if (e == null) return const Scaffold(body: Center(child: Text('Kegiatan tidak ditemukan')));

    return Scaffold(
      appBar: AppBar(title: Text(fresh ? '' : 'Tiket Saya')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            if (fresh) ...[
              const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check, color: Colors.white, size: 36)),
              const SizedBox(height: 12),
              const Text('Pendaftaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Terima kasih telah mendaftar pada\nkegiatan ini.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted(context))),
              const SizedBox(height: 18),
            ],
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: softOf(context),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                  child: Text('Tiket Kehadiran',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Text(e.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${fmtLongDate(e.date)} - ${e.time}',
                        style: TextStyle(fontSize: 12, color: muted(context))),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: QrImageView(
                          data: reg.code, size: 170, backgroundColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text('Kode: ${reg.code}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Atas nama ${s.user?.name ?? '-'}', style: const TextStyle(fontSize: 12)),
                    if (reg.status != RegStatus.registered) ...[
                      const SizedBox(height: 8),
                      StatusChip(reg.status == RegStatus.attended ? 'Sudah hadir' : 'Dibatalkan',
                          reg.status == RegStatus.attended ? AppColors.success : Colors.grey),
                    ],
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            PrimaryButton('Lihat Detail Event', onTap: () {
              if (fromDetail) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => EventDetailScreen(e)));
              }
            }),
            const SizedBox(height: 10),
            PrimaryButton('Bagikan Tiket', light: true, icon: Icons.share, onTap: () {
              Clipboard.setData(ClipboardData(
                  text: 'Tiket ${e.title}\n${fmtLongDate(e.date)}, ${e.time}\nKode: ${reg.code}'));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Detail tiket disalin ke clipboard')));
            }),
          ]),
        ),
      ),
    );
  }
}
