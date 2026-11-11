import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEF2F2);

/// Ubah jadi true setelah kamu menaruh file logo asli (PNG) di folder
/// assets/image/ dengan nama: bca.png, mandiri.png, bni.png, bri.png, livin.png,
/// gopay.png, ovo.png, dana.png, shopeepay.png, qris.png
/// Jika false, logo digambar langsung dengan kode (warna & teks merek).
const bool kUseLogoAssets = false;

String _rp(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp $b';
}

enum _Kind { va, app, qris }

class _Method {
  final String id, name, subtitle, group, mark;
  final _Kind kind;
  final Color color, markColor;
  final IconData? icon;
  final double markSize;
  const _Method({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.group,
    required this.kind,
    required this.color,
    this.mark = '',
    this.markColor = Colors.white,
    this.markSize = 14,
    this.icon,
  });

  String get asset => 'assets/image/$id.png';
}

const _groups = ['Transfer Bank', 'E-Wallet', 'QRIS'];

const _methods = <_Method>[
  _Method(id: 'bca', name: 'BCA Virtual Account', subtitle: 'Bayar dengan BCA Virtual Account',
      group: 'Transfer Bank', kind: _Kind.va, color: Color(0xFF0060AF), mark: 'BCA', markSize: 15),
  _Method(id: 'mandiri', name: 'Mandiri Virtual Account', subtitle: 'Bayar dengan Mandiri Virtual Account',
      group: 'Transfer Bank', kind: _Kind.va, color: Color(0xFF003D79), mark: 'mandiri',
      markColor: Color(0xFFFFB700), markSize: 11),
  _Method(id: 'bni', name: 'BNI Virtual Account', subtitle: 'Bayar dengan BNI Virtual Account',
      group: 'Transfer Bank', kind: _Kind.va, color: Color(0xFFF15A22), mark: 'BNI', markSize: 15),
  _Method(id: 'bri', name: 'BRI Virtual Account', subtitle: 'Bayar dengan BRI Virtual Account',
      group: 'Transfer Bank', kind: _Kind.va, color: Color(0xFF00529C), mark: 'BRI', markSize: 15),
  _Method(id: 'livin', name: "Livin' by Mandiri", subtitle: "Bayar dengan Livin' by Mandiri",
      group: 'Transfer Bank', kind: _Kind.app, color: Color(0xFF003D79), icon: Icons.account_balance),
  _Method(id: 'gopay', name: 'GoPay', subtitle: 'Bayar dengan GoPay',
      group: 'E-Wallet', kind: _Kind.app, color: Color(0xFF00AED6), icon: Icons.account_balance_wallet),
  _Method(id: 'ovo', name: 'OVO', subtitle: 'Bayar dengan OVO',
      group: 'E-Wallet', kind: _Kind.app, color: Color(0xFF4C2A86), icon: Icons.radio_button_unchecked),
  _Method(id: 'dana', name: 'DANA', subtitle: 'Bayar dengan DANA',
      group: 'E-Wallet', kind: _Kind.app, color: Color(0xFF118EEA), mark: 'DANA', markSize: 12),
  _Method(id: 'shopeepay', name: 'ShopeePay', subtitle: 'Bayar dengan ShopeePay',
      group: 'E-Wallet', kind: _Kind.app, color: Color(0xFFEE4D2D), icon: Icons.shopping_bag),
  _Method(id: 'qris', name: 'QRIS', subtitle: 'Bayar dengan QR Code',
      group: 'QRIS', kind: _Kind.qris, color: Color(0xFF111111), icon: Icons.qr_code_2),
];

/// Cara pakai:
///   final paid = await Navigator.push<bool>(context,
///       MaterialPageRoute(builder: (_) => const PaymentScreen(amount: 50000)));
/// [paid] bernilai true jika pembayaran dikonfirmasi.
class PaymentScreen extends StatefulWidget {
  final int amount;
  final String title;
  const PaymentScreen({super.key, this.amount = 50000, this.title = 'Pembayaran'});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selected;

  _Method? get _selectedMethod {
    for (final m in _methods) {
      if (m.id == selected) return m;
    }
    return null;
  }

  // ------------------------------------------------------------------ logo
  Widget _mark(_Method m, double size) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(12)),
        child: m.icon != null
            ? Icon(m.icon, color: m.markColor, size: size * .5)
            : Text(m.mark,
                style: TextStyle(
                    color: m.markColor,
                    fontWeight: FontWeight.w800,
                    fontSize: m.markSize,
                    letterSpacing: -.3)),
      );

  Widget _logo(_Method m, {double size = 46}) {
    if (!kUseLogoAssets) return _mark(m, size);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: Image.asset(m.asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _mark(m, size)),
    );
  }

  // ------------------------------------------------------------------ item
  Widget _tile(_Method m) {
    final sel = selected == m.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => selected = m.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? _redSoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? _red : Colors.grey.shade300, width: sel ? 1.6 : 1),
          ),
          child: Row(children: [
            _logo(m),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(m.subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ]),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? _red : Colors.grey, width: 2)),
              child: sel
                  ? Center(
                      child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)))
                  : null,
            ),
          ]),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- bayar
  void _pay() {
    final m = _selectedMethod;
    if (m == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')));
      return;
    }
    _showInstruction(m);
  }

  void _showInstruction(_Method m) {
    final ref = DateTime.now().millisecondsSinceEpoch;
    String? va;
    if (m.kind == _Kind.va) {
      const prefixes = {'bca': '39201', 'mandiri': '88608', 'bni': '8808', 'bri': '26215'};
      va = (prefixes[m.id] ?? '99') + (ref % 100000000000).toString().padLeft(11, '0');
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              _logo(m),
              const SizedBox(width: 12),
              Expanded(child: Text(m.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _redSoft, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(_rp(widget.amount),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _red)),
              ]),
            ),
            const SizedBox(height: 16),
            if (va != null) ...[
              const Text('Nomor Virtual Account', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SelectableText(va,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: va!));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Nomor VA disalin')));
                  },
                ),
              ]),
              const SizedBox(height: 4),
              Text('Transfer melalui ATM, mobile banking, atau internet banking ${m.name.split(' ').first}.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ] else if (m.kind == _Kind.qris) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)),
                child: QrImageView(
                    data: 'VOLUNTEER-PAY-$ref-${widget.amount}', size: 200, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text('Scan QR dengan aplikasi bank atau e-wallet apa pun.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ] else
              Text('Buka aplikasi ${m.name} lalu konfirmasi pembayaran sebesar ${_rp(widget.amount)}.',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  _success();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Saya Sudah Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(sheet), child: const Text('Batal')),
          ]),
        ),
      ),
    );
  }

  Future<void> _success() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF16A34A),
              child: Icon(Icons.check, color: Colors.white, size: 36)),
          const SizedBox(height: 14),
          const Text('Pembayaran Berhasil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_rp(widget.amount), style: const TextStyle(color: Colors.black54)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), children: [
                const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Total tagihan: ${_rp(widget.amount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                for (final g in _groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(g, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ),
                  for (final m in _methods.where((e) => e.group == g)) _tile(m),
                ],
              ]),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10, offset: const Offset(0, -2)),
          ]),
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('Bayar ${_rp(widget.amount)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
