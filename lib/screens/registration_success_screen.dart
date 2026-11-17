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
    final desktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(fresh ? '' : 'Tiket Saya', style: const TextStyle(fontWeight: FontWeight.w800)),
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
              top: -70,
              right: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _red.withOpacity(dark ? 0.06 : 0.08)),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -70,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _red.withOpacity(dark ? 0.05 : 0.07)),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(desktop ? 32 : 16, 16, desktop ? 32 : 16, 28),
                  child: desktop ? _desktopLayout(context, s, e) : _mobileLayout(context, s, e),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ layout laptop / desktop
  Widget _desktopLayout(BuildContext context, AppState s, EventModel e) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandHeader(context, big: true),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _eventCardTall(context, e)),
              const SizedBox(width: 22),
              Expanded(flex: 5, child: _qrCard(context, s, e)),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: _actions(context, e, true),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ layout HP / tablet
  Widget _mobileLayout(BuildContext context, AppState s, EventModel e) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandHeader(context, big: false),
          const SizedBox(height: 20),
          _eventCardCompact(context, e),
          const SizedBox(height: 14),
          _qrCard(context, s, e),
          const SizedBox(height: 18),
          _actions(context, e, false),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ bagian
  Widget _logo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD6D6), width: 3),
        boxShadow: [BoxShadow(color: _red.withOpacity(0.22), blurRadius: 26, offset: const Offset(0, 10))],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/image/logo_volunteer.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.volunteer_activism, color: AppColors.primary, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _brandHeader(BuildContext context, {required bool big}) {
    final dark = isDark(context);
    final size = big ? 116.0 : 100.0;
    final titleColor = dark ? Colors.white : const Color(0xFF7F1D1D);

    final label = reg.status == RegStatus.registered
        ? 'Terdaftar'
        : reg.status == RegStatus.attended
            ? 'Sudah hadir'
            : 'Dibatalkan';
    final color = reg.status == RegStatus.registered
        ? AppColors.success
        : reg.status == RegStatus.attended
            ? _red
            : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + 14,
          height: size + 14,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _logo(size),
              if (fresh)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          fresh ? 'Pendaftaran Berhasil!' : 'Tiket Kehadiran',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: big ? 30 : 24, fontWeight: FontWeight.w800, color: titleColor),
        ),
        const SizedBox(height: 6),
        Text(
          fresh ? 'Terima kasih telah mendaftar pada kegiatan ini.' : 'Simpan tiket ini untuk registrasi ulang di lokasi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: muted(context)),
        ),
        if (!fresh) ...[
          const SizedBox(height: 10),
          StatusChip(label, color),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF97316), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: bold ? 16 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _pinkCard(bool dark) => BoxDecoration(
        color: dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? Colors.white12 : const Color(0xFFF8D4D4)),
      );

  // Kartu event untuk layar lebar: foto di atas, info di bawah (tanpa Expanded)
  Widget _eventCardTall(BuildContext context, EventModel e) {
    final dark = isDark(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _pinkCard(dark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: EventImage(e, width: double.infinity, height: 220, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.event_available, e.title, bold: true),
                _infoRow(Icons.schedule, '${fmtLongDate(e.date)} • ${e.time}'),
                _infoRow(Icons.location_on, e.location),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kartu event untuk HP: info di kiri, foto kecil di kanan
  Widget _eventCardCompact(BuildContext context, EventModel e) {
    final dark = isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _pinkCard(dark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.event_available, e.title, bold: true),
                _infoRow(Icons.schedule, '${fmtLongDate(e.date)} • ${e.time}'),
                _infoRow(Icons.location_on, e.location),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 84,
              height: 84,
              child: EventImage(e, width: 84, height: 84, radius: 16),
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
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? Colors.white12 : const Color(0xFFF3E3E3)),
        boxShadow: [BoxShadow(color: _red.withOpacity(dark ? 0 : 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(data: reg.code, size: 180, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text('Kode Pendaftaran:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFE9E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reg.code,
              style: const TextStyle(color: _red, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text('Atas nama ${s.user?.name ?? '-'}', style: TextStyle(fontSize: 12, color: muted(context))),
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
                child: Text(
                  'Tunjukkan kode ini saat registrasi ulang di lokasi kegiatan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: muted(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, EventModel e, bool row) {
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

    if (row) {
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