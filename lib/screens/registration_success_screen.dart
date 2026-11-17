import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/nav_bus.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final Registration reg;
  final bool fresh; // true: baru saja mendaftar
  final bool fromDetail; // true: dibuka dari halaman detail event
  const RegistrationSuccessScreen(this.reg, {super.key, this.fresh = false, this.fromDetail = false});

  static const Color _red = AppColors.primary;

  // ------------------------------------------------------------ aksi
  String _ticketText(EventModel e) =>
      'Tiket ${e.title}\n${fmtLongDate(e.date)}, ${e.time}\n${e.location}\nKode: ${reg.code}';

  void _snack(BuildContext context, String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reg.code));
    _snack(context, 'Kode pendaftaran disalin');
  }

  Future<void> _open(BuildContext context, EventModel e, Uri uri) async {
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      Clipboard.setData(ClipboardData(text: _ticketText(e)));
      if (context.mounted) {
        _snack(context, 'Tidak bisa membuka aplikasinya, detail tiket disalin ke clipboard');
      }
    }
  }

  void _shareTicket(BuildContext context, EventModel e) {
    final text = _ticketText(e);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 14),
          const Text('Bagikan Tiket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
            title: const Text('WhatsApp'),
            onTap: () {
              Navigator.pop(sheet);
              _open(context, e, Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'));
            },
          ),
          ListTile(
            leading: const Icon(Icons.send, color: Color(0xFF2AABEE)),
            title: const Text('Telegram'),
            onTap: () {
              Navigator.pop(sheet);
              _open(context, e, Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(text)}'));
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: _red),
            title: const Text('Salin detail tiket'),
            onTap: () {
              Navigator.pop(sheet);
              Clipboard.setData(ClipboardData(text: text));
              _snack(context, 'Detail tiket disalin ke clipboard');
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _goDetail(BuildContext context, EventModel e) {
    if (fromDetail) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e)));
    }
  }

  void _goHistory(BuildContext context) {
    // Kembali ke halaman utama, lalu buka Riwayat > tab Mengikuti
    Navigator.of(context).popUntil((r) => r.isFirst);
    navRequest.value = NavRequest(2, subTab: 0, highlightRegId: reg.id);
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    navRequest.value = NavRequest(0);
  }

  // ------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final e = s.eventById(reg.eventId);
    if (e == null) return const Scaffold(body: Center(child: Text('Kegiatan tidak ditemukan')));

    final dark = isDark(context);
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(fresh ? '' : 'Tiket Saya'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF181212), Color(0xFF1F1414)]
                : const [Color(0xFFFFF7F7), Color(0xFFFFE1E1)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _red.withOpacity(dark ? 0.06 : 0.08)),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _red.withOpacity(dark ? 0.05 : 0.07)),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(wide ? 32 : 16, kToolbarHeight + 8, wide ? 32 : 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: wide ? _wideLayout(context, s, e) : _narrowLayout(context, s, e),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wideLayout(BuildContext context, AppState s, EventModel e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(flex: 4, child: Center(child: _Celebration())),
        const SizedBox(width: 16),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _eventCard(context, e, true),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _qrCard(context, s, e),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _actions(context, e, true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(BuildContext context, AppState s, EventModel e) {
    return Column(
      children: [
        _header(context),
        const SizedBox(height: 16),
        _eventCard(context, e, false),
        const SizedBox(height: 14),
        _qrCard(context, s, e),
        const SizedBox(height: 18),
        _actions(context, e, false),
      ],
    );
  }

  // ------------------------------------------------------------ bagian
  Widget _header(BuildContext context) {
    final dark = isDark(context);
    if (!fresh) {
      return Column(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: _red, size: 40),
          const SizedBox(height: 8),
          Text('Tiket Kehadiran',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: dark ? Colors.white : const Color(0xFF7F1D1D))),
        ],
      );
    }
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.12),
          ),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ),
        ),
        const SizedBox(height: 14),
        Text('Pendaftaran Berhasil!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, color: dark ? Colors.white : const Color(0xFF7F1D1D))),
        const SizedBox(height: 6),
        Text('Terima kasih telah mendaftar pada kegiatan ini.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: muted(context))),
      ],
    );
  }

  Widget _eventCard(BuildContext context, EventModel e, bool wide) {
    final dark = isDark(context);
    Widget row(IconData icon, String text, {bool bold = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFF97316), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, height: 1.3)),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark ? Colors.white12 : const Color(0xFFF8D4D4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                row(Icons.event_available, e.title, bold: true),
                row(Icons.schedule, '${fmtLongDate(e.date)} • ${e.time}'),
                row(Icons.location_on, e.location),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: wide ? 140 : 86,
              height: wide ? 100 : 86,
              child: EventImage(e, width: wide ? 140 : 86, height: wide ? 100 : 86, radius: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCard(BuildContext context, AppState s, EventModel e) {
    final dark = isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? Colors.white12 : const Color(0xFFF3E3E3)),
        boxShadow: [BoxShadow(color: _red.withOpacity(dark ? 0 : 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(data: reg.code, size: 176, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text('Kode Pendaftaran:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFE9E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(reg.code,
                style: const TextStyle(
                    color: _red, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
          ),
          const SizedBox(height: 4),
          Text('Atas nama ${s.user?.name ?? '-'}', style: TextStyle(fontSize: 12, color: muted(context))),
          if (reg.status != RegStatus.registered) ...[
            const SizedBox(height: 8),
            StatusChip(reg.status == RegStatus.attended ? 'Sudah hadir' : 'Dibatalkan',
                reg.status == RegStatus.attended ? AppColors.success : Colors.grey),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _copyCode(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin Kode Pendaftaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFE9E9),
                  foregroundColor: _red,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _shareTicket(context, e),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Bagikan Tiket'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _red,
                  side: BorderSide(color: _red.withOpacity(0.5)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15, color: muted(context)),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Tunjukkan kode ini saat registrasi ulang di lokasi kegiatan.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: muted(context))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, EventModel e, bool wide) {
    final dark = isDark(context);

    final detail = SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _goDetail(context, e),
        icon: const Icon(Icons.event_note_outlined, size: 20),
        label: const Text('Lihat Detail Event'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _red.withOpacity(0.4),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );

    final history = SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _goHistory(context),
        icon: const Icon(Icons.history, size: 20),
        label: const Text('Lihat Riwayat'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _red,
          side: const BorderSide(color: _red, width: 1.4),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );

    final home = SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _goHome(context),
        icon: const Icon(Icons.home_rounded, size: 20),
        label: const Text('Kembali ke Beranda'),
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFE0E0),
          foregroundColor: _red,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: detail),
          const SizedBox(width: 12),
          Expanded(child: history),
          const SizedBox(width: 12),
          Expanded(child: home),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(width: double.infinity, child: detail),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: history),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: home),
      ],
    );
  }
}

// ------------------------------------------------------------ ilustrasi
class _Celebration extends StatelessWidget {
  const _Celebration();

  Widget _bubble(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFD1D1), Color(0xFFFFEEEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 26, offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 92),
          ),
          Positioned(top: 22, left: 40, child: _bubble(Icons.celebration, const Color(0xFFF59E0B), 54)),
          Positioned(top: 44, right: 30, child: _bubble(Icons.favorite, AppColors.primary, 50)),
          Positioned(bottom: 40, left: 30, child: _bubble(Icons.star_rounded, const Color(0xFFF97316), 50)),
          Positioned(bottom: 24, right: 46, child: _bubble(Icons.groups_2, const Color(0xFF2563EB), 56)),
        ],
      ),
    );
  }
}