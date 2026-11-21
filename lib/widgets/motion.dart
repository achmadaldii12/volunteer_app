import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// FILE BARU: kumpulan animasi (gerak) untuk aplikasi Volunteer.
//
//  1. HoverLift                    -> kartu terangkat + goyang halus saat kursor
//                                     diarahkan, mengecil sedikit saat ditekan
//  2. TabTransition                -> animasi geser + pudar saat pindah tab
//                                     (Beranda <-> Event <-> Riwayat, dst.)
//  3. SmoothPageTransitionsBuilder -> animasi saat membuka halaman baru
//                                     (mis. membuka detail event)
//
// Tidak mengubah backend dan tidak mengubah logika aplikasi.
// ============================================================================

/// Membungkus kartu agar:
///  - terangkat ([lift]) dan sedikit membesar ([scale]) saat kursor di atasnya,
///  - bergoyang halus satu kali saat kursor pertama masuk,
///  - mengecil ([pressScale]) saat ditekan (juga terasa di layar sentuh).
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.scale = 1.03,
    this.lift = 6,
    this.pressScale = 0.98,
    this.wiggle = true,
  });

  final Widget child;
  final double scale;
  final double lift;
  final double pressScale;
  final bool wiggle;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> with SingleTickerProviderStateMixin {
  late final AnimationController _wiggle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  bool _hover = false;
  bool _down = false;

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _enter() {
    setState(() => _hover = true);
    if (widget.wiggle) _wiggle.forward(from: 0);
  }

  void _exit() {
    if (mounted) setState(() => _hover = false);
  }

  void _setDown(bool v) {
    if (mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _down ? widget.pressScale : (_hover ? widget.scale : 1.0);

    // MouseRegion berada paling luar (tidak ikut bergeser) supaya tidak "berkedip"
    // saat kartu terangkat di tepi kursor.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _enter(),
      onExit: (_) => _exit(),
      child: Listener(
        onPointerDown: (_) => _setDown(true),
        onPointerUp: (_) => _setDown(false),
        onPointerCancel: (_) => _setDown(false),
        child: AnimatedBuilder(
          animation: _wiggle,
          builder: (context, child) {
            final t = _wiggle.value; // 0 -> 1
            // goyang kiri-kanan yang makin mengecil (maks ± 0.8 derajat)
            final angle = widget.wiggle ? math.sin(t * math.pi * 4) * (1 - t) * 0.014 : 0.0;
            return Transform.rotate(angle: angle, child: child);
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _hover ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) =>
                Transform.translate(offset: Offset(0, -widget.lift * v), child: child),
            child: AnimatedScale(
              scale: scale,
              duration: Duration(milliseconds: _down ? 90 : 240),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animasi pindah tab: halaman yang baru aktif muncul dengan geser + pudar.
/// Halaman lain tetap tersimpan di IndexedStack (posisi scroll tidak hilang).
/// [direction] = 1 -> masuk dari kanan, -1 -> masuk dari kiri.
class TabTransition extends StatefulWidget {
  const TabTransition({
    super.key,
    required this.active,
    required this.child,
    this.direction = 1,
  });

  final bool active;
  final Widget child;
  final double direction;

  @override
  State<TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<TabTransition> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: widget.active ? 1.0 : 0.0,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  double _dir = 1;

  @override
  void didUpdateWidget(TabTransition old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _dir = widget.direction;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final v = _curve.value; // 0 -> 1
          final dx = (1 - v) * 36 * _dir; // geser 36 px
          final s = 0.985 + 0.015 * v; // sedikit membesar
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: s, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Animasi membuka halaman baru (push): pudar + naik halus + sedikit membesar.
/// Halaman sebelumnya ikut memudar sedikit saat tertutup.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final secondary =
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          // saat halaman lain dibuka di atasnya: memudar & mengecil tipis
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.92).animate(secondary),
            child: child,
          ),
        ),
      ),
    );
  }
}