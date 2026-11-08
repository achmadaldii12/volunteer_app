import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import 'auth_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final s = context.read<AppState>();
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldC, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
          TextField(controller: newC, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru (min. 6)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = s.changePassword(oldC.text, newC.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? 'Password berhasil diubah')));
  }

  Future<void> _reset(BuildContext context) async {
    final s = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset data demo?'),
        content: const Text('Semua akun, pendaftaran, dan notifikasi akan dikembalikan ke data awal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await s.resetData();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(children: [
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Mode Gelap'),
          value: s.themeMode == ThemeMode.dark,
          onChanged: (v) => s.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Ubah Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _changePassword(context),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Reset Data Demo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _reset(context),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Tentang Aplikasi'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Volunteer',
            applicationVersion: '1.0.0',
            applicationIcon: const Icon(Icons.volunteer_activism, color: AppColors.primary, size: 36),
            children: const [Text('Bersama, Kita Memberi Dampak.\nAplikasi kerelawanan berbasis Flutter.')],
          ),
        ),
      ]),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('Bagaimana cara mendaftar kegiatan?', 'Buka tab Cari, pilih kegiatan, lalu tekan "Daftar Sekarang". Tiket QR akan muncul setelah pendaftaran berhasil.'),
      ('Bagaimana cara mendapatkan poin?', 'Poin diberikan setelah kehadiranmu pada sebuah kegiatan tercatat. Jumlah poin berbeda untuk setiap kegiatan.'),
      ('Kapan sertifikat tersedia?', 'Sertifikat tersedia di menu Sertifikat & Feedback setelah kegiatan berstatus Selesai.'),
      ('Bagaimana cara membatalkan pendaftaran?', 'Buka tab Daftar (Aktivitas Saya), pilih kegiatan, lalu pilih "Batalkan Pendaftaran".'),
      ('Bagaimana cara naik peringkat?', 'Ikuti lebih banyak kegiatan untuk mengumpulkan poin. Peringkat dihitung dari total poin.'),
      ('Apa itu badge?', 'Badge adalah penghargaan atas pencapaian, misalnya jumlah kegiatan, jam kontribusi, dan poin.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & FAQ')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        for (final f in faqs)
          ExpansionTile(
            title: Text(f.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedAlignment: Alignment.centerLeft,
            children: [Text(f.$2)],
          ),
      ]),
    );
  }
}
