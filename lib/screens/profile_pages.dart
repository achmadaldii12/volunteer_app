import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';
import '../providers/profile_store.dart';
import 'auth_screens.dart';

// ============================================================
// BAHASA: tx() dipakai di dalam build, txr() dipakai di dalam callback
// ============================================================
String tx(BuildContext c, String id, String en) => c.watch<ProfileStore>().isEnglish ? en : id;
String txr(BuildContext c, String id, String en) => c.read<ProfileStore>().isEnglish ? en : id;

void pSnack(BuildContext c, String m) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
}

const RoundedRectangleBorder kPSheetShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)));

// ============================================================
// KOMPONEN BERSAMA
// ============================================================
class PCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  const PCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final radius = BorderRadius.circular(22);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: dark ? Colors.white.withAlpha(28) : const Color(0xFFFEE2E2)),
        boxShadow: dark
            ? null
            : [BoxShadow(color: AppColors.primary.withAlpha(18), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const PSectionHeader(this.icon, this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      if (action != null)
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(children: [
              Text(action!,
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
            ]),
          ),
        ),
    ]);
  }
}

class PMenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;
  const PMenuTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: danger ? AppColors.danger : null)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(subtitle!, style: TextStyle(fontSize: 11, color: muted(context))),
                ),
            ]),
          ),
          trailing ?? Icon(Icons.chevron_right, color: muted(context)),
        ]),
      ),
    );
  }
}

/// Avatar pengguna: foto profil jika ada, jika tidak inisial nama.
class PAvatar extends StatelessWidget {
  final String userId, name;
  final double size;
  final bool ring;
  const PAvatar(this.userId, this.name, {super.key, this.size = 48, this.ring = false});

  String get _initials {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.first.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = context.watch<ProfileStore>().avatarOf(userId);
    final Widget inner = bytes != null
        ? ClipOval(child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover))
        : Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(_initials,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * .36)),
          );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: inner,
    );
  }
}

// ============================================================
// FOTO PROFIL
// ============================================================
class PhotoResult {
  final Uint8List? bytes;
  final bool remove;
  const PhotoResult._(this.bytes, this.remove);
  factory PhotoResult.picked(Uint8List b) => PhotoResult._(b, false);
  factory PhotoResult.removed() => const PhotoResult._(null, true);
}

/// Menampilkan pilihan galeri / kamera / hapus foto lalu mengembalikan hasilnya.
Future<PhotoResult?> choosePhoto(BuildContext context, {required bool hasPhoto}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    shape: kPSheetShape,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 14),
        Text(tx(sheet, 'Foto Profil', 'Profile Photo'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
          title: Text(tx(sheet, 'Pilih dari galeri', 'Choose from gallery')),
          onTap: () => Navigator.pop(sheet, 'gallery'),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
          title: Text(tx(sheet, 'Ambil foto dengan kamera', 'Take a photo')),
          onTap: () => Navigator.pop(sheet, 'camera'),
        ),
        if (hasPhoto)
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(tx(sheet, 'Hapus foto', 'Remove photo'), style: const TextStyle(color: AppColors.danger)),
            onTap: () => Navigator.pop(sheet, 'remove'),
          ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (choice == null) return null;
  if (choice == 'remove') return PhotoResult.removed();
  try {
    final x = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 85,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return PhotoResult.picked(bytes);
  } catch (_) {
    if (context.mounted) {
      pSnack(context, txr(context, 'Tidak dapat mengakses galeri / kamera di perangkat ini',
          'Cannot access the gallery / camera on this device'));
    }
    return null;
  }
}

// ============================================================
// LOGOUT (dengan dialog konfirmasi)
// ============================================================
Future<void> confirmLogout(BuildContext context) async {
  final s = context.read<AppState>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tx(ctx, 'Konfirmasi Keluar', 'Confirm Logout')),
      content: Text(tx(ctx, 'Apakah kamu yakin ingin keluar dari akun ini?',
          'Are you sure you want to log out of this account?')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx(ctx, 'Batal', 'Cancel'))),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: Text(tx(ctx, 'Keluar', 'Log out')),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  s.logout();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
}

InputDecoration pInput(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

// ============================================================
// EDIT PROFIL
// ============================================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _bio;
  Uint8List? _avatar;
  bool _avatarChanged = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _address = TextEditingController(text: u?.city ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
    if (u != null) _avatar = context.read<ProfileStore>().avatarOf(u.id);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final r = await choosePhoto(context, hasPhoto: _avatar != null);
    if (r == null || !mounted) return;
    setState(() {
      _avatar = r.remove ? null : r.bytes;
      _avatarChanged = true;
    });
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final st = context.read<ProfileStore>();
    final u = s.user;
    if (u == null) return;

    final emailErr = s.updateEmail(_email.text);
    if (emailErr != null) {
      pSnack(context, emailErr);
      return;
    }
    s.updateProfile(name: _name.text, phone: _phone.text, city: _address.text, bio: _bio.text);
    if (_avatarChanged) st.setAvatar(u.id, _avatar);
    Navigator.pop(context);
    pSnack(context, txr(context, 'Profil berhasil diperbarui', 'Profile updated successfully'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    final a = _avatar;

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Edit Profil', 'Edit Profile'))),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _form,
                    child: Column(children: [
                      Center(
                        child: Stack(children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withAlpha(90), width: 3),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: a != null
                                ? ClipOval(child: Image.memory(a, fit: BoxFit.cover))
                                : Container(
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFF7C3AED)]),
                                    ),
                                    child: Text(u.initials,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                                  ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _changePhoto,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _changePhoto,
                        child: Text(tx(context, 'Ganti foto profil', 'Change profile photo')),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _name,
                        decoration: pInput(tx(context, 'Nama lengkap', 'Full name'), Icons.person_outline),
                        validator: (v) => validateRequired(v, txr(context, 'Nama', 'Name')),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: pInput('Email', Icons.email_outlined),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: pInput(tx(context, 'Nomor telepon', 'Phone number'), Icons.phone_outlined),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null;
                          final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
                          return digits.length < 8
                              ? txr(context, 'Nomor telepon tidak valid', 'Invalid phone number')
                              : null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _address,
                        decoration: pInput(tx(context, 'Alamat / kota', 'Address / city'), Icons.location_city_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bio,
                        maxLines: 3,
                        maxLength: 120,
                        decoration: pInput(tx(context, 'Deskripsi singkat', 'Short bio'), Icons.edit_note),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(tx(context, 'Batalkan', 'Cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(tx(context, 'Simpan', 'Save'),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// KEAMANAN & PRIVASI
// ============================================================
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  String _platformName() {
    if (kIsWeb) return 'Browser (Web)';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Perangkat ini';
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final s = context.read<AppState>();
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'Ganti Password', 'Change Password')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: oldC,
              obscureText: true,
              decoration: InputDecoration(labelText: tx(ctx, 'Password lama', 'Current password')),
            ),
            TextField(
              controller: newC,
              obscureText: true,
              decoration: InputDecoration(labelText: tx(ctx, 'Password baru (min. 6)', 'New password (min. 6)')),
            ),
            TextField(
              controller: confC,
              obscureText: true,
              decoration: InputDecoration(labelText: tx(ctx, 'Ulangi password baru', 'Repeat new password')),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx(ctx, 'Batal', 'Cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(tx(ctx, 'Simpan', 'Save')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (newC.text != confC.text) {
      pSnack(context, txr(context, 'Konfirmasi password baru tidak sama', 'New password confirmation does not match'));
      return;
    }
    final err = s.changePassword(oldC.text, newC.text);
    pSnack(context, err ?? txr(context, 'Password berhasil diubah', 'Password changed successfully'));
  }

  Future<void> _verifyEmail(BuildContext context) async {
    final s = context.read<AppState>();
    final st = context.read<ProfileStore>();
    final u = s.user;
    if (u == null) return;
    final code = (100000 + Random().nextInt(900000)).toString();
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'Verifikasi Email', 'Verify Email')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.email, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tx(ctx, 'Mode demo (belum ada server email). Kode verifikasimu: $code',
                  'Demo mode (no email server yet). Your verification code: $code'),
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(labelText: tx(ctx, 'Masukkan kode 6 digit', 'Enter the 6-digit code')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx(ctx, 'Batal', 'Cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(tx(ctx, 'Verifikasi', 'Verify')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (c.text.trim() == code) {
      st.setEmailVerified(u.id, u.email);
      pSnack(context, txr(context, 'Email berhasil diverifikasi', 'Email verified successfully'));
    } else {
      pSnack(context, txr(context, 'Kode salah, coba lagi', 'Wrong code, please try again'));
    }
  }

  Future<void> _editPhone(BuildContext context) async {
    final s = context.read<AppState>();
    final u = s.user;
    if (u == null) return;
    final c = TextEditingController(text: u.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'Nomor Telepon', 'Phone Number')),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx(ctx, 'Batal', 'Cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(tx(ctx, 'Simpan', 'Save')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final digits = c.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (c.text.trim().isNotEmpty && digits.length < 8) {
      pSnack(context, txr(context, 'Nomor telepon tidak valid', 'Invalid phone number'));
      return;
    }
    s.updateProfile(phone: c.text);
    pSnack(context, txr(context, 'Nomor telepon disimpan', 'Phone number saved'));
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final s = context.read<AppState>();
    final st = context.read<ProfileStore>();
    final u = s.user;
    if (u == null) return;
    final id = u.id;
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'Hapus Akun?', 'Delete Account?'),
            style: const TextStyle(color: AppColors.danger)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            tx(ctx,
                'Seluruh data akunmu (pendaftaran, poin, riwayat, dan pesan komunitas) akan dihapus permanen dan tidak dapat dikembalikan.',
                'All your account data (registrations, points, history and community messages) will be permanently deleted and cannot be restored.'),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: c,
            obscureText: true,
            decoration: InputDecoration(labelText: tx(ctx, 'Masukkan password untuk konfirmasi', 'Enter your password to confirm')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tx(ctx, 'Batal', 'Cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: Text(tx(ctx, 'Hapus Akun', 'Delete Account')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = s.deleteAccount(c.text);
    if (err != null) {
      pSnack(context, err);
      return;
    }
    st.clearUser(id);
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final u = s.user;
    final verified = u != null && st.emailVerified(u.id, u.email);

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Keamanan & Privasi', 'Security & Privacy'))),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    PCard(
                      child: Column(children: [
                        PMenuTile(
                          icon: Icons.lock_outline,
                          color: AppColors.primary,
                          title: tx(context, 'Ganti Password', 'Change Password'),
                          subtitle: tx(context, 'Ubah password akunmu', 'Update your account password'),
                          onTap: () => _changePassword(context),
                        ),
                        PMenuTile(
                          icon: Icons.mark_email_read_outlined,
                          color: const Color(0xFF2563EB),
                          title: tx(context, 'Verifikasi Email', 'Verify Email'),
                          subtitle: u.email,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (verified ? AppColors.success : AppColors.warning).withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              verified ? tx(context, 'Terverifikasi', 'Verified') : tx(context, 'Belum', 'Not yet'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: verified ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                          onTap: () {
                            if (verified) {
                              pSnack(context, txr(context, 'Email kamu sudah terverifikasi', 'Your email is already verified'));
                            } else {
                              _verifyEmail(context);
                            }
                          },
                        ),
                        PMenuTile(
                          icon: Icons.phone_outlined,
                          color: const Color(0xFF15803D),
                          title: tx(context, 'Kelola Nomor Telepon', 'Manage Phone Number'),
                          subtitle: u.phone.isEmpty ? tx(context, 'Belum diisi', 'Not set') : u.phone,
                          onTap: () => _editPhone(context),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    PCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        PSectionHeader(Icons.devices_outlined, tx(context, 'Sesi Login', 'Login Sessions')),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.verified_user_outlined, color: AppColors.success),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${_platformName()} • ${tx(context, 'Perangkat ini', 'This device')}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(
                                '${tx(context, 'Aktif sejak', 'Active since')} ${fmtDateTime(st.sessionStart)}',
                                style: TextStyle(fontSize: 11, color: muted(context)),
                              ),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => confirmLogout(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: Text(tx(context, 'Keluar dari sesi ini', 'Log out of this session')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    PCard(
                      child: PMenuTile(
                        icon: Icons.delete_forever_outlined,
                        color: AppColors.danger,
                        title: tx(context, 'Hapus Akun', 'Delete Account'),
                        subtitle: tx(context, 'Hapus akun dan seluruh datamu secara permanen',
                            'Permanently delete your account and all data'),
                        danger: true,
                        onTap: () => _deleteAccount(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tx(context,
                          'Data akunmu disimpan di perangkat ini. Email dan nomor telepon tidak ditampilkan kepada anggota lain.',
                          'Your account data is stored on this device. Your email and phone number are never shown to other members.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: muted(context), height: 1.4),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }
}

// ============================================================
// PENGATURAN NOTIFIKASI
// ============================================================
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final u = s.user;

    final items = <(String, IconData, String, String, String, String)>[
      ('event', Icons.campaign_outlined, 'Notifikasi event terbaru', 'New event notifications',
          'Info kegiatan baru dan informasi umum', 'New activities and general information'),
      ('reminder', Icons.alarm, 'Pengingat kegiatan', 'Activity reminders',
          'Pendaftaran dan pembatalan kegiatan', 'Registration and cancellation updates'),
      ('community', Icons.forum_outlined, 'Pesan komunitas', 'Community messages',
          'Pesan baru, balasan, dan undangan event', 'New messages, replies and event invitations'),
      ('announce', Icons.record_voice_over_outlined, 'Pengumuman', 'Announcements',
          'Pengumuman resmi dari admin', 'Official announcements from admin'),
      ('points', Icons.stars_outlined, 'Pemberitahuan poin', 'Point notifications',
          'Poin masuk setelah kehadiran diverifikasi', 'Points received after attendance is verified'),
      ('badge', Icons.emoji_events_outlined, 'Achievement baru', 'New achievements',
          'Badge, level baru, dan target tercapai', 'Badges, new levels and reached goals'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Pengaturan Notifikasi', 'Notification Settings'))),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(children: [
                    PCard(
                      child: Column(children: [
                        for (final it in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(24), shape: BoxShape.circle),
                                child: Icon(it.$2, color: AppColors.primary, size: 21),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(st.isEnglish ? it.$4 : it.$3,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  Text(st.isEnglish ? it.$6 : it.$5,
                                      style: TextStyle(fontSize: 11, color: muted(context))),
                                ]),
                              ),
                              Switch(
                                value: st.notifOn(u.id, it.$1),
                                activeColor: AppColors.primary,
                                onChanged: (v) => st.setNotif(u.id, it.$1, v),
                              ),
                            ]),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tx(context,
                          'Notifikasi yang dimatikan tidak akan tampil di daftar Notifikasi.',
                          'Notifications you turn off will not appear in the Notifications list.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: muted(context)),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }
}

// ============================================================
// BAHASA
// ============================================================
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<ProfileStore>();
    Widget option(String code, String label, String sub) {
      final selected = st.language == code;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          st.setLanguage(code);
          pSnack(context, code == 'en' ? 'Language set to English' : 'Bahasa diubah ke Indonesia');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : muted(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(sub, style: TextStyle(fontSize: 11, color: muted(context))),
              ]),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Bahasa', 'Language'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Column(children: [
                  option('id', 'Bahasa Indonesia', 'Indonesia'),
                  const Divider(height: 1),
                  option('en', 'English', 'Bahasa Inggris'),
                ]),
              ),
              const SizedBox(height: 12),
              Text(
                tx(context,
                    'Pilihan bahasa disimpan dan diterapkan pada halaman Profil beserta seluruh menu di dalamnya. '
                        'Halaman lain masih memakai teks Bahasa Indonesia karena teksnya belum diterjemahkan.',
                    'Your language choice is saved and applied to the Profile page and all of its menus. '
                        'Other pages still use Indonesian text because they are not translated yet.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: muted(context), height: 1.4),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// AKSESIBILITAS
// ============================================================
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<ProfileStore>();

    Widget switchRow(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text(sub, style: TextStyle(fontSize: 11, color: muted(context))),
            ]),
          ),
          Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tx(context, 'Aksesibilitas', 'Accessibility'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [
              PCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PSectionHeader(Icons.text_fields, tx(context, 'Ukuran Tulisan', 'Text Size')),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: st.textScale,
                        min: 0.85,
                        max: 1.4,
                        divisions: 11,
                        activeColor: AppColors.primary,
                        label: '${(st.textScale * 100).round()}%',
                        onChanged: st.setTextScale,
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
                  Text(
                    tx(context, 'Contoh teks: Bersama, Kita Memberi Dampak.', 'Sample text: Together, We Make an Impact.'),
                    style: TextStyle(color: muted(context)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => st.setTextScale(1.0),
                      child: Text(tx(context, 'Atur ulang', 'Reset')),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              PCard(
                child: Column(children: [
                  switchRow(
                    Icons.contrast,
                    tx(context, 'Kontras tinggi', 'High contrast'),
                    tx(context, 'Teks dan garis lebih tegas', 'Sharper text and borders'),
                    st.highContrast,
                    st.setHighContrast,
                  ),
                  const Divider(height: 14),
                  switchRow(
                    Icons.record_voice_over_outlined,
                    tx(context, 'Dukungan pembaca layar', 'Screen reader support'),
                    tx(context, 'Area sentuh lebih besar & ramah TalkBack / VoiceOver',
                        'Larger touch areas, friendly to TalkBack / VoiceOver'),
                    st.screenReader,
                    st.setScreenReader,
                  ),
                  const Divider(height: 14),
                  switchRow(
                    Icons.animation,
                    tx(context, 'Kurangi animasi', 'Reduce animations'),
                    tx(context, 'Matikan gerakan dan transisi berlebih', 'Turn off extra motion and transitions'),
                    st.reduceMotion,
                    st.setReduceMotion,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Text(
                tx(context, 'Pengaturan ini berlaku untuk seluruh halaman aplikasi dan tersimpan otomatis.',
                    'These settings apply to the whole app and are saved automatically.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: muted(context)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}