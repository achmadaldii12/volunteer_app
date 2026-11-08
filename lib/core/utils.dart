import 'package:intl/intl.dart';

String fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
String fmtLongDate(DateTime d) => DateFormat('d MMMM yyyy', 'id_ID').format(d);
String fmtDateTime(DateTime d) => DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(d);
String fmtNum(num n) => NumberFormat.decimalPattern('id_ID').format(n);

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return fmtDate(d);
}

String? validateRequired(String? v, String label) =>
    (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
  final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v.trim());
  return ok ? null : 'Format email tidak valid';
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password wajib diisi';
  if (v.length < 6) return 'Password minimal 6 karakter';
  return null;
}
