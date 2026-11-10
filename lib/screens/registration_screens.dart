import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'registration_success_screen.dart';

/// Mendaftarkan relawan ke event lalu membuka halaman tiket.
/// Mengembalikan false jika gagal (pesan error tampil di SnackBar).
bool finishRegistration(BuildContext context, EventModel e) {
  final s = context.read<AppState>();
  final err = s.registerEvent(e);
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    return false;
  }
  final reg = s.regOf(e.id)!;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => RegistrationSuccessScreen(reg, fresh: true)),
    (route) => route.isFirst,
  );
  return true;
}

// ============================================================
// HALAMAN 1: BIODATA RELAWAN
// ============================================================
class RegistrationFormScreen extends StatefulWidget {
  final EventModel event;
  const RegistrationFormScreen(this.event, {super.key});

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  final _birth = TextEditingController();
  final _emgName = TextEditingController();
  final _emgPhone = TextEditingController();
  final _motivation = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  bool _agree = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _city = TextEditingController(text: u?.city ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city, _birth, _emgName, _emgPhone, _motivation]) {
      c.dispose();
    }
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Centang persetujuan terlebih dahulu')),
      );
      return;
    }

    // Simpan data kontak ke profil pengguna
    context.read<AppState>().updateProfile(
          name: _name.text,
          phone: _phone.text,
          city: _city.text,
        );

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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Biodata Relawan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ringkasan event
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: EventImage(e, width: 64, height: 64, radius: 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${fmtLongDate(e.date)} • ${e.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: muted(context))),
                            const SizedBox(height: 6),
                            StatusChip(
                              e.priceText,
                              e.isPaid ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    const Text('Data Diri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    _label('Nama Lengkap'),
                    AppTextField('Nama sesuai identitas', Icons.person_outline,
                        controller: _name, validator: (v) => validateRequired(v, 'Nama lengkap')),

                    _label('Email'),
                    AppTextField('email@contoh.com', Icons.email_outlined,
                        controller: _email, keyboard: TextInputType.emailAddress, validator: validateEmail),

                    _label('No. WhatsApp'),
                    AppTextField('08xxxxxxxxxx', Icons.phone_outlined,
                        controller: _phone,
                        keyboard: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'No. WhatsApp wajib diisi';
                          final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length < 9) return 'No. WhatsApp tidak valid';
                          return null;
                        }),

                    _label('Jenis Kelamin'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        items: const ['Laki-laki', 'Perempuan']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v),
                        validator: (v) => v == null ? 'Pilih jenis kelamin' : null,
                        decoration: InputDecoration(
                          hintText: 'Pilih jenis kelamin',
                          prefixIcon: const Icon(Icons.wc_outlined, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    _label('Tanggal Lahir'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: _birth,
                        readOnly: true,
                        onTap: _pickBirthDate,
                        validator: (v) => validateRequired(v, 'Tanggal lahir'),
                        decoration: InputDecoration(
                          hintText: 'Pilih tanggal lahir',
                          prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    _label('Kota / Alamat Domisili'),
                    AppTextField('Contoh: Gresik, Jawa Timur', Icons.location_city_outlined,
                        controller: _city, validator: (v) => validateRequired(v, 'Kota / alamat')),

                    const SizedBox(height: 8),
                    const Text('Kontak Darurat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    _label('Nama Kontak Darurat'),
                    AppTextField('Nama keluarga / kerabat', Icons.contact_phone_outlined,
                        controller: _emgName, validator: (v) => validateRequired(v, 'Nama kontak darurat')),

                    _label('No. Telepon Kontak Darurat'),
                    AppTextField('08xxxxxxxxxx', Icons.phone_in_talk_outlined,
                        controller: _emgPhone,
                        keyboard: TextInputType.phone,
                        validator: (v) => validateRequired(v, 'No. telepon kontak darurat')),

                    const SizedBox(height: 8),
                    const Text('Motivasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _label('Mengapa ingin ikut kegiatan ini? (opsional)'),
                    AppTextField('Ceritakan singkat motivasimu...', Icons.edit_note,
                        controller: _motivation, maxLines: 3),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      title: const Text(
                        'Saya menyatakan data di atas benar dan bersedia mengikuti arahan penyelenggara kegiatan.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      e.isPaid ? 'Lanjut ke Pembayaran' : 'Daftar Sekarang',
                      onTap: _submit,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HALAMAN 2: PEMBAYARAN (hanya untuk event berbayar)
// ============================================================
class _PayMethod {
  final String id, name, group;
  final IconData icon;
  const _PayMethod(this.id, this.name, this.group, this.icon);
}

const List<_PayMethod> _kPayMethods = [
  _PayMethod('bca', 'BCA Virtual Account', 'Transfer Bank', Icons.account_balance),
  _PayMethod('mandiri', 'Mandiri Virtual Account', 'Transfer Bank', Icons.account_balance),
  _PayMethod('bni', 'BNI Virtual Account', 'Transfer Bank', Icons.account_balance),
  _PayMethod('bri', 'BRI Virtual Account', 'Transfer Bank', Icons.account_balance),
  _PayMethod('gopay', 'GoPay', 'E-Wallet', Icons.account_balance_wallet_outlined),
  _PayMethod('ovo', 'OVO', 'E-Wallet', Icons.account_balance_wallet_outlined),
  _PayMethod('dana', 'DANA', 'E-Wallet', Icons.account_balance_wallet_outlined),
  _PayMethod('shopeepay', 'ShopeePay', 'E-Wallet', Icons.account_balance_wallet_outlined),
  _PayMethod('qris', 'QRIS', 'QRIS', Icons.qr_code_2),
];

class PaymentScreen extends StatefulWidget {
  final EventModel event;
  final String participantName;
  const PaymentScreen(this.event, {super.key, required this.participantName});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selected;

  _PayMethod? get _method {
    for (final m in _kPayMethods) {
      if (m.id == _selected) return m;
    }
    return null;
  }

  String _vaNumber(_PayMethod m) {
    final prefix = {'bca': '39201', 'mandiri': '88608', 'bni': '8808', 'bri': '26215'}[m.id] ?? '88';
    final n = (widget.event.id.hashCode.abs() % 10000000).toString().padLeft(7, '0');
    return '$prefix$n';
  }

  Future<void> _pay() async {
    final m = _method;
    if (m == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
      );
      return;
    }

    // Simulasi proses pembayaran
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // tutup loading

    finishRegistration(context, widget.event);
  }

  Widget _methodTile(_PayMethod m) {
    final selected = _selected == m.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? softOf(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selected = m.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(children: [
              Icon(m.icon, color: selected ? AppColors.primary : muted(context)),
              const SizedBox(width: 12),
              Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : Colors.grey,
                size: 20,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _methodDetail() {
    final m = _method;
    if (m == null) return const SizedBox.shrink();

    Widget box(Widget child) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: child,
        );

    if (m.group == 'Transfer Bank') {
      final va = _vaNumber(m);
      return box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nomor Virtual Account', style: TextStyle(fontSize: 11.5, color: muted(context))),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: Text(va, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: va));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Nomor VA disalin')));
            },
          ),
        ]),
        const SizedBox(height: 4),
        Text('Transfer sesuai nominal melalui ATM, m-banking, atau internet banking ${m.name.split(' ').first}.',
            style: TextStyle(fontSize: 12, color: muted(context), height: 1.4)),
      ]));
    }

    if (m.group == 'E-Wallet') {
      return box(Text(
        'Kamu akan diarahkan ke aplikasi ${m.name} untuk menyelesaikan pembayaran sebesar ${widget.event.priceText}.',
        style: TextStyle(fontSize: 12.5, color: muted(context), height: 1.4),
      ));
    }

    // QRIS
    return box(Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: QrImageView(
          data: 'QRIS-${widget.event.id}-${widget.event.price}',
          size: 170,
          backgroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Text('Scan dengan aplikasi bank atau e-wallet apa pun.',
          style: TextStyle(fontSize: 12, color: muted(context))),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final groups = <String>[];
    for (final m in _kPayMethods) {
      if (!groups.contains(m.group)) groups.add(m.group);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Ringkasan pesanan
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Ringkasan Pendaftaran',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        _row('Kegiatan', e.title),
                        _row('Peserta', widget.participantName),
                        _row('Tanggal', fmtLongDate(e.date)),
                        const Divider(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(e.priceText,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFE65100))),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    const Text('Pilih Metode Pembayaran',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    for (final g in groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(g, style: TextStyle(fontSize: 12, color: muted(context), fontWeight: FontWeight.w600)),
                      ),
                      for (final m in _kPayMethods.where((x) => x.group == g)) ...[
                        _methodTile(m),
                        if (_selected == m.id) _methodDetail(),
                      ],
                    ],
                  ]),
                ),
              ),
            ),
          ),

          // Tombol bayar (menempel di bawah)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: PrimaryButton('Bayar ${e.priceText}', onTap: _pay),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 80, child: Text(l, style: TextStyle(fontSize: 12.5, color: muted(context)))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        ]),
      );
}
