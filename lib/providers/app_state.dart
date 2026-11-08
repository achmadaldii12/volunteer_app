import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../models/models.dart';

enum EventSort { soonest, popular, points }

/// Seluruh logika aplikasi: auth, event, pendaftaran, poin, badge, notifikasi.
/// Data disimpan lokal (shared_preferences) sehingga tidak perlu backend.
class AppState extends ChangeNotifier {
  bool ready = false;
  List<AppUser> users = [];
  List<Registration> regs = [];
  List<Notif> notifs = [];
  List<FeedbackItem> feedbacks = [];
  Set<String> bookmarks = {};
  String? sessionUserId;
  ThemeMode themeMode = ThemeMode.light;

  // Navigasi antar tab (Beranda, Cari, Daftar, Notifikasi, Profil)
  int tab = 0;
  String searchCategory = 'Semua';

  final List<EventModel> events = buildSeedEvents();
  int _counter = 0;
  static const leaderboardSize = 1250;

  String _id(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  // ---------------------------------------------------------------- init/save
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('users') == null) {
      _seed();
      await _save();
    } else {
      _load(p);
    }
    ready = true;
    notifyListeners();
  }

  void _seed() {
    users = [buildDemoUser()];
    regs = buildDemoRegs();
    notifs = buildDemoNotifs();
    feedbacks = [];
    bookmarks = {'u_demo:e4'};
    sessionUserId = null;
  }

  List<T> _list<T>(String? s, T Function(Map<String, dynamic>) f) {
    if (s == null) return [];
    return (jsonDecode(s) as List)
        .map((e) => f(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void _load(SharedPreferences p) {
    users = _list(p.getString('users'), AppUser.fromJson);
    regs = _list(p.getString('regs'), Registration.fromJson);
    notifs = _list(p.getString('notifs'), Notif.fromJson);
    feedbacks = _list(p.getString('feedbacks'), FeedbackItem.fromJson);
    bookmarks = (p.getStringList('bookmarks') ?? []).toSet();
    sessionUserId = p.getString('session');
    final t = p.getString('theme');
    themeMode = ThemeMode.values
        .firstWhere((m) => m.name == t, orElse: () => ThemeMode.light);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('users', jsonEncode(users.map((e) => e.toJson()).toList()));
    await p.setString('regs', jsonEncode(regs.map((e) => e.toJson()).toList()));
    await p.setString('notifs', jsonEncode(notifs.map((e) => e.toJson()).toList()));
    await p.setString('feedbacks', jsonEncode(feedbacks.map((e) => e.toJson()).toList()));
    await p.setStringList('bookmarks', bookmarks.toList());
    await p.setString('theme', themeMode.name);
    if (sessionUserId == null) {
      await p.remove('session');
    } else {
      await p.setString('session', sessionUserId!);
    }
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  Future<void> resetData() async {
    _seed();
    tab = 0;
    searchCategory = 'Semua';
    await _save();
    notifyListeners();
  }

  // --------------------------------------------------------------------- auth
  AppUser? get user {
    for (final u in users) {
      if (u.id == sessionUserId) return u;
    }
    return null;
  }

  String? login(String email, String password) {
    final e = email.trim().toLowerCase();
    for (final u in users) {
      if (u.email.toLowerCase() == e) {
        if (u.password != password) return 'Password salah';
        sessionUserId = u.id;
        tab = 0;
        _commit();
        return null;
      }
    }
    return 'Akun dengan email tersebut tidak ditemukan';
  }

  void loginDemo() {
    sessionUserId = 'u_demo';
    tab = 0;
    _commit();
  }

  String? register(String name, String email, String password) {
    final e = email.trim().toLowerCase();
    if (users.any((u) => u.email.toLowerCase() == e)) {
      return 'Email sudah terdaftar, silakan login';
    }
    final u = AppUser(id: _id('u'), name: name.trim(), email: e, password: password);
    users.add(u);
    sessionUserId = u.id;
    tab = 0;
    _notify('Selamat datang di Volunteer!',
        'Yuk, cari kegiatan pertamamu dan mulai memberi dampak.', 'info');
    _commit();
    return null;
  }

  void logout() {
    sessionUserId = null;
    tab = 0;
    _commit();
  }

  void updateProfile({String? name, String? phone, String? city, String? bio}) {
    final u = user;
    if (u == null) return;
    if (name != null && name.trim().isNotEmpty) u.name = name.trim();
    if (phone != null) u.phone = phone.trim();
    if (city != null) u.city = city.trim();
    if (bio != null) u.bio = bio.trim();
    _commit();
  }

  String? changePassword(String oldPass, String newPass) {
    final u = user;
    if (u == null) return 'Sesi berakhir';
    if (u.password != oldPass) return 'Password lama salah';
    if (newPass.length < 6) return 'Password baru minimal 6 karakter';
    u.password = newPass;
    _commit();
    return null;
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _commit();
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void openSearch(String category) {
    searchCategory = category;
    tab = 1;
    notifyListeners();
  }

  void setSearchCategory(String c) {
    searchCategory = c;
    notifyListeners();
  }

  // ------------------------------------------------------------------- events
  EventModel? eventById(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  int participants(EventModel e) =>
      e.baseParticipants +
      regs.where((r) => r.eventId == e.id && r.status != RegStatus.cancelled).length;

  int remaining(EventModel e) => (e.quota - participants(e)).clamp(0, e.quota).toInt();

  List<EventModel> query({
    String category = 'Semua',
    String q = '',
    EventSort sort = EventSort.soonest,
    bool onlySaved = false,
    bool upcomingOnly = false,
  }) {
    final key = q.trim().toLowerCase();
    final list = events.where((e) {
      if (category != 'Semua' && e.category != category) return false;
      if (onlySaved && !isBookmarked(e.id)) return false;
      if (upcomingOnly && e.isFinished) return false;
      if (key.isNotEmpty &&
          !(e.title.toLowerCase().contains(key) ||
              e.organizer.toLowerCase().contains(key) ||
              e.location.toLowerCase().contains(key) ||
              e.category.toLowerCase().contains(key))) {
        return false;
      }
      return true;
    }).toList();
    switch (sort) {
      case EventSort.soonest:
        list.sort((a, b) {
          if (a.isFinished != b.isFinished) return a.isFinished ? 1 : -1;
          return a.date.compareTo(b.date);
        });
        break;
      case EventSort.popular:
        list.sort((a, b) => participants(b).compareTo(participants(a)));
        break;
      case EventSort.points:
        list.sort((a, b) => b.points.compareTo(a.points));
        break;
    }
    return list;
  }

  bool isBookmarked(String eventId) =>
      user != null && bookmarks.contains('${user!.id}:$eventId');

  void toggleBookmark(String eventId) {
    if (user == null) return;
    final k = '${user!.id}:$eventId';
    if (!bookmarks.remove(k)) bookmarks.add(k);
    _commit();
  }

  // ------------------------------------------------------------ registrations
  List<Registration> get myRegs {
    final list = regs.where((r) => r.userId == user?.id).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Registration> get attendedRegs =>
      myRegs.where((r) => r.status == RegStatus.attended).toList();

  /// Pendaftaran aktif (belum dibatalkan) milik user untuk sebuah event.
  Registration? regOf(String eventId) {
    for (final r in regs) {
      if (r.userId == user?.id && r.eventId == eventId && r.status != RegStatus.cancelled) {
        return r;
      }
    }
    return null;
  }

  String _makeCode(EventModel e) {
    final d = e.date;
    final seq = regs.where((r) => r.eventId == e.id).length + 1;
    return 'VOL${d.year}${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}${seq.toString().padLeft(3, '0')}';
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  String? registerEvent(EventModel e) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    if (e.isFinished) return 'Kegiatan ini sudah selesai';
    if (regOf(e.id) != null) return 'Kamu sudah terdaftar pada kegiatan ini';
    if (remaining(e) <= 0) return 'Kuota kegiatan sudah penuh';
    regs.add(Registration(
        id: _id('r'), userId: u.id, eventId: e.id, code: _makeCode(e), createdAt: DateTime.now()));
    _notify('Pendaftaran berhasil', 'Kamu terdaftar di ${e.title}. Tunjukkan QR saat hadir.', 'register');
    _commit();
    return null;
  }

  void cancelReg(String regId) {
    for (final r in regs) {
      if (r.id == regId && r.status == RegStatus.registered) {
        r.status = RegStatus.cancelled;
        final e = eventById(r.eventId);
        _notify('Pendaftaran dibatalkan', 'Kamu membatalkan pendaftaran ${e?.title ?? 'kegiatan'}.', 'cancel');
      }
    }
    _commit();
  }

  /// Simulasi check-in: mencatat kehadiran, menambah poin, dan membuka badge.
  void markAttended(String regId) {
    final before = earnedBadges.map((b) => b.name).toSet();
    for (final r in regs) {
      if (r.id == regId && r.status == RegStatus.registered) {
        r.status = RegStatus.attended;
        final e = eventById(r.eventId);
        if (e != null) {
          _notify('Kehadiran tercatat', '+${e.points} poin dari ${e.title}. Sertifikat sudah tersedia.', 'attend');
        }
      }
    }
    for (final b in earnedBadges) {
      if (!before.contains(b.name)) {
        _notify('Badge baru!', 'Selamat, kamu mendapatkan badge ${b.name}.', 'badge');
      }
    }
    _commit();
  }

  // -------------------------------------------------------------------- stats
  int _sumAttended(int Function(EventModel) f) {
    var total = 0;
    for (final r in attendedRegs) {
      final e = eventById(r.eventId);
      if (e != null) total += f(e);
    }
    return total;
  }

  int get totalEvents => (user?.pastEvents ?? 0) + attendedRegs.length;
  int get totalHours => (user?.pastHours ?? 0) + _sumAttended((e) => e.hours);
  int get totalPoints => (user?.pastPoints ?? 0) + _sumAttended((e) => e.points);
  int get totalImpact => (user?.pastImpact ?? 0) + _sumAttended((e) => e.impact);

  int metricValue(BadgeMetric m) {
    switch (m) {
      case BadgeMetric.events:
        return totalEvents;
      case BadgeMetric.hours:
        return totalHours;
      case BadgeMetric.points:
        return totalPoints;
      case BadgeMetric.impact:
        return totalImpact;
    }
  }

  double badgeProgress(BadgeDef b) => (metricValue(b.metric) / b.target).clamp(0.0, 1.0).toDouble();
  bool isEarned(BadgeDef b) => metricValue(b.metric) >= b.target;
  List<BadgeDef> get earnedBadges => kBadges.where(isEarned).toList();

  /// Peringkat di antara [leaderboardSize] relawan (berdasarkan poin).
  int get rank {
    final p = totalPoints;
    if (p >= 2350) return max(1, 12 - (p - 2350) ~/ 100);
    return 12 + (1238 * pow(1 - p / 2350, 2)).round();
  }

  // ------------------------------------------------------------- notifikasi
  void _notify(String title, String body, String kind) {
    final u = user;
    if (u == null) return;
    notifs.insert(0, Notif(
        id: _id('n'), userId: u.id, title: title, body: body, kind: kind, createdAt: DateTime.now()));
  }

  List<Notif> get myNotifs => notifs.where((n) => n.userId == user?.id).toList();
  int get unreadCount => myNotifs.where((n) => !n.read).length;

  void markAllRead() {
    for (final n in myNotifs) {
      n.read = true;
    }
    _commit();
  }

  void markRead(String id) {
    for (final n in notifs) {
      if (n.id == id) n.read = true;
    }
    _commit();
  }

  // ----------------------------------------------------------------- feedback
  void submitFeedback(String eventTitle, int rating, String text) {
    final u = user;
    if (u == null) return;
    feedbacks.insert(0, FeedbackItem(
        id: _id('f'), userId: u.id, eventTitle: eventTitle, text: text.trim(),
        rating: rating, createdAt: DateTime.now()));
    _commit();
  }

  List<FeedbackItem> get myFeedbacks => feedbacks.where((f) => f.userId == user?.id).toList();
}
