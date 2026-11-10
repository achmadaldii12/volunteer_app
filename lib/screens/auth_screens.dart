import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final s = context.read<AppState>();
    await Future.wait([s.init(), Future.delayed(const Duration(milliseconds: 2200))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => s.user == null ? LoginScreen() : MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -60, right: -60, child: _circle(220)),
            Positioned(bottom: 90, left: -80, child: _circle(240)),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volunteer_activism, size: 110, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Volunteer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bersama, Kita\nMemberi Dampak',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      duration: const Duration(milliseconds: 2000),
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
    MaterialPageRoute(builder: (_) => const MainShell()),
    (_) => false,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  
  String _selectedRole = 'volunteer';

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
        SnackBar(
          content: Text(
            _selectedRole == 'volunteer'
                ? 'Berhasil masuk sebagai Relawan!'
                : 'Berhasil masuk sebagai Penyelenggara!',
          ),
        ),
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

  Widget _socialBtn(Widget child, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: child,
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.volunteer_activism, size: 45, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Selamat Datang',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Masuk untuk melanjutkan aksi kebaikanmu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
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
                              const Text(
                                'Masuk Sebagai',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedRole = 'volunteer'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'volunteer'
                                              ? primary
                                              : (isDark(context) ? Colors.grey[800] : Colors.grey[100]),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 15,
                                              color: _selectedRole == 'volunteer' ? Colors.white : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Relawan',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: _selectedRole == 'volunteer' ? Colors.white : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedRole = 'organizer'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'organizer'
                                              ? primary
                                              : (isDark(context) ? Colors.grey[800] : Colors.grey[100]),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              size: 15,
                                              color: _selectedRole == 'organizer' ? Colors.white : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Penyelenggara',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: _selectedRole == 'organizer' ? Colors.white : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
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
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              PrimaryButton('Login', onTap: _submit),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'atau masuk dengan',
                            style: TextStyle(fontSize: 11.5, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialBtn(
                              const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDB4437),
                                ),
                              ),
                              () => _social('Google'),
                            ),
                            const SizedBox(width: 12),
                            _socialBtn(const Icon(Icons.apple, size: 22, color: Colors.black87), () => _social('Apple')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildAuthLink(
                          'Belum punya akun? ',
                          'Daftar',
                          Colors.white,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
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