import 'package:flutter/material.dart';
import '../core/theme.dart';

// ============================================================================
// FILE BARU: menu bawah gaya "kaca melayang" dengan gelembung yang berpindah.
//
//  - Bilah berbentuk kapsul gelap bening yang melayang di atas halaman.
//  - Menu yang dipilih muncul sebagai gelembung merah berisi ikonnya sendiri
//    (Beranda = ikon rumah, Event = ikon kalender, dst.), duduk di lekukan bilah.
//  - Saat pindah menu, gelembung dan lekukan meluncur halus ke menu baru.
//  - Di layar lebar (laptop) bilah dibatasi lebarnya dan ditaruh di tengah.
//
// Dipakai oleh MainShell. Tidak mengubah backend dan tidak mengubah logika aplikasi.
// ============================================================================

class GlassNavItem {
  const GlassNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  // ----- ukuran (boleh diubah sesuai selera) -----
  static const double _pillH = 58; // tinggi kapsul
  static const double _rise = 26; // ruang di atas kapsul untuk gelembung
  static const double _bubbleD = 52; // diameter gelembung
  static const double _corner = 24; // kelengkungan ujung kapsul
  static const double _notchHalf = 40; // setengah lebar lekukan (di tepi atas)
  static const double _notchDepth = 34; // kedalaman lekukan

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final idx = currentIndex < 0 ? 0 : (currentIndex > n - 1 ? n - 1 : currentIndex);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              height: _pillH + _rise,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;

                  // Jarak tepi supaya lekukan di menu paling kiri/kanan tetap muat
                  var pad = (_corner + _notchHalf - w / (2 * n)) / (1 - 1 / n);
                  if (pad < 10) pad = 10;
                  if (pad > 60) pad = 60;
                  final slotW = (w - 2 * pad) / n;
                  double centerOf(int i) => pad + slotW * (i + 0.5);

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: centerOf(idx)),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
                    builder: (context, cx, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Kapsul kaca + ikon-ikon menu
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: _pillH,
                            child: CustomPaint(
                              painter: _GlassPillPainter(
                                cx: cx,
                                corner: _corner,
                                notchHalf: _notchHalf,
                                notchDepth: _notchDepth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: pad),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Row(
                                    children: [
                                      for (var i = 0; i < n; i++) Expanded(child: _item(i, idx)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Gelembung menu yang sedang dipilih
                          Positioned(
                            left: cx - _bubbleD / 2,
                            top: _rise - _bubbleD / 2 + 2,
                            child: IgnorePointer(child: _bubble(idx)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, int selected) {
    final isSelected = i == selected;
    return Tooltip(
      message: items[i].label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: items[i].label,
        child: InkResponse(
          radius: 28,
          onTap: () => onTap(i),
          child: SizedBox.expand(
            child: Center(
              // ikon menu terpilih disembunyikan karena sudah tampil di gelembung
              child: AnimatedScale(
                scale: isSelected ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: isSelected ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(items[i].icon, size: 24, color: Colors.white.withOpacity(0.88)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(int idx) {
    return Container(
      width: _bubbleD,
      height: _bubbleD,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), AppColors.primary],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.55), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
        child: Icon(
          items[idx].icon,
          key: ValueKey<int>(idx),
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

/// Menggambar kapsul kaca dengan lekukan melengkung di posisi [cx].
class _GlassPillPainter extends CustomPainter {
  _GlassPillPainter({
    required this.cx,
    required this.corner,
    required this.notchHalf,
    required this.notchDepth,
  });

  final double cx;
  final double corner;
  final double notchHalf;
  final double notchDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = corner;
    final left = cx - notchHalf;
    final right = cx + notchHalf;

    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(left, 0)
      ..cubicTo(left + 16, 0, cx - 24, notchDepth, cx, notchDepth)
      ..cubicTo(cx + 24, notchDepth, right - 16, 0, right, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();

    final rect = Offset.zero & size;

    // bayangan lembut di bawah kapsul
    canvas.drawShadow(path, Colors.black.withOpacity(0.55), 12, false);

    // isi kapsul: gradasi gelap kemerahan
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D2124), Color(0xFF231315)],
        ).createShader(rect),
    );

    // garis tepi tipis bergradasi (kesan kaca)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.10)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPillPainter old) => old.cx != cx;
}