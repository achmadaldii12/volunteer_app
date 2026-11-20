import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Alamat server backend (Laragon).
///
/// Urutan prioritas:
///  1. Alamat yang diisi lewat dialog "Pengaturan Server" (tekan LAMA logo di layar Login).
///  2. --dart-define=API_BASE=http://...   (saat flutter run / build)
///  3. Bawaan: emulator Android -> 10.0.2.2:8000 , Flutter Web/Chrome -> localhost:8000 (php artisan serve)
class ApiConfig {
  static const String _defined = String.fromEnvironment('API_BASE', defaultValue: '');
  static const String _prefKey = 'api_base_url';
  static String? _custom;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_prefKey);
    _custom = (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  static String get defaultUrl => kIsWeb
      ? 'http://localhost:8000/api'
      : 'http://10.0.2.2:8000/api';

  static String get baseUrl => _custom ?? (_defined.isNotEmpty ? _defined : defaultUrl);

  /// Mengubah masukan sederhana ("192.168.1.5") menjadi alamat API lengkap.
  static String normalize(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    s = s.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(s);
    final port = uri.hasPort ? uri.port : 8000;
    var path = uri.path;
    if (!path.endsWith('/api')) path = (path.isEmpty || path == '/') ? '/api' : '$path/api';
    return '${uri.scheme}://${uri.host}:$port$path';
  }

  /// Simpan alamat kustom. Kosong = kembali ke bawaan.
  static Future<void> setCustom(String? value) async {
    final p = await SharedPreferences.getInstance();
    final v = (value == null || value.trim().isEmpty) ? null : normalize(value);
    _custom = v;
    if (v == null) {
      await p.remove(_prefKey);
    } else {
      await p.setString(_prefKey, v);
    }
  }
}
