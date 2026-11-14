import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/app_state.dart';
import 'providers/profile_store.dart';
import 'screens/auth_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final profile = ProfileStore();
  await profile.load(); // pengaturan tampilan & data tambahan profil
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppState()),
      ChangeNotifierProvider<ProfileStore>.value(value: profile),
    ],
    child: const VolunteerApp(),
  ));
}

/// Menerapkan pengaturan aksesibilitas (kontras tinggi & area sentuh besar) ke tema.
ThemeData _applyAccessibility(ThemeData t, ProfileStore p) {
  var r = t;
  if (p.highContrast) {
    final dark = t.brightness == Brightness.dark;
    final fg = dark ? Colors.white : Colors.black;
    r = r.copyWith(
      textTheme: r.textTheme.apply(bodyColor: fg, displayColor: fg),
      dividerColor: dark ? Colors.white54 : Colors.black54,
      colorScheme: r.colorScheme.copyWith(onSurface: fg),
    );
  }
  if (p.screenReader) {
    r = r.copyWith(materialTapTargetSize: MaterialTapTargetSize.padded);
  }
  return r;
}

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = context.watch<ProfileStore>();
    return MaterialApp(
      title: 'Volunteer',
      debugShowCheckedModeBanner: false,
      theme: _applyAccessibility(buildTheme(Brightness.light), p),
      darkTheme: _applyAccessibility(buildTheme(Brightness.dark), p),
      themeMode: s.themeMode,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final wide = mq.size.width > 700;
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear((wide ? 1.1 : 1.0) * p.textScale),
            disableAnimations: p.reduceMotion || mq.disableAnimations,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}