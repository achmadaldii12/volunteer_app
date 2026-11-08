import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'achievement_screen.dart';
import 'auth_screens.dart';
import 'certificate_screen.dart';
import 'impact_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    final primary = Theme.of(context).colorScheme.primary;
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    Widget row(IconData i, String t, VoidCallback onTap, {String? trailing}) => ListTile(
          leading: Icon(i, color: primary),
          title: Text(t, style: const TextStyle(fontSize: 14)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (trailing != null) Text(trailing, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right),
          ]),
          onTap: onTap,
        );

    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 6),
      Center(
        child: CircleAvatar(
          radius: 44,
          backgroundColor: softOf(context),
          child: Text(u?.initials ?? '?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: primary)),
        ),
      ),
      const SizedBox(height: 10),
      Center(child: Text(u?.name ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      Center(child: Text(u?.email ?? '', style: TextStyle(color: muted(context)))),
      if ((u?.city ?? '').isNotEmpty)
        Center(child: Text(u!.city, style: TextStyle(fontSize: 12, color: muted(context)))),
      const SizedBox(height: 12),
      Center(
          child: SizedBox(
              width: 200,
              child: PrimaryButton('Edit Profil', light: true, onTap: () => open(const EditProfileScreen())))),
      const SizedBox(height: 14),
      row(Icons.stars_outlined, 'Poin Saya', () => open(const AchievementScreen()), trailing: fmtNum(s.totalPoints)),
      row(Icons.emoji_events_outlined, 'Achievement', () => open(const AchievementScreen()),
          trailing: '${s.earnedBadges.length} Badge'),
      row(Icons.favorite_border, 'Dampak Sosial', () => open(const ImpactScreen())),
      row(Icons.history, 'Riwayat Kegiatan', () => open(const HistoryScreen())),
      row(Icons.workspace_premium_outlined, 'Sertifikat & Feedback', () => open(const CertificateScreen())),
      row(Icons.settings_outlined, 'Pengaturan', () => open(const SettingsScreen())),
      row(Icons.help_outline, 'Bantuan & FAQ', () => open(const HelpScreen())),
      ListTile(
        leading: Icon(Icons.logout, color: primary),
        title: const Text('Keluar', style: TextStyle(fontSize: 14)),
        onTap: () {
          s.logout();
          Navigator.pushAndRemoveUntil(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        },
      ),
    ]);
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _city, _bio;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _name = TextEditingController(text: u?.name ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _city = TextEditingController(text: u?.city ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(children: [
            AppTextField('Nama Lengkap', Icons.person_outline,
                controller: _name, validator: (v) => validateRequired(v, 'Nama')),
            AppTextField('Email', Icons.mail_outline,
                controller: TextEditingController(text: s.user?.email ?? ''), enabled: false),
            AppTextField('No. Telepon', Icons.phone_outlined, controller: _phone, keyboard: TextInputType.phone),
            AppTextField('Kota', Icons.location_city_outlined, controller: _city),
            AppTextField('Tentang saya', Icons.info_outline, controller: _bio, maxLines: 3),
            const SizedBox(height: 6),
            PrimaryButton('Simpan Perubahan', onTap: () {
              if (!_form.currentState!.validate()) return;
              s.updateProfile(name: _name.text, phone: _phone.text, city: _city.text, bio: _bio.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
              Navigator.pop(context);
            }),
          ]),
        ),
      ),
    );
  }
}
