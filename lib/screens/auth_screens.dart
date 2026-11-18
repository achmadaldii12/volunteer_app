import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import '../penyelenggara/organizer_shell.dart';

// ============================================================
// KOMPONEN BERSAMA: logo & animasi masuk
// ============================================================

/// Logo Volunteer di dalam lingkaran putih (logo diperbesar sedikit agar jelas).
class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: 1.55,
          child: Image.asset(
            'assets/image/logo_volunteer.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.volunteer_activism, color: AppColors.primary, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Memunculkan widget dengan efek fade + geser halus (dengan jeda opsional).
class _Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Offset from;
  const _Reveal({required this.child, this.delayMs = 0, this.from = const Offset(0, 0.12)});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
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
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.from, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// SPLASH
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _boot();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final s = context.read<AppState>();
    await Future.wait([s.init(), Future.delayed(const Duration(milliseconds: 2800))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => s.user == null ? LoginScreen() : const RoleHome(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse]),
        builder: (context, _) {
          final t = _intro.value;
          double iv(double a, double b, Curve c) => c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

          final logoScale = iv(0.0, 0.6, Curves.elasticOut);
          final logoFade = iv(0.0, 0.25, Curves.easeOut);
          final titleT = iv(0.45, 0.8, Curves.easeOutCubic);
          final tagT = iv(0.6, 1.0, Curves.easeOutCubic);
          final drift = math.sin(_pulse.value * 2 * math.pi);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primaryDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(top: -60 + drift * 10, right: -60, child: _circle(220)),
                Positioned(bottom: 90 - drift * 12, left: -80, child: _circle(240)),
                Positioned(top: 140 - drift * 8, left: 40, child: _circle(46)),
                Positioned(bottom: 190 + drift * 8, right: 60, child: _circle(70)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Gelombang di belakang logo
                            for (int i = 0; i < 2; i++) _ripple((_pulse.value + i * 0.5) % 1.0, logoFade),
                            Opacity(
                              opacity: logoFade.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: logoScale,
                                child: Transform.translate(
                                  offset: Offset(0, drift * 4),
                                  child: const _LogoBadge(size: 160),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: titleT,
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - titleT)),
                          child: const Text(
                            'Volunteer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: tagT,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - tagT)),
                          child: const Text(
                            'Bersama, Kita\nMemberi Dampak',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 120,
                        height: 5,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 2600),
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ripple(double p, double fade) {
    final size = 160 + p * 130;
    return Opacity(
      opacity: ((1 - p) * 0.35 * fade).clamp(0.0, 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.07),
      ),
    );
  }
}

void _toMain(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const RoleHome()),
    (_) => false,
  );
}

// ============================================================
// LOGIN
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final err = context.read<AppState>().login(_email.text, _pass.text);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil masuk!')),
      );
      _toMain(context);
    }
  }

  void _social(String name) {
    context.read<AppState>().loginDemo();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mode demo: masuk dengan akun contoh ($name)')),
    );
    _toMain(context);
  }

  Widget _buildAuthLink(String a, String b, Color textColor, Color linkColor, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(a, style: TextStyle(fontSize: 12.5, color: textColor)),
        GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              b,
              style: TextStyle(
                fontSize: 12.5,
                color: linkColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialBtn(Widget child, VoidCallback onTap, {required bool onRed}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onRed ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.35)),
        ),
        child: child,
      ),
    );
  }

  /// Kartu formulir login (dipakai di tampilan HP dan laptop)
  Widget _formCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            'Email',
            Icons.mail_outline,
            controller: _email,
            validator: validateEmail,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 4),
          AppTextField(
            'Password',
            Icons.lock_outline,
            controller: _pass,
            password: true,
            validator: validatePassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _email.text = 'aldi@email.com';
                _pass.text = '123456';
              },
              child: Text(
                'Isi akun demo',
                style: TextStyle(fontSize: 11.5, color: primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton('Login', onTap: _submit),
        ],
      ),
    );
  }

  Widget _socialRow({required bool onRed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialBtn(
          const Text(
            'G',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFDB4437)),
          ),
          () => _social('Google'),
          onRed: onRed,
        ),
        const SizedBox(width: 12),
        _socialBtn(const Icon(Icons.apple, size: 22, color: Colors.black87), () => _social('Apple'), onRed: onRed),
      ],
    );
  }

  void _openRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(body: wide ? _wideLayout() : _mobileLayout());
  }

  // ------------------------------------------------------------ HP / tablet
  Widget _mobileLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -70, right: -70, child: _bgCircle(220)),
          Positioned(bottom: -90, left: -80, child: _bgCircle(250)),
          SafeArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Reveal(
                            from: const Offset(0, -0.15),
                            child: const Center(child: _LogoBadge(size: 96)),
                          ),
                          const SizedBox(height: 12),
                          const _Reveal(
                            delayMs: 150,
                            child: Text(
                              'Selamat Datang, Volunteer!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const _Reveal(
                            delayMs: 250,
                            child: Text(
                              'Masuk untuk melanjutkan aksi kebaikanmu',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Reveal(delayMs: 350, child: _formCard()),
                          const SizedBox(height: 12),
                          const _Reveal(
                            delayMs: 500,
                            child: Center(
                              child: Text(
                                'atau masuk dengan',
                                style: TextStyle(fontSize: 11.5, color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Reveal(delayMs: 560, child: _socialRow(onRed: true)),
                          const SizedBox(height: 14),
                          _Reveal(
                            delayMs: 620,
                            child: _buildAuthLink(
                              'Belum punya akun? ',
                              'Daftar',
                              Colors.white70,
                              Colors.white,
                              _openRegister,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ laptop / desktop
  Widget _wideLayout() {
    final dark = isDark(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        // Kiri: panel merah dengan logo
        Expanded(child: _leftPanel()),
        // Kanan: formulir
        Expanded(
          child: Container(
            color: dark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
            child: SafeArea(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Reveal(
                              child: Text(
                                'Selamat Datang, Volunteer!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _Reveal(
                              delayMs: 100,
                              child: Text(
                                'Masuk untuk melanjutkan aksi kebaikanmu',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13.5, color: muted(context)),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _Reveal(delayMs: 200, child: _formCard()),
                            const SizedBox(height: 16),
                            _Reveal(
                              delayMs: 330,
                              child: Center(
                                child: Text(
                                  'atau masuk dengan',
                                  style: TextStyle(fontSize: 12, color: muted(context)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Reveal(delayMs: 380, child: _socialRow(onRed: false)),
                            const SizedBox(height: 18),
                            _Reveal(
                              delayMs: 440,
                              child: _buildAuthLink(
                                'Belum punya akun? ',
                                'Daftar',
                                muted(context),
                                primary,
                                _openRegister,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _leftPanel() {
    Widget point(int n, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14.5))),
            ],
          ),
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -90, right: -80, child: _bgCircle(300)),
          Positioned(bottom: -140, right: -60, child: _bgCircle(360)),
          Positioned(top: 120, left: -60, child: _bgCircle(150)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Reveal(
                      from: Offset(-0.1, 0),
                      child: _LogoBadge(size: 150),
                    ),
                    const SizedBox(height: 26),
                    const _Reveal(
                      delayMs: 150,
                      child: Text(
                        'Volunteer',
                        style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _Reveal(
                      delayMs: 250,
                      child: Text(
                        'Bersama, Kita Memberi Dampak',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Reveal(
                      delayMs: 350,
                      child: Text(
                        'Temukan, ikuti, dan kelola kegiatan kerelawanan dalam satu aplikasi. Mulai berkontribusi untuk Indonesia hari ini.',
                        style: TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.55),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Reveal(delayMs: 450, child: point(1, 'Temukan kegiatan relawan di sekitarmu')),
                    _Reveal(delayMs: 540, child: point(2, 'Daftar dan dapatkan tiket digital')),
                    _Reveal(delayMs: 630, child: point(3, 'Kumpulkan poin dan sertifikat')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bgCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final err = context.read<AppState>().register(_name.text, _email.text, _pass.text);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      _toMain(context);
    }
  }

  Widget _buildAuthLink(String a, String b, Color color, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(a, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            b,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_outlined, size: 36, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Daftar Akun',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Bergabunglah dengan komunitas\nvolunteer sekarang!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                'Nama Lengkap',
                                Icons.person_outline,
                                controller: _name,
                                validator: (v) => validateRequired(v, 'Nama'),
                              ),
                              const SizedBox(height: 4),
                              AppTextField(
                                'Email',
                                Icons.mail_outline,
                                controller: _email,
                                validator: validateEmail,
                                keyboard: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 4),
                              AppTextField(
                                'Password',
                                Icons.lock_outline,
                                controller: _pass,
                                password: true,
                                validator: validatePassword,
                              ),
                              const SizedBox(height: 4),
                              AppTextField(
                                'Konfirmasi Password',
                                Icons.lock_outline,
                                controller: _confirm,
                                password: true,
                                validator: (v) => v != _pass.text ? 'Konfirmasi password tidak sama' : null,
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton('Daftar', onTap: _submit),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAuthLink(
                          'Sudah punya akun? ',
                          'Login',
                          Colors.white,
                          () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}