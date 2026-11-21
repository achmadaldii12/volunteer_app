import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// FILE BARU: tema "Kuning" (hangat, kekuningan) untuk aplikasi Volunteer.
//
// Cara kerja:
//  - Dipilih dari Profil > Pengaturan Akun > Tampilan Aplikasi (ikon palet).
//  - Dasarnya tetap tema Terang. Semua warna aplikasi diberi nuansa kuning
//    krem lewat filter warna lembut, jadi putih -> krem kekuningan dan merah muda
//    -> krem hangat, tanpa mengubah file tampilan satu per satu.
//  - Pilihan disimpan di perangkat (SharedPreferences), jadi tetap aktif saat
//    aplikasi dibuka lagi.
//  - Dashboard penyelenggara dan tema Gelap tidak terpengaruh.
// Tidak mengubah backend dan tidak mengubah logika aplikasi.
// ============================================================================
class WarmTheme {
  WarmTheme._();

  /// true = tema Kuning aktif.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static const String _key = 'pf_warm_theme';

  /// Dipanggil sekali di main() sebelum runApp.
  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_key) ?? false;
    } catch (_) {}
  }

  /// Menyalakan / mematikan tema Kuning (dan menyimpannya).
  static Future<void> set(bool value) async {
    enabled.value = value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, value);
    } catch (_) {}
  }

  /// Matriks warna: sedikit mengurangi biru (dan hijau) -> putih menjadi krem kuning.
  /// Ubah 0.86 (biru) agar lebih kuning (mis. 0.80) atau lebih pucat (mis. 0.92).
  static const ColorFilter filter = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, // merah
    0, 0.985, 0, 0, 0, // hijau
    0, 0, 0.86, 0, 0, // biru
    0, 0, 0, 1, 0, // alpha
  ]);

  /// Membungkus [child] dengan filter tema Kuning.
  static Widget wrap(Widget child) => ColorFiltered(colorFilter: filter, child: child);
}