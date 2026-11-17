import 'package:flutter/foundation.dart';

/// Permintaan pindah halaman utama (tab) dari halaman mana pun.
/// tab: 0 Beranda, 1 Event, 2 Riwayat, 3 Komunitas, 4 Profil
/// subTab: khusus Riwayat -> 0 Mengikuti, 1 Selesai
/// highlightRegId: id pendaftaran yang ingin disorot di Riwayat
class NavRequest {
  final int tab;
  final int subTab;
  final String? highlightRegId;
  NavRequest(this.tab, {this.subTab = 0, this.highlightRegId});
}

/// Setiap kali diisi objek NavRequest baru, MainShell pindah tab
/// dan halaman Riwayat membuka sub-tab yang diminta.
final ValueNotifier<NavRequest?> navRequest = ValueNotifier<NavRequest?>(null);