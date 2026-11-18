import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../org_widgets.dart';
import '../organizer_store.dart';

class OrgProfilePage extends StatefulWidget {
  const OrgProfilePage({super.key});
  @override
  State<OrgProfilePage> createState() => _OrgProfilePageState();
}

class _OrgProfilePageState extends State<OrgProfilePage> {
  late final TextEditingController _name, _desc, _addr, _email, _phone, _social, _pj;
  String _cat = 'Sosial', _pic = '';

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final p = OrgStore.instance.profileOf(s.user!);
    _name = TextEditingController(text: p.name);
    _desc = TextEditingController(text: p.desc);
    _addr = TextEditingController(text: p.address);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _social = TextEditingController(text: p.social);
    _pj = TextEditingController(text: p.pj);
    _cat = p.category;
    _pic = p.pic;
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _addr, _email, _phone, _social, _pj]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 75);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _pic = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) toast(context, 'Gagal memilih gambar');
    }
  }

  void _save() {
    if (_name.text.trim().isEmpty) return toast(context, 'Nama organisasi wajib diisi');
    final s = context.read<AppState>();
    OrgStore.instance.saveProfile(
      s,
      s.user!,
      OrgProfile(name: _name.text, desc: _desc.text, category: _cat, address: _addr.text, email: _email.text, phone: _phone.text, social: _social.text, pic: _pic, pj: _pj.text),
    );
    toast(context, 'Profil organisasi disimpan');
  }

  @override
  Widget build(BuildContext context) {
    Widget f(TextEditingController c, String l, IconData i, {int lines = 1}) => TextField(controller: c, minLines: lines, maxLines: lines, decoration: fieldDeco(l, icon: i));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHead('Profil Organisasi', 'Informasi ini tampil pada detail event di aplikasi relawan', actions: [
        ElevatedButton.icon(onPressed: _save, style: redBtn(), icon: const Icon(Icons.save_rounded, size: 18), label: const Text('Simpan')),
      ]),
      OrgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(initialsOf(_name.text), size: 84, pic: _pic),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Logo organisasi', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              OutlinedButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.upload_rounded, size: 16), label: const Text('Unggah logo')),
            ]),
          ]),
          const SizedBox(height: 18),
          Grid([
            f(_name, 'Nama organisasi', Icons.apartment_rounded),
            f(_pj, 'Nama penanggung jawab', Icons.badge_outlined),
            f(_email, 'Email', Icons.mail_outline),
            f(_phone, 'Nomor telepon', Icons.phone_outlined),
          ], minWidth: 280, gap: 12),
          const SizedBox(height: 12),
          const Text('Kategori organisasi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in kCategories)
              ChoiceChip(label: Text(k.name), selected: _cat == k.name, selectedColor: k.color, labelStyle: TextStyle(color: _cat == k.name ? Colors.white : Colors.black87, fontWeight: FontWeight.w600), onSelected: (_) => setState(() => _cat = k.name)),
          ]),
          const SizedBox(height: 12),
          f(_desc, 'Deskripsi organisasi', Icons.notes_rounded, lines: 3),
          const SizedBox(height: 12),
          f(_addr, 'Alamat', Icons.place_outlined, lines: 2),
          const SizedBox(height: 12),
          f(_social, 'Media sosial (mis. @volunteer.id)', Icons.share_outlined),
        ]),
      ),
    ]);
  }
}