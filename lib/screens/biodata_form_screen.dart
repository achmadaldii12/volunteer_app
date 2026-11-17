import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/profile_store.dart';
import '../widgets/common.dart';
import 'profile_pages.dart' show choosePhoto;
import 'registration_screens.dart' show finishRegistration, PaymentScreen;

// ============================================================
// BIODATA RELAWAN (formulir bertahap 4 langkah)
// ============================================================
class BiodataRelawanScreen extends StatefulWidget {
  final EventModel event;
  const BiodataRelawanScreen(this.event, {super.key});

  @override
  State<BiodataRelawanScreen> createState() => _BiodataRelawanScreenState();
}

class _Opt {
  final String label;
  final IconData icon;
  const _Opt(this.label, this.icon);
}

const List<_Opt> _kInterests = [
  _Opt('Pendidikan', Icons.menu_book_outlined),
  _Opt('Lingkungan', Icons.eco_outlined),
  _Opt('Sosial', Icons.volunteer_activism_outlined),
  _Opt('Kemanusiaan', Icons.favorite_border),
  _Opt('Kesehatan', Icons.medical_services_outlined),
  _Opt('Teknologi', Icons.computer_outlined),
];

const List<_Opt> _kSkills = [
  _Opt('Mengajar', Icons.school_outlined),
  _Opt('Desain Grafis', Icons.brush_outlined),
  _Opt('Fotografi', Icons.photo_camera_outlined),
  _Opt('Public Speaking', Icons.mic_none),
  _Opt('Pertolongan Pertama', Icons.healing_outlined),
  _Opt('Administrasi', Icons.assignment_outlined),
  _Opt('Logistik', Icons.inventory_2_outlined),
  _Opt('Penulisan', Icons.edit_outlined),
];

const List<String> _kEducation = ['SD/SMP', 'SMA/SMK', 'D3', 'S1', 'S2', 'S3'];
const List<String> _kTimes = ['Pagi (06.00-11.00)', 'Siang (11.00-15.00)', 'Sore (15.00-18.00)', 'Malam (18.00-21.00)'];
const List<String> _kDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const List<String> _kStepTitles = ['Data Pribadi', 'Minat & Keahlian', 'Pengalaman', 'Konfirmasi'];

class _BiodataRelawanScreenState extends State<BiodataRelawanScreen> {
  static const Color _red = AppColors.primary;

  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  int _step = 0;
  bool _forward = true;
  bool _saving = false;
  bool _agree = false;
  String _status = ''; // '', 'draft', atau 'complete'

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  final _birth = TextEditingController();
  final _emgName = TextEditingController();
  final _emgPhone = TextEditingController();
  final _skillOther = TextEditingController();
  final _field = TextEditingController();
  final _orgName = TextEditingController();
  final _orgRole = TextEditingController();
  final _socialExp = TextEditingController();
  final _expDesc = TextEditingController();
  final _motivation = TextEditingController();
  final _target = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  String? _education;
  bool? _hasExp;
  final Set<String> _interests = {};
  final Set<String> _skills = {};
  final Set<String> _times = {};
  final Set<String> _days = {};

  Uint8List? _avatar;
  bool _avatarChanged = false;

  List<TextEditingController> get _all => [
        _name, _email, _phone, _city, _birth, _emgName, _emgPhone, _skillOther,
        _field, _orgName, _orgRole, _socialExp, _expDesc, _motivation, _target,
      ];

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _city = TextEditingController(text: u?.city ?? '');
    for (final c in _all) {
      c.addListener(_refresh);
    }
    _loadSaved();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.removeListener(_refresh);
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ penyimpanan
  String _key(String uid) => 'biodata_$uid';

  List<String> _asList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

  void _setText(TextEditingController c, dynamic v) {
    final s = (v ?? '').toString();
    if (s.isNotEmpty) c.text = s;
  }

  Future<void> _loadSaved() async {
    final app = context.read<AppState>();
    final store = context.read<ProfileStore>();
    final uid = app.user?.id;
    if (uid == null) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(uid));
    final avatar = store.avatarOf(uid);
    if (!mounted) return;
    setState(() {
      _avatar = avatar;
      if (raw == null) return;
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _status = (m['status'] ?? '') as String;
        _setText(_name, m['name']);
        _setText(_email, m['email']);
        _setText(_phone, m['phone']);
        _setText(_city, m['city']);
        _setText(_emgName, m['emgName']);
        _setText(_emgPhone, m['emgPhone']);
        _setText(_skillOther, m['skillOther']);
        _setText(_field, m['field']);
        _setText(_orgName, m['orgName']);
        _setText(_orgRole, m['orgRole']);
        _setText(_socialExp, m['socialExp']);
        _setText(_expDesc, m['expDesc']);
        _setText(_motivation, m['motivation']);
        _setText(_target, m['target']);
        final g = m['gender'];
        if (g == 'Laki-laki' || g == 'Perempuan') _gender = g as String;
        final b = m['birth'];
        if (b is String && b.isNotEmpty) {
          _birthDate = DateTime.tryParse(b);
          if (_birthDate != null) _birth.text = fmtLongDate(_birthDate!);
        }
        final edu = m['education'];
        if (edu is String && _kEducation.contains(edu)) _education = edu;
        if (m['hasExp'] is bool) _hasExp = m['hasExp'] as bool;
        _interests.addAll(_asList(m['interests']));
        _skills.addAll(_asList(m['skills']));
        _times.addAll(_asList(m['times']));
        _days.addAll(_asList(m['days']));
      } catch (_) {
        // data rusak diabaikan, formulir mulai dari data akun
      }
    });
  }

  Map<String, dynamic> _toJson(String status) => {
        'status': status,
        'savedAt': DateTime.now().toIso8601String(),
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'city': _city.text.trim(),
        'gender': _gender,
        'birth': _birthDate?.toIso8601String(),
        'emgName': _emgName.text.trim(),
        'emgPhone': _emgPhone.text.trim(),
        'interests': _interests.toList(),
        'skills': _skills.toList(),
        'skillOther': _skillOther.text.trim(),
        'education': _education,
        'field': _field.text.trim(),
        'times': _times.toList(),
        'days': _days.toList(),
        'hasExp': _hasExp,
        'orgName': _orgName.text.trim(),
        'orgRole': _orgRole.text.trim(),
        'socialExp': _socialExp.text.trim(),
        'expDesc': _expDesc.text.trim(),
        'motivation': _motivation.text.trim(),
        'target': _target.text.trim(),
      };

  Future<void> _persist(String status) async {
    final app = context.read<AppState>();
    final store = context.read<ProfileStore>();
    final uid = app.user?.id;
    if (uid == null) throw Exception('Sesi berakhir');
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(uid), jsonEncode(_toJson(status)));
    if (_avatarChanged) {
      store.setAvatar(uid, _avatar);
      _avatarChanged = false;
    }
    _status = status;
  }

  Future<void> _saveDraft({bool silent = false}) async {
    try {
      await _persist(_status == 'complete' ? 'complete' : 'draft');
      if (!mounted) return;
      if (!silent) _snack('Biodata disimpan sementara');
    } catch (_) {
      if (mounted && !silent) _snack('Gagal menyimpan biodata, coba lagi');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  // -------------------------------------------------------------- validasi
  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'No. WhatsApp wajib diisi';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 15) return 'No. WhatsApp tidak valid';
    return null;
  }

  String? _step0Error() {
    return validateRequired(_name.text, 'Nama lengkap') ??
        validateEmail(_email.text) ??
        _validatePhone(_phone.text) ??
        (_gender == null ? 'Pilih jenis kelamin' : null) ??
        validateRequired(_birth.text, 'Tanggal lahir') ??
        validateRequired(_city.text, 'Kota / alamat') ??
        validateRequired(_emgName.text, 'Nama kontak darurat') ??
        validateRequired(_emgPhone.text, 'No. telepon kontak darurat');
  }

  int get _percent {
    final checks = <bool>[
      _avatar != null,
      _name.text.trim().isNotEmpty,
      validateEmail(_email.text) == null,
      _validatePhone(_phone.text) == null,
      _gender != null,
      _birthDate != null,
      _city.text.trim().isNotEmpty,
      _emgName.text.trim().isNotEmpty,
      _emgPhone.text.trim().isNotEmpty,
      _interests.isNotEmpty,
      _skills.isNotEmpty || _skillOther.text.trim().isNotEmpty,
      _education != null,
      _times.isNotEmpty || _days.isNotEmpty,
      _hasExp != null,
      _motivation.text.trim().isNotEmpty,
    ];
    return (checks.where((c) => c).length / checks.length * 100).round();
  }

  // ------------------------------------------------------------ navigasi
  void _scrollTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _goTo(int i) {
    if (i == _step) return;
    setState(() {
      _forward = i > _step;
      _step = i;
    });
    _scrollTop();
  }

  void _next() {
    if (_step == 0) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) {
        _snack('Lengkapi data yang bertanda * terlebih dahulu');
        return;
      }
    }
    _saveDraft(silent: true);
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      _goTo(_step - 1);
    }
  }

  Future<void> _pickPhoto() async {
    final r = await choosePhoto(context, hasPhoto: _avatar != null);
    if (r == null || !mounted) return;
    setState(() {
      _avatar = r.remove ? null : r.bytes;
      _avatarChanged = true;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birth.text = fmtLongDate(picked);
      });
    }
  }

  void _toggle(Set<String> set, String v) {
    setState(() {
      if (set.contains(v)) {
        set.remove(v);
      } else {
        set.add(v);
      }
    });
  }

  Future<void> _submit() async {
    if (_step0Error() != null) {
      _goTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _formKey.currentState?.validate());
      _snack('Lengkapi data pribadi terlebih dahulu');
      return;
    }
    if (!_agree) {
      _snack('Centang persetujuan terlebih dahulu');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Simpan biodata?'),
        content: Text(widget.event.isPaid
            ? 'Pastikan data sudah benar. Setelah disimpan, kamu akan lanjut ke pembayaran.'
            : 'Pastikan data sudah benar. Setelah disimpan, kamu langsung terdaftar di kegiatan ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Periksa Lagi')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final app = context.read<AppState>();
    setState(() => _saving = true);
    try {
      await _persist('complete');
      // Simpan data kontak ke profil pengguna (sama seperti sebelumnya)
      app.updateProfile(name: _name.text, phone: _phone.text, city: _city.text);
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Gagal menyimpan biodata, coba lagi');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    _snack('Biodata berhasil disimpan');

    if (widget.event.isPaid) {
      // Berbayar: lanjut ke halaman pembayaran
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(widget.event, participantName: _name.text.trim())),
      );
    } else {
      // Gratis: langsung terdaftar
      finishRegistration(context, widget.event);
    }
  }

  // ---------------------------------------------------------------- warna
  bool get _dark => isDark(context);
  Color get _card => _dark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _pink => _dark ? const Color(0xFF2A1B1B) : const Color(0xFFFFF1F1);
  Color get _line => _dark ? Colors.white12 : const Color(0xFFF1DCDC);
  Color get _fill => _dark ? const Color(0xFF252020) : Colors.white;
  Color get _soft => muted(context);

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w >= 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _dark
                ? const [Color(0xFF181212), Color(0xFF1F1414)]
                : const [Color(0xFFFFF7F7), Color(0xFFFFE3E3)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(wide ? 32 : 14, 4, wide ? 32 : 14, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: wide ? _wideLayout() : _narrowLayout(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_saving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20)),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _red),
                          SizedBox(height: 14),
                          Text('Menyimpan biodata...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Material(
            color: _card,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Biodata Relawan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco({double radius = 28}) => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _red.withOpacity(_dark ? 0 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  Widget _wideLayout() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: _leftPanel()),
          const SizedBox(width: 28),
          Expanded(flex: 8, child: _rightPanel()),
        ],
      ),
    );
  }

  Widget _narrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _introCompact(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(radius: 24),
          child: _rightPanel(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ panel kiri
  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _pink,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: _card, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: _red, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Lengkapi Biodata Anda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Data diri yang lengkap akan membantu kami memberikan pengalaman terbaik sebagai relawan, dan mempercepat proses pendaftaran kegiatan.',
            style: TextStyle(fontSize: 13.5, height: 1.55, color: _soft),
          ),
          const SizedBox(height: 16),
          _eventCard(),
          const SizedBox(height: 8),
          const _VolunteerIllustration(),
          const SizedBox(height: 8),
          _tipsCard(),
        ],
      ),
    );
  }

  Widget _introCompact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pink,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _card, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: _red, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Lengkapi Biodata Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Data yang lengkap membantu proses pendaftaran kegiatan.',
            style: TextStyle(fontSize: 13, height: 1.5, color: _soft),
          ),
          const SizedBox(height: 12),
          _eventCard(),
        ],
      ),
    );
  }

  Widget _eventCard() {
    final e = widget.event;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: EventImage(e, width: 56, height: 56, radius: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 3),
                Text('${fmtLongDate(e.date)} • ${e.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _soft)),
                const SizedBox(height: 5),
                StatusChip(
                  e.priceText,
                  e.isPaid ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    Widget tip(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFF97316), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(t, style: const TextStyle(fontSize: 12.5, height: 1.4))),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Tips Mengisi Biodata:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          tip('Pastikan data sesuai dengan identitas'),
          tip('Gunakan nomor WhatsApp yang aktif'),
          tip('Lengkapi semua informasi yang diperlukan'),
          tip('Simpan sementara jika ingin melanjutkan nanti'),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- panel kanan
  Widget _rightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepper(),
        const SizedBox(height: 16),
        _progressRow(),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) {
            final offset = Tween<Offset>(
              begin: Offset(_forward ? 0.06 : -0.06, 0),
              end: Offset.zero,
            ).animate(anim);
            return FadeTransition(opacity: anim, child: SlideTransition(position: offset, child: child));
          },
          child: KeyedSubtree(key: ValueKey<int>(_step), child: _stepContent()),
        ),
        const SizedBox(height: 22),
        _navBar(),
      ],
    );
  }

  Widget _stepper() {
    return LayoutBuilder(builder: (context, c) {
      final itemW = c.maxWidth >= 560 ? 120.0 : 66.0;
      final labelSize = c.maxWidth >= 560 ? 12.5 : 10.5;

      Widget item(int i) {
        final done = i < _step;
        final active = i == _step;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: i < _step ? () => _goTo(i) : null,
          child: SizedBox(
            width: itemW,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (done || active) ? _red : (_dark ? Colors.white24 : const Color(0xFFD9D9DE)),
                    boxShadow: active
                        ? [BoxShadow(color: _red.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text('${i + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                const SizedBox(height: 6),
                Text(
                  _kStepTitles[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: labelSize,
                    height: 1.2,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: (active || done) ? null : _soft,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      Widget line(int i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < _step ? _red : (_dark ? Colors.white24 : const Color(0xFFE3E3E8)),
                ),
              ),
            ),
          );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(0),
          line(0),
          item(1),
          line(1),
          item(2),
          line(2),
          item(3),
        ],
      );
    });
  }

  Widget _progressRow() {
    final pct = _percent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _pink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: _red, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Kelengkapan biodata',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text('$pct%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _red)),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: pct / 100),
            duration: const Duration(milliseconds: 400),
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: _dark ? Colors.white12 : Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(_red),
              ),
            ),
          ),
          if (_status == 'complete') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Biodata sebelumnya sudah tersimpan. Kamu bisa mengeditnya di sini.',
                      style: TextStyle(fontSize: 11.5, color: _soft)),
                ),
              ],
            ),
          ] else if (_status == 'draft') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.edit_note, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Draf tersimpan. Lanjutkan pengisian dari data terakhirmu.',
                      style: TextStyle(fontSize: 11.5, color: _soft)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _step0();
      case 1:
        return _step1();
      case 2:
        return _step2();
      default:
        return _step3();
    }
  }

  // ------------------------------------------------------------ komponen UI
  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.5, color: _soft.withOpacity(0.7)),
      prefixIcon: Icon(icon, size: 20, color: _soft),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fill,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: b(_line),
      border: b(_line),
      focusedBorder: b(_red, 1.6),
      errorBorder: b(AppColors.danger),
      focusedErrorBorder: b(AppColors.danger, 1.6),
    );
  }

  Widget _labeled(String label, Widget child, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
          ])),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _two(Widget a, Widget b) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 520) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 14),
            Expanded(child: b),
          ],
        );
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [a, b]);
    });
  }

  Widget _sectionTitle(String t, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Text(hint, style: TextStyle(fontSize: 12, color: _soft)),
            ),
        ],
      ),
    );
  }

  Widget _chipOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? _red.withOpacity(0.10) : _fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? _red : _line, width: selected ? 1.6 : 1),
        boxShadow: selected
            ? [BoxShadow(color: _red.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 3))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(selected ? Icons.check_circle : icon, size: 18, color: selected ? _red : _soft),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? _red : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceCard(String label, IconData icon, bool selected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? _red.withOpacity(0.10) : _fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? _red : _line, width: selected ? 1.6 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? _red : _soft, size: 22),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: selected ? _red : null)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ LANGKAH 1
  Widget _photoCard() {
    final has = _avatar != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dark ? Colors.white12 : const Color(0xFFE6E6EB),
                  border: Border.all(color: _card, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: has
                    ? Image.memory(_avatar!, width: 88, height: 88, fit: BoxFit.cover)
                    : Icon(Icons.person, size: 52, color: _soft),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: _red,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.photo_camera, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Foto Profil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text('Unggah foto terbaik Anda (JPG/PNG)', style: TextStyle(fontSize: 12, color: _soft)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(has ? 'Ganti Foto' : 'Pilih Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _card,
                        foregroundColor: _red,
                        elevation: 0,
                        side: BorderSide(color: _red.withOpacity(0.4)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    if (has)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _avatar = null;
                          _avatarChanged = true;
                        }),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step0() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photoCard(),
          const SizedBox(height: 18),
          _sectionTitle('Data Diri'),
          _two(
            _labeled(
              'Nama Lengkap',
              required: true,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: (v) => validateRequired(v, 'Nama lengkap'),
                decoration: _dec('Masukkan nama lengkap Anda', Icons.person_outline),
              ),
            ),
            _labeled(
              'Email',
              required: true,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                decoration: _dec('nama@email.com', Icons.email_outlined),
              ),
            ),
          ),
          _two(
            _labeled(
              'No. WhatsApp',
              required: true,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                decoration: _dec('08xxxxxxxxxx', Icons.phone_outlined),
              ),
            ),
            _labeled(
              'Jenis Kelamin',
              required: true,
              DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                items: const ['Laki-laki', 'Perempuan']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? 'Pilih jenis kelamin' : null,
                decoration: _dec('Pilih jenis kelamin', Icons.wc_outlined),
              ),
            ),
          ),
          _two(
            _labeled(
              'Tanggal Lahir',
              required: true,
              TextFormField(
                controller: _birth,
                readOnly: true,
                onTap: _pickBirthDate,
                validator: (v) => validateRequired(v, 'Tanggal lahir'),
                decoration: _dec('Pilih tanggal lahir', Icons.cake_outlined,
                    suffix: IconButton(
                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                      onPressed: _pickBirthDate,
                    )),
              ),
            ),
            _labeled(
              'Kota / Alamat Domisili',
              required: true,
              TextFormField(
                controller: _city,
                validator: (v) => validateRequired(v, 'Kota / alamat'),
                decoration: _dec('Contoh: Gresik, Jawa Timur', Icons.location_on_outlined),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _sectionTitle('Kontak Darurat'),
          _two(
            _labeled(
              'Nama Kontak Darurat',
              required: true,
              TextFormField(
                controller: _emgName,
                textCapitalization: TextCapitalization.words,
                validator: (v) => validateRequired(v, 'Nama kontak darurat'),
                decoration: _dec('Nama keluarga / kerabat', Icons.contact_phone_outlined),
              ),
            ),
            _labeled(
              'No. Telepon Kontak Darurat',
              required: true,
              TextFormField(
                controller: _emgPhone,
                keyboardType: TextInputType.phone,
                validator: (v) => validateRequired(v, 'No. telepon kontak darurat'),
                decoration: _dec('08xxxxxxxxxx', Icons.phone_in_talk_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ LANGKAH 2
  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Minat Relawan', hint: 'Pilih satu atau lebih bidang yang kamu minati'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final o in _kInterests)
              _chipOption(
                label: o.label,
                icon: o.icon,
                selected: _interests.contains(o.label),
                onTap: () => _toggle(_interests, o.label),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionTitle('Keahlian yang Dimiliki', hint: 'Boleh memilih lebih dari satu'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final o in _kSkills)
              _chipOption(
                label: o.label,
                icon: o.icon,
                selected: _skills.contains(o.label),
                onTap: () => _toggle(_skills, o.label),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _labeled(
          'Keahlian lainnya (opsional)',
          TextFormField(
            controller: _skillOther,
            decoration: _dec('Contoh: Edit video, Bahasa Inggris', Icons.add_circle_outline),
          ),
        ),
        const SizedBox(height: 6),
        _sectionTitle('Latar Belakang'),
        _two(
          _labeled(
            'Pendidikan Terakhir',
            DropdownButtonFormField<String>(
              value: _education,
              isExpanded: true,
              items: _kEducation.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _education = v),
              decoration: _dec('Pilih pendidikan terakhir', Icons.school_outlined),
            ),
          ),
          _labeled(
            'Bidang Keahlian',
            TextFormField(
              controller: _field,
              decoration: _dec('Contoh: Teknik Informatika', Icons.work_outline),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _sectionTitle('Ketersediaan Waktu', hint: 'Kapan kamu biasanya bisa menjadi relawan?'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in _kTimes)
              _chipOption(
                label: t,
                icon: Icons.schedule,
                selected: _times.contains(t),
                onTap: () => _toggle(_times, t),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Pilihan Hari Kegiatan'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final d in _kDays)
              _chipOption(
                label: d,
                selected: _days.contains(d),
                onTap: () => _toggle(_days, d),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------ LANGKAH 3
  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pengalaman Relawan'),
        const Text('Pernah mengikuti kegiatan volunteer?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _choiceCard('Ya, pernah', Icons.thumb_up_alt_outlined, _hasExp == true,
                  () => setState(() => _hasExp = true)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _choiceCard('Belum pernah', Icons.emoji_people_outlined, _hasExp == false,
                  () => setState(() => _hasExp = false)),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _hasExp == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _two(
                        _labeled(
                          'Nama Organisasi',
                          TextFormField(
                            controller: _orgName,
                            decoration: _dec('Contoh: Karang Taruna Desa', Icons.groups_2_outlined),
                          ),
                        ),
                        _labeled(
                          'Pengalaman Organisasi',
                          TextFormField(
                            controller: _orgRole,
                            decoration: _dec('Contoh: Koordinator Acara', Icons.badge_outlined),
                          ),
                        ),
                      ),
                      _labeled(
                        'Pengalaman Kegiatan Sosial',
                        TextFormField(
                          controller: _socialExp,
                          decoration: _dec('Contoh: Bakti sosial, bersih pantai', Icons.volunteer_activism_outlined),
                        ),
                      ),
                      _labeled(
                        'Deskripsi Pengalaman',
                        TextFormField(
                          controller: _expDesc,
                          maxLines: 4,
                          decoration: _dec('Ceritakan singkat pengalamanmu...', Icons.edit_note),
                        ),
                      ),
                    ],
                  ),
                )
              : _hasExp == false
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _pink,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _line),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: _red, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tidak masalah! Semua orang memulai dari pertama kali. Kamu tetap bisa melanjutkan.',
                                style: TextStyle(fontSize: 12.5, color: _soft, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Motivasi & Target'),
        _labeled(
          'Motivasi bergabung menjadi relawan (opsional)',
          TextFormField(
            controller: _motivation,
            maxLines: 3,
            decoration: _dec('Ceritakan singkat motivasimu...', Icons.edit_note),
          ),
        ),
        _labeled(
          'Target kontribusi yang ingin dicapai (opsional)',
          TextFormField(
            controller: _target,
            maxLines: 2,
            decoration: _dec('Contoh: Mengikuti 10 kegiatan tahun ini', Icons.flag_outlined),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ LANGKAH 4
  String _v(String s) => s.trim().isEmpty ? '-' : s.trim();
  String _j(Iterable<String> s) => s.isEmpty ? '-' : s.join(', ');

  Widget _sumRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(l, style: TextStyle(fontSize: 12.5, color: _soft))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _sumCard({
    required String title,
    required IconData icon,
    required int editStep,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _pink, shape: BoxShape.circle),
                child: Icon(icon, color: _red, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
              TextButton.icon(
                onPressed: () => _goTo(editStep),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: _red, visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _step3() {
    final has = _avatar != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Konfirmasi Biodata', hint: 'Periksa kembali data kamu sebelum disimpan'),
        _sumCard(
          title: 'Data Pribadi',
          icon: Icons.person_outline,
          editStep: 0,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dark ? Colors.white12 : const Color(0xFFE6E6EB),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: has
                      ? Image.memory(_avatar!, width: 64, height: 64, fit: BoxFit.cover)
                      : Icon(Icons.person, size: 36, color: _soft),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(has ? 'Foto profil dipilih' : 'Belum ada foto profil',
                      style: TextStyle(fontSize: 12.5, color: _soft)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sumRow('Nama Lengkap', _v(_name.text)),
            _sumRow('Email', _v(_email.text)),
            _sumRow('No. WhatsApp', _v(_phone.text)),
            _sumRow('Jenis Kelamin', _gender ?? '-'),
            _sumRow('Tanggal Lahir', _v(_birth.text)),
            _sumRow('Domisili', _v(_city.text)),
            _sumRow('Kontak Darurat', '${_v(_emgName.text)} (${_v(_emgPhone.text)})'),
          ],
        ),
        _sumCard(
          title: 'Minat & Keahlian',
          icon: Icons.interests_outlined,
          editStep: 1,
          children: [
            _sumRow('Minat', _j(_interests)),
            _sumRow('Keahlian', _j([..._skills, if (_skillOther.text.trim().isNotEmpty) _skillOther.text.trim()])),
            _sumRow('Pendidikan', _education ?? '-'),
            _sumRow('Bidang Keahlian', _v(_field.text)),
            _sumRow('Waktu', _j(_times)),
            _sumRow('Hari', _j(_days)),
          ],
        ),
        _sumCard(
          title: 'Pengalaman Relawan',
          icon: Icons.emoji_events_outlined,
          editStep: 2,
          children: [
            _sumRow('Pernah relawan', _hasExp == null ? '-' : (_hasExp! ? 'Ya' : 'Belum pernah')),
            if (_hasExp == true) ...[
              _sumRow('Organisasi', _v(_orgName.text)),
              _sumRow('Peran', _v(_orgRole.text)),
              _sumRow('Kegiatan Sosial', _v(_socialExp.text)),
              _sumRow('Deskripsi', _v(_expDesc.text)),
            ],
            _sumRow('Motivasi', _v(_motivation.text)),
            _sumRow('Target', _v(_target.text)),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: _pink,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _agree ? _red : _line),
          ),
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: _red,
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
            title: const Text(
              'Saya menyatakan data di atas benar, bersedia mengikuti arahan penyelenggara kegiatan, dan menyetujui penggunaan data untuk proses pendaftaran.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------- tombol bawah
  Widget _navBar() {
    final last = _step == 3;

    final back = OutlinedButton.icon(
      onPressed: _saving ? null : _back,
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Kembali'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _red,
        side: BorderSide(color: _red.withOpacity(0.55)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    final draft = TextButton.icon(
      onPressed: _saving ? null : () => _saveDraft(),
      icon: const Icon(Icons.save_outlined, size: 18),
      label: const Text('Simpan Sementara'),
      style: TextButton.styleFrom(
        foregroundColor: _soft,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );

    final next = ElevatedButton(
      onPressed: _saving ? null : (last ? _submit : _next),
      style: ElevatedButton.styleFrom(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade400,
        elevation: 3,
        shadowColor: _red.withOpacity(0.4),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              last ? 'Simpan Biodata' : 'Selanjutnya',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
          const SizedBox(width: 8),
          Icon(last ? Icons.check_circle_outline : Icons.arrow_forward, size: 18),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 560) {
        return Row(
          children: [
            back,
            const Spacer(),
            draft,
            const SizedBox(width: 12),
            next,
          ],
        );
      }
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: back),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: next),
            ],
          ),
          const SizedBox(height: 6),
          draft,
        ],
      );
    });
  }
}

// ------------------------------------------------------------ ilustrasi
class _VolunteerIllustration extends StatelessWidget {
  const _VolunteerIllustration();

  Widget _bubble(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD1D1), Color(0xFFFFEEEE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 62),
            ),
            Positioned(top: 10, left: 22, child: _bubble(Icons.favorite, AppColors.primary, 40)),
            Positioned(top: 26, right: 18, child: _bubble(Icons.verified_user, const Color(0xFF16A34A), 44)),
            Positioned(bottom: 14, left: 34, child: _bubble(Icons.school_outlined, const Color(0xFFF59E0B), 38)),
            Positioned(bottom: 8, right: 38, child: _bubble(Icons.groups_2, const Color(0xFF2563EB), 42)),
          ],
        ),
      ),
    );
  }
}