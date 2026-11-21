import 'package:flutter/material.dart';
import '../core/nav_bus.dart';
import 'motion.dart';

// ============================================================================
// FILE BARU: tombol logo Volunteer.
// Ditaruh di pojok kiri atas halaman Event, Riwayat, Komunitas, dan Profil.
// Saat diketuk -> kembali ke tab Beranda (lewat navRequest yang sudah ada).
// Tidak mengubah backend dan tidak mengubah logika aplikasi.
// ============================================================================
class AppLogoButton extends StatelessWidget {
  const AppLogoButton({super.key, this.size = 44, this.onDark = false});

  /// Ukuran kotak logo (px).
  final double size;

  /// true jika dipasang di atas latar merah (mis. AppBar halaman Profil).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Kembali ke Beranda',
      child: HoverLift(
        scale: 1.1,
        lift: 2,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => navRequest.value = NavRequest(0), // 0 = Beranda
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: onDark ? Colors.white.withAlpha(150) : Colors.grey.withAlpha(60),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              // zoom yang sama seperti logo di Beranda
              child: Transform.scale(
                scale: 2.0,
                child: Image.asset('assets/image/logo_volunteer.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}