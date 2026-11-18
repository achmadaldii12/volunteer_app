import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _old = TextEditingController(), _new = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHead('Pengaturan', 'Preferensi akun dan dashboard penyelenggara'),
      OrgSection(
        title: 'Akun',
        icon: Icons.manage_accounts_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.email, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Text('Akun penyelenggara dibuat oleh administrator dan tidak dapat didaftarkan sendiri.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          Grid([
            TextField(controller: _old, obscureText: true, decoration: fieldDeco('Password lama', icon: Icons.lock_outline)),
            TextField(controller: _new, obscureText: true, decoration: fieldDeco('Password baru (min. 6)', icon: Icons.lock_reset_rounded)),
          ], minWidth: 260, gap: 12),
          const SizedBox(height: 12),
          ElevatedButton(
            style: redBtn(),
            onPressed: () {
              final er = s.changePassword(_old.text, _new.text);
              if (er == null) {
                _old.clear();
                _new.clear();
              }
              toast(context, er ?? 'Password berhasil diubah');
            },
            child: const Text('Ubah Password'),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      OrgSection(
        title: 'Preferensi',
        icon: Icons.tune_rounded,
        child: Column(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text('Event baru perlu persetujuan'),
            subtitle: const Text('Nilai awal untuk event yang kamu buat (bisa diubah per event).', style: TextStyle(fontSize: 12)),
            value: org.defaultApproval,
            onChanged: (v) => org.setFlags(approval: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text('Tampilkan lencana pendaftar baru'),
            value: org.notifNewReg,
            onChanged: (v) => org.setFlags(newReg: v),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () => s.logout(), icon: const Icon(Icons.logout_rounded), label: const Text('Keluar dari akun')),
    ]);
  }
}
