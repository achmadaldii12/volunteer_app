import 'package:flutter/material.dart';
import '../core/nav_bus.dart';
import 'motion.dart';

// ============================================================================
// Tombol logo Volunteer (tanpa kotak latar).
// Ditaruh di pojok kiri atas halaman Event, Riwayat, Komunitas, dan Profil.
// Saat diketuk -> kembali ke tab Beranda (lewat navRequest yang sudah ada).
// Tidak mengubah backend dan tidak mengubah logika aplikasi.
// ============================================================================
class AppLogoButton extends StatelessWidget {
  const AppLogoButton({super.key, this.size = 44, this.onDark = false});

  /// Ukuran area logo (px).
  final double size;

  /// true jika dipasang di atas latar merah (mis. AppBar halaman Profil):
  /// logo ditampilkan putih polos supaya jelas terbaca.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset('assets/image/logo_volunteer.png', fit: BoxFit.contain);
    if (onDark) {
      logo = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: logo,
      );
    }

    return Tooltip(
      message: 'Kembali ke Beranda',
      child: HoverLift(
        scale: 1.1,
        lift: 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => navRequest.value = NavRequest(0), // 0 = Beranda
          child: SizedBox(
            width: size,
            height: size,
            // gambar logo punya ruang kosong di tepinya, jadi diperbesar
            // sedikit agar logo tampak sebesar ukuran yang diminta
            child: Transform.scale(scale: 1.9, child: logo),
          ),
        ),
      ),
    );
  }
}