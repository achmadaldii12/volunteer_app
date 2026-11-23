import 'dart:ui' show PointMode;
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================================
// MENU BAWAH - MELAYANG, SUDUT MELENGKUNG, MERAH LEMBUT BERBINTIK
// (VERSI RINGAN: tanpa efek blur, jadi cepat dan bebas "Shader compilation error")
//
// GANTI SELURUH ISI file lib/widgets/glass_nav_bar.dart DENGAN KODE INI.
// File lain (main_shell.dart dll) TIDAK perlu diubah.
//
// Perbaikan dari versi sebelumnya:
//  - Tidak ada lagi MaskFilter.blur / BoxShadow blur yang digambar ulang di
//    setiap frame saat pindah menu (penyebab "Shader compilation error").
//  - Bintik-bintik digambar hanya dengan 3 panggilan gambar (bukan ratusan)
//    dan posisinya disimpan (cache), jadi animasi pindah menu lebih lancar.
//  - Isi bilah (ikon) tidak dibangun ulang tiap frame animasi.
//  - Gelembung dibuat sebagai layer tersendiri (RepaintBoundary).
// ============================================================================

class GlassNavItem {
  const GlassNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Kumpulan warna menu bawah. Ubah di sini kalau mau ganti warna.
class _NavPalette {
  const _NavPalette({
    required this.barTop,
    required this.barBottom,
    required this.edge,
    required this.shadow,
    required this.idleIcon,
    required this.bubbleTop,
    required this.bubbleBottom,
    required this.bubbleBorder,
    required this.bubbleGlow,
    required this.iconOnBubble,
    required this.dotColor,
  });

  final Color barTop; // warna bilah bagian atas
  final Color barBottom; // warna bilah bagian bawah
  final Color edge; // garis tepi tipis bilah
  final Color shadow; // bayangan bilah
  final Color idleIcon; // ikon menu yang tidak dipilih
  final Color bubbleTop; // gelembung: warna awal gradasi
  final Color bubbleBottom; // gelembung: warna akhir gradasi
  final Color bubbleBorder; // bingkai gelembung
  final Color bubbleGlow; // cahaya tipis di sekitar gelembung
  final Color iconOnBubble; // ikon di dalam gelembung
  final Color dotColor; // warna bintik-bintik hiasan di bilah

  // ---------- MODE TERANG ----------
  static const light = _NavPalette(
    barTop: Color(0xFFF07C7C),
    barBottom: Color(0xFFE76363),
    edge: Color(0x66FFFFFF),
    shadow: Color(0xB3000000),
    idleIcon: Color(0xFFFFF4F4),
    bubbleTop: Color(0xFFDC4242),
    bubbleBottom: Color(0xFFC42E2E),
    bubbleBorder: Color(0xFFFFFFFF),
    bubbleGlow: Color(0xFFB02424),
    iconOnBubble: Color(0xFFFFFFFF),
    dotColor: Color(0xFFC62828),
  );

  // ---------- MODE GELAP ----------
  static const dark = _NavPalette(
    barTop: Color(0xFFDA6B6B),
    barBottom: Color(0xFFC75858),
    edge: Color(0x4DFFFFFF),
    shadow: Color(0xE6000000),
    idleIcon: Color(0xFFFFEAEA),
    bubbleTop: Color(0xFFB83434),
    bubbleBottom: Color(0xFF9E2727),
    bubbleBorder: Color(0xFFFFFFFF),
    bubbleGlow: Color(0xFF7E1D1D),
    iconOnBubble: Color(0xFFFFFFFF),
    dotColor: Color(0xFFA32222),
  );
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
  static const double _barH = 62; // tinggi bilah
  static const double _rise = 24; // ruang di atas bilah untuk gelembung
  static const double _bubbleD = 50; // diameter gelembung
  static const double _glowD = 76; // diameter cahaya di sekitar gelembung
  static const double _corner = 28; // kelengkungan keempat sudut bilah
  static const double _notchHalf = 38; // setengah lebar lekukan
  static const double _notchDepth = 32; // kedalaman lekukan
  static const double _sideMarginPhone = 12; // jarak kiri/kanan di HP
  static const double _sideMarginWide = 28; // jarak kiri/kanan di layar lebar
  static const double _bottomMargin = 10; // jarak bilah dari bawah layar

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final idx = currentIndex < 0 ? 0 : (currentIndex > n - 1 ? n - 1 : currentIndex);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomGap = bottomInset + _bottomMargin;
    final pal = Theme.of(context).brightness == Brightness.dark
        ? _NavPalette.dark
        : _NavPalette.light;

    return SizedBox(
      height: _rise + _barH + bottomGap,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final side = w >= 700 ? _sideMarginWide : _sideMarginPhone;
          final barW = w - 2 * side;

          // Ikon dibagi rata dari kiri ke kanan dalam bilah.
          // Jarak tepi (pad) hanya ditambah bila perlu (di HP) supaya lekukan
          // di menu paling kiri/kanan tidak terpotong sudut bilah.
          var pad = (_corner + _notchHalf - barW / (2 * n)) / (1 - 1 / n);
          if (pad < 0) pad = 0;
          if (pad > 60) pad = 60;
          final slotW = (barW - 2 * pad) / n;
          double centerOf(int i) => pad + slotW * (i + 0.5);

          // Isi bilah (ikon-ikon). Dibangun SEKALI per pergantian menu,
          // tidak dibangun ulang di setiap frame animasi.
          final content = Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  for (var i = 0; i < n; i++) Expanded(child: _item(i, idx, pal)),
                ],
              ),
            ),
          );

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: centerOf(idx)),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            child: content,
            builder: (context, cx, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bilah melayang
                  Positioned(
                    left: side,
                    right: side,
                    bottom: bottomGap,
                    height: _barH,
                    child: CustomPaint(
                      painter: _BarPainter(
                        cx: cx,
                        corner: _corner,
                        notchHalf: _notchHalf,
                        notchDepth: _notchDepth,
                        pal: pal,
                      ),
                      child: child,
                    ),
                  ),
                  // Gelembung menu yang sedang dipilih (layer tersendiri)
                  Positioned(
                    left: side + cx - _glowD / 2,
                    top: _rise - _glowD / 2 + 2,
                    child: IgnorePointer(
                      child: RepaintBoundary(child: _bubble(idx, pal)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _item(int i, int selected, _NavPalette pal) {
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
                  child: Icon(items[i].icon, size: 24, color: pal.idleIcon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(int idx, _NavPalette pal) {
    return SizedBox(
      width: _glowD,
      height: _glowD,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // cahaya lembut TANPA blur: memakai gradasi radial biasa
          Container(
            width: _glowD,
            height: _glowD,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  pal.bubbleGlow.withOpacity(0.32),
                  pal.bubbleGlow.withOpacity(0.0),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          Container(
            width: _bubbleD,
            height: _bubbleD,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pal.bubbleTop, pal.bubbleBottom],
              ),
              border: Border.all(color: pal.bubbleBorder, width: 2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
              child: Icon(
                items[idx].icon,
                key: ValueKey<int>(idx),
                color: pal.iconOnBubble,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menggambar bilah melayang: keempat sudut melengkung, dengan lekukan
/// melengkung di posisi [cx] dan bintik-bintik merah di dalamnya.
class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.cx,
    required this.corner,
    required this.notchHalf,
    required this.notchDepth,
    required this.pal,
  });

  final double cx;
  final double corner;
  final double notchHalf;
  final double notchDepth;
  final _NavPalette pal;

  // ---- cache posisi bintik (dihitung sekali per ukuran bilah) ----
  static Size? _cachedSize;
  static List<Offset> _small = const [];
  static List<Offset> _mid = const [];
  static List<Offset> _big = const [];

  static void _buildDots(Size size) {
    if (_cachedSize == size) return;
    _cachedSize = size;
    final rnd = math.Random(11); // tetap sama -> bintik tidak berubah-ubah
    const stepX = 24.0; // jarak antar bintik (kiri-kanan)
    const stepY = 17.0; // jarak antar baris bintik
    final s = <Offset>[];
    final m = <Offset>[];
    final b = <Offset>[];
    var row = 0;
    for (double y = 6; y < size.height; y += stepY) {
      final shift = row.isEven ? 0.0 : stepX / 2;
      for (double x = shift + 6; x < size.width; x += stepX) {
        final p = Offset(
          x + (rnd.nextDouble() - 0.5) * 10,
          y + (rnd.nextDouble() - 0.5) * 8,
        );
        final t = rnd.nextDouble();
        if (t < 0.45) {
          s.add(p);
        } else if (t < 0.80) {
          m.add(p);
        } else {
          b.add(p);
        }
      }
      row++;
    }
    _small = s;
    _mid = m;
    _big = b;
  }

  Paint _dotPaint(double diameter, double alpha) => Paint()
    ..color = pal.dotColor.withOpacity(alpha)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = diameter;

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
      ..cubicTo(left + 15, 0, cx - 22, notchDepth, cx, notchDepth)
      ..cubicTo(cx + 22, notchDepth, right - 15, 0, right, 0)
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

    // bayangan bilah (bawaan Flutter, tanpa blur kustom)
    canvas.drawShadow(path, pal.shadow, 6, false);

    // isi bilah
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.barTop, pal.barBottom],
        ).createShader(rect),
    );

    // bintik-bintik merah: hanya 3 panggilan gambar, di dalam bilah saja
    _buildDots(size);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPoints(PointMode.points, _small, _dotPaint(3.0, 0.30));
    canvas.drawPoints(PointMode.points, _mid, _dotPaint(4.6, 0.42));
    canvas.drawPoints(PointMode.points, _big, _dotPaint(6.4, 0.55));
    canvas.restore();

    // garis tepi tipis
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = pal.edge,
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.cx != cx ||
      old.corner != corner ||
      old.notchHalf != notchHalf ||
      old.notchDepth != notchDepth ||
      old.pal != pal;
}