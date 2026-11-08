import 'package:flutter/material.dart';

class AppColors {
  // Palet Warna Merah Kemanusiaan (Selaras dengan referensi platform relawan)
  static const primary = Color(0xFFDC2626); // Red Utama
  static const primaryDark = Color(0xFFB91C1C);
  static const primaryLight = Color(0xFFEF4444);
  static const soft = Color(0xFFFEF2F2); // Soft Red yang bersih & nyaman
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
}

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  const CategoryInfo(this.name, this.icon, this.color);
}

const List<CategoryInfo> kCategories = [
  CategoryInfo('Edukasi', Icons.school_outlined, Color(0xFF2563EB)),
  CategoryInfo('Lingkungan', Icons.eco_outlined, Color(0xFF15803D)),
  CategoryInfo('Sosial', Icons.volunteer_activism, Color(0xFFEA580C)),
  CategoryInfo('Kemanusiaan', Icons.favorite_outline, Color(0xFFDB2777)),
];

CategoryInfo categoryInfo(String name) =>
    kCategories.firstWhere((c) => c.name == name, orElse: () => kCategories[2]);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color softOf(BuildContext c) => isDark(c) ? const Color(0xFF451A03) : AppColors.soft;
Color muted(BuildContext c) => Theme.of(c).colorScheme.onSurface.withOpacity(.7);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: b)
      .copyWith(primary: dark ? AppColors.primaryLight : AppColors.primary);

  // Menggunakan kombinasi font modern kelas atas yang tebal dan jelas
  const String customFont = 'Montserrat';
  const List<String> fontFallbacks = ['Montserrat', 'Inter', 'SF Pro Display', 'Roboto', 'sans-serif'];

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF181212) : Colors.white,
    fontFamily: customFont,
    fontFamilyFallback: fontFallbacks,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displayMedium: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displaySmall: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      headlineLarge: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineMedium: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      titleMedium: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      titleSmall: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      bodyMedium: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.normal, letterSpacing: 0.1),
      bodySmall: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelMedium: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: customFont, fontFamilyFallback: fontFallbacks),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF181212) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontFamily: customFont,
          fontFamilyFallback: fontFallbacks,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: dark ? Colors.white : Colors.black87),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// Kompatibilitas fungsi tema opsional jika dibutuhkan di file lain
ThemeData appTheme(BuildContext context) => buildTheme(Brightness.light);
ThemeData appDarkTheme(BuildContext context) => buildTheme(Brightness.dark);