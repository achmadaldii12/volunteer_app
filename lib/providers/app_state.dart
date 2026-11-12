import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../data/leaderboard_seed.dart';
import '../data/community_seed.dart';
import '../models/community.dart';
import '../models/models.dart';
import '../models/gamification.dart';

enum EventSort { soonest, popular, points }

/// Seluruh logika aplikasi: auth, event, pendaftaran, poin, badge, notifikasi.
/// Data disimpan lokal (shared_preferences) sehingga tidak perlu backend.
class AppState extends ChangeNotifier {
  bool ready = false;
  List<AppUser> users = [];
  List<Registration> regs = [];
  List<Notif> notifs = [];
  List<FeedbackItem> feedbacks = [];
  List<PointEntry> pointEntries = []; // riwayat poin semua pengguna (disimpan permanen)
  final List<Celebration> _celebrations = []; // antrean popup poin / badge / level
  // ---- Komunitas (disimpan permanen) ----
  List<CommMessage> commMessages = [];
  List<Announcement> announcements = [];
  List<CommPoll> polls = [];
  List<CommReport> commReports = [];
  Set<String> commBlocked = {}; // format "idSaya:idDiblokir"
  Map<String, int> commLastRead = {}; // format "idSaya:idRuang" -> waktu terakhir dibaca
  Set<String> commAdmins = {};
  Set<String> bookmarks = {};
  String? sessionUserId;
  ThemeMode themeMode = ThemeMode.light;

  // Navigasi antar tab (Beranda, Cari, Daftar, Notifikasi, Profil)
  int tab = 0;
  String searchCategory = 'Semua';

  final List<EventModel> events = buildSeedEvents();
  int _counter = 0;

  String _id(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  // ---------------------------------------------------------------- init/save
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('users') == null) {
      _seed();
      await _save();
    } else {
      _load(p);
      // Migrasi: aplikasi versi lama belum punya riwayat poin
      if (p.getString('points') == null) {
        _initPointLedger();
        await _save();
      }
      // Migrasi: aplikasi versi lama belum punya data komunitas
      if (p.getString('comm_messages') == null) {
        _seedCommunity();
        await _save();
      }
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
    pointEntries = [];
    _celebrations.clear();
    _initPointLedger();
    _seedCommunity();
  }

  /// Isi awal Komunitas (pesan, pengumuman, polling) + notifikasi awal untuk akun yang ada.
  void _seedCommunity() {
    final pack = buildCommunitySeed(events);
    commMessages = pack.messages;
    announcements = pack.announcements;
    polls = pack.polls;
    commReports = [];
    commBlocked = {};
    commLastRead = {};
    commAdmins = {kDefaultAdminId};
    for (final u in users) {
      if (u.id.startsWith(kSeedUserPrefix)) continue;
      if (notifs.any((n) => n.userId == u.id && n.kind.startsWith('comm_'))) continue;
      final now = DateTime.now();
      notifs.insert(0, Notif(
          id: _id('n'), userId: u.id, title: 'Pengumuman penting', body: pack.announcements.first.title,
          kind: 'comm_announce:${pack.announcements.first.id}', createdAt: now.subtract(const Duration(hours: 20))));
      notifs.insert(0, Notif(
          id: _id('n'), userId: u.id, title: 'Undangan event dari Budi Santoso',
          body: 'Ayo ajak relawan ke event pilihan! Cek ruang Umum.',
          kind: 'comm_invite:umum', createdAt: now.subtract(const Duration(minutes: 80))));
      notifs.insert(0, Notif(
          id: _id('n'), userId: u.id, title: 'Pesan baru di Umum',
          body: 'Siti Rahmawati: Halo relawan! Ada yang mau ikut aksi tanam mangrove minggu ini?',
          kind: 'comm_msg:umum', createdAt: now.subtract(const Duration(minutes: 40))));
    }
  }

  /// Dipakai oleh logika komunitas (community_logic.dart).
  String newId(String prefix) => _id(prefix);

  /// Menyimpan perubahan data komunitas dan memperbarui tampilan.
  void commitCommunity() => _commit();

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
    pointEntries = _list(p.getString('points'), PointEntry.fromJson);
    commMessages = _list(p.getString('comm_messages'), CommMessage.fromJson);
    announcements = _list(p.getString('comm_announcements'), Announcement.fromJson);
    polls = _list(p.getString('comm_polls'), CommPoll.fromJson);
    commReports = _list(p.getString('comm_reports'), CommReport.fromJson);
    commBlocked = (p.getStringList('comm_blocked') ?? []).toSet();
    commAdmins = (p.getStringList('comm_admins') ?? [kDefaultAdminId]).toSet();
    commLastRead = {};
    final lr = p.getString('comm_lastread');
    if (lr != null) {
      (jsonDecode(lr) as Map).forEach((k, v) {
        commLastRead[k.toString()] = (v as num).toInt();
      });
    }
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
    await p.setString('points', jsonEncode(pointEntries.map((e) => e.toJson()).toList()));
    await p.setString('comm_messages', jsonEncode(commMessages.map((e) => e.toJson()).toList()));
    await p.setString('comm_announcements', jsonEncode(announcements.map((e) => e.toJson()).toList()));
    await p.setString('comm_polls', jsonEncode(polls.map((e) => e.toJson()).toList()));
    await p.setString('comm_reports', jsonEncode(commReports.map((e) => e.toJson()).toList()));
    await p.setStringList('comm_blocked', commBlocked.toList());
    await p.setStringList('comm_admins', commAdmins.toList());
    await p.setString('comm_lastread', jsonEncode(commLastRead));
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

  /// Verifikasi kehadiran oleh panitia (di aplikasi ini disimulasikan lewat menu
  /// "Verifikasi Kehadiran"). Poin HANYA diberikan di sini, bukan saat mendaftar.
  /// Mengembalikan jumlah poin yang diperoleh (0 jika tidak ada / sudah pernah).
  int markAttended(String regId) {
    final u = user;
    if (u == null) return 0;
    Registration? reg;
    for (final r in regs) {
      if (r.id == regId && r.userId == u.id) reg = r;
    }
    if (reg == null || reg.status != RegStatus.registered) return 0;
    final e = eventById(reg.eventId);
    if (e == null) return 0;

    final badgesBefore = badgeIdsOf(u.id);
    final levelBefore = levelIndexOf(pointsOf(u.id));

    reg.status = RegStatus.attended;

    // +40 poin untuk menyelesaikan event (anti dobel per event)
    var gained = _award(u, e, PointType.event, kPointsPerEvent, 'Kehadiran terverifikasi oleh panitia');

    // +50 bonus setiap kelipatan 5 event
    final done = eventsOf(u.id);
    if (gained > 0 && done % 5 == 0) {
      gained += _award(u, e, PointType.bonus, kPointsBonus5Events, 'Bonus menyelesaikan $done event');
    }

    _notify('Kehadiran terverifikasi', '+$gained poin dari ${e.title}. Sertifikat sudah tersedia.', 'attend');
    _afterPoints(u, gained, e.title, badgesBefore, levelBefore);
    _commit();
    return gained;
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

  int get totalEvents => user == null ? 0 : eventsOf(user!.id);
  int get totalHours => (user?.pastHours ?? 0) + _sumAttended((e) => e.hours);
  int get totalPoints => user == null ? 0 : pointsOf(user!.id);
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

  /// Peringkat sepanjang waktu pengguna yang sedang login.
  int get rank => myRankEntry(RankPeriod.allTime)?.rank ?? 0;

  // ======================================================================
  // POIN, LEVEL, BADGE, LEADERBOARD, VOLUNTEER OF THE MONTH
  // ======================================================================
  AppUser? userById(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Total poin terverifikasi milik seorang pengguna.
  int pointsOf(String userId) {
    var t = 0;
    for (final e in pointEntries) {
      if (e.userId == userId && e.verified) t += e.points;
    }
    return t;
  }

  /// Jumlah event yang diselesaikan (riwayat lama + kehadiran terverifikasi).
  int eventsOf(String userId) {
    var n = userById(userId)?.pastEvents ?? 0;
    for (final r in regs) {
      if (r.userId == userId && r.status == RegStatus.attended) n++;
    }
    return n;
  }

  bool _hasEntry(String userId, String? eventId, String type) => pointEntries
      .any((x) => x.userId == userId && x.eventId == eventId && x.type == type);

  /// Menambah poin. Satu jenis poin hanya bisa diberikan 1x per event (anti dobel).
  int _award(AppUser u, EventModel e, String type, int pts, String note) {
    if (_hasEntry(u.id, e.id, type)) return 0;
    pointEntries.add(PointEntry(
      id: _id('p'),
      userId: u.id,
      eventId: e.id,
      title: e.title,
      category: e.category,
      type: type,
      points: pts,
      note: note,
      date: e.date,
      createdAt: DateTime.now(),
    ));
    return pts;
  }

  /// Poin tambahan dari panitia untuk kegiatan yang SUDAH diverifikasi hadir.
  String? awardCoordinator(String regId) => _awardExtra(
      regId, PointType.coordinator, kPointsCoordinator, 'Menjadi koordinator kegiatan');

  String? awardAppreciation(String regId) => _awardExtra(
      regId, PointType.appreciation, kPointsAppreciation, 'Apresiasi dari panitia');

  String? _awardExtra(String regId, String type, int pts, String note) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    Registration? reg;
    for (final r in regs) {
      if (r.id == regId && r.userId == u.id) reg = r;
    }
    if (reg == null) return 'Pendaftaran tidak ditemukan';
    if (reg.status != RegStatus.attended) return 'Kehadiran harus diverifikasi panitia terlebih dahulu';
    final e = eventById(reg.eventId);
    if (e == null) return 'Kegiatan tidak ditemukan';
    if (_hasEntry(u.id, e.id, type)) return 'Poin ini sudah pernah diberikan untuk kegiatan tersebut';

    final badgesBefore = badgeIdsOf(u.id);
    final levelBefore = levelIndexOf(pointsOf(u.id));
    final gained = _award(u, e, type, pts, note);
    _notify('Poin tambahan', '+$gained poin: $note (${e.title}).', 'attend');
    _afterPoints(u, gained, '$note • ${e.title}', badgesBefore, levelBefore);
    _commit();
    return null;
  }

  /// Menyusun popup penghargaan (poin, level naik, badge baru) + notifikasi badge.
  void _afterPoints(AppUser u, int gained, String source, Set<String> badgesBefore, int levelBefore) {
    if (gained > 0) {
      _celebrations.add(Celebration(
        kind: CelebrationKind.points,
        title: '+$gained Poin',
        subtitle: source,
        icon: Icons.stars_rounded,
        color: const Color(0xFFF59E0B),
        points: gained,
      ));
    }
    final levelAfter = levelIndexOf(pointsOf(u.id));
    if (levelAfter > levelBefore) {
      final lv = kLevels[levelAfter];
      _celebrations.add(Celebration(
        kind: CelebrationKind.level,
        title: 'Naik Level!',
        subtitle: 'Selamat, kamu sekarang level ${lv.name}',
        icon: lv.icon,
        color: lv.color,
      ));
      _notify('Naik level!', 'Kamu sekarang berada di level ${lv.name}.', 'badge');
    }
    final after = badgeIdsOf(u.id);
    for (final b in kAchBadges) {
      if (after.contains(b.id) && !badgesBefore.contains(b.id)) {
        _celebrations.add(Celebration(
          kind: CelebrationKind.badge,
          title: 'Badge Baru!',
          subtitle: '${b.name} • ${b.desc}',
          icon: b.icon,
          color: b.color,
        ));
        _notify('Badge baru!', 'Selamat, kamu mendapatkan badge ${b.name}.', 'badge');
      }
    }
  }

  /// Mengambil (dan mengosongkan) antrean popup penghargaan.
  List<Celebration> takeCelebrations() {
    final list = List<Celebration>.from(_celebrations);
    _celebrations.clear();
    return list;
  }

  // ---------------------------------------------------------------- badge
  int _categoryCount(String userId, String category) {
    final ids = <String>{};
    for (final e in pointEntries) {
      if (e.userId == userId && e.verified && e.type == PointType.event && e.category == category) {
        ids.add(e.eventId ?? e.id);
      }
    }
    return ids.length;
  }

  int achValue(String userId, AchMetric m) {
    switch (m) {
      case AchMetric.started:
        final u = userById(userId);
        return regs.where((r) => r.userId == userId).length + ((u?.pastEvents ?? 0) > 0 ? 1 : 0);
      case AchMetric.events:
        return eventsOf(userId);
      case AchMetric.lingkungan:
        return _categoryCount(userId, 'Lingkungan');
      case AchMetric.edukasi:
        return _categoryCount(userId, 'Edukasi');
      case AchMetric.points:
        return pointsOf(userId);
    }
  }

  bool achEarned(String userId, AchBadge b) => achValue(userId, b.metric) >= b.target;

  double achProgress(String userId, AchBadge b) =>
      (achValue(userId, b.metric) / b.target).clamp(0.0, 1.0).toDouble();

  Set<String> badgeIdsOf(String userId) =>
      kAchBadges.where((b) => achEarned(userId, b)).map((b) => b.id).toSet();

  // ------------------------------------------------------------- streak
  int _weekIndex(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1970, 1, 5)).inDays ~/ 7;

  /// Streak = jumlah minggu berturut-turut yang memiliki minimal 1 event terverifikasi.
  int streakOf(String userId) {
    final weeks = <int>{};
    for (final e in pointEntries) {
      if (e.userId == userId && e.verified && e.type == PointType.event) {
        weeks.add(_weekIndex(e.createdAt));
      }
    }
    if (weeks.isEmpty) return 0;
    var w = _weekIndex(DateTime.now());
    if (!weeks.contains(w)) w -= 1;
    var s = 0;
    while (weeks.contains(w)) {
      s++;
      w--;
    }
    return s;
  }

  // -------------------------------------------------------------- ranking
  DateTime? _periodStart(RankPeriod p) {
    final now = DateTime.now();
    switch (p) {
      case RankPeriod.weekly:
        return now.subtract(const Duration(days: 7));
      case RankPeriod.monthly:
        return now.subtract(const Duration(days: 30));
      case RankPeriod.allTime:
        return null;
    }
  }

  /// Leaderboard otomatis: diurutkan dari poin tertinggi pada periode terpilih.
  /// Seri dipecah oleh total poin sepanjang waktu, lalu nama.
  List<RankEntry> leaderboard(RankPeriod p) {
    final start = _periodStart(p);
    final inPeriod = <String, int>{};
    final eventsIn = <String, int>{};
    final all = <String, int>{};
    for (final e in pointEntries) {
      if (!e.verified) continue;
      all[e.userId] = (all[e.userId] ?? 0) + e.points;
      if (start == null || !e.createdAt.isBefore(start)) {
        inPeriod[e.userId] = (inPeriod[e.userId] ?? 0) + e.points;
        if (e.type == PointType.event) eventsIn[e.userId] = (eventsIn[e.userId] ?? 0) + 1;
      }
    }
    final list = users
        .map((u) => RankEntry(
              user: u,
              points: inPeriod[u.id] ?? 0,
              totalPoints: all[u.id] ?? 0,
              events: eventsIn[u.id] ?? 0,
              rank: 0,
              isMe: u.id == sessionUserId,
            ))
        .toList();
    list.sort((a, b) {
      final c = b.points.compareTo(a.points);
      if (c != 0) return c;
      final d = b.totalPoints.compareTo(a.totalPoints);
      if (d != 0) return d;
      return a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
    });
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].withRank(i + 1);
    }
    return list;
  }

  RankEntry? myRankEntry(RankPeriod p) {
    for (final e in leaderboard(p)) {
      if (e.isMe) return e;
    }
    return null;
  }

  // ------------------------------------------------- volunteer of the month
  /// Bulan berjalan; jika belum ada aktivitas sama sekali, memakai bulan lalu.
  MonthlyBoard monthlyBoard() {
    final now = DateTime.now();
    var m = DateTime(now.year, now.month);
    var stars = _starsFor(m);
    if (stars.isEmpty) {
      m = DateTime(now.year, now.month - 1);
      stars = _starsFor(m);
    }
    return MonthlyBoard(m, stars);
  }

  /// Skor = poin bulan itu + 20 x jumlah minggu aktif (konsistensi).
  /// Poin sudah memuat jumlah event (+40) dan kontribusi (koordinator / apresiasi).
  List<MonthlyStar> _starsFor(DateTime month) {
    final end = DateTime(month.year, month.month + 1);
    final pts = <String, int>{};
    final evs = <String, int>{};
    final contrib = <String, int>{};
    final weeks = <String, Set<int>>{};
    for (final e in pointEntries) {
      if (!e.verified || e.type == PointType.opening) continue;
      if (e.createdAt.isBefore(month) || !e.createdAt.isBefore(end)) continue;
      pts[e.userId] = (pts[e.userId] ?? 0) + e.points;
      if (e.type == PointType.event) {
        evs[e.userId] = (evs[e.userId] ?? 0) + 1;
        (weeks[e.userId] ??= <int>{}).add(_weekIndex(e.createdAt));
      }
      if (e.type == PointType.coordinator || e.type == PointType.appreciation) {
        contrib[e.userId] = (contrib[e.userId] ?? 0) + e.points;
      }
    }
    final list = <MonthlyStar>[];
    for (final u in users) {
      final p = pts[u.id] ?? 0;
      if (p <= 0) continue;
      final w = weeks[u.id]?.length ?? 0;
      list.add(MonthlyStar(
        user: u,
        points: p,
        events: evs[u.id] ?? 0,
        activeWeeks: w,
        contribution: contrib[u.id] ?? 0,
        score: p + 20 * w,
        isMe: u.id == sessionUserId,
      ));
    }
    list.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      return b.events.compareTo(a.events);
    });
    return list;
  }

  // -------------------------------------------------------- riwayat poin
  /// Riwayat poin pengguna: poin terverifikasi + poin yang masih menunggu verifikasi
  /// (kegiatan sudah didaftar tapi kehadiran belum diverifikasi, belum dihitung).
  List<PointEntry> get myPointHistory {
    final u = user;
    if (u == null) return [];
    final list = pointEntries.where((e) => e.userId == u.id).toList();
    for (final r in regs) {
      if (r.userId == u.id && r.status == RegStatus.registered) {
        final e = eventById(r.eventId);
        if (e == null) continue;
        list.add(PointEntry(
          id: 'pending_${r.id}',
          userId: u.id,
          eventId: e.id,
          title: e.title,
          category: e.category,
          type: PointType.event,
          points: kPointsPerEvent,
          note: 'Menunggu verifikasi kehadiran oleh panitia',
          date: e.date,
          createdAt: r.createdAt,
          verified: false,
        ));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ------------------------------------------- inisialisasi / migrasi data
  /// Membuat relawan awal untuk leaderboard dan riwayat poin akun yang sudah ada.
  void _initPointLedger() {
    final pack = buildSeedVolunteers();
    for (final u in pack.users) {
      if (userById(u.id) == null) users.add(u);
    }
    for (final e in pack.entries) {
      if (!pointEntries.any((x) => x.id == e.id)) pointEntries.add(e);
    }
    for (final u in users) {
      if (u.id.startsWith(kSeedUserPrefix)) continue;
      if (pointEntries.any((x) => x.userId == u.id)) continue;
      _migrateUser(u);
    }
  }

  void _migrateUser(AppUser u) {
    final now = DateTime.now();
    final past = now.subtract(const Duration(days: 365));
    if (u.pastPoints > 0) {
      pointEntries.add(PointEntry(
        id: 'p_open_${u.id}',
        userId: u.id,
        title: 'Poin dari kegiatan sebelumnya',
        type: PointType.opening,
        points: u.pastPoints,
        date: past,
        createdAt: past,
        note: 'Akumulasi poin sebelum sistem riwayat aktif',
      ));
    }
    var count = u.pastEvents;
    final att = regs.where((r) => r.userId == u.id && r.status == RegStatus.attended).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final r in att) {
      final e = eventById(r.eventId);
      if (e == null) continue;
      count++;
      pointEntries.add(PointEntry(
        id: _id('p'),
        userId: u.id,
        eventId: e.id,
        title: e.title,
        category: e.category,
        type: PointType.event,
        points: kPointsPerEvent,
        note: 'Kehadiran terverifikasi oleh panitia',
        date: e.date,
        createdAt: r.createdAt,
      ));
      if (count % 5 == 0) {
        pointEntries.add(PointEntry(
          id: _id('p'),
          userId: u.id,
          eventId: e.id,
          title: e.title,
          category: e.category,
          type: PointType.bonus,
          points: kPointsBonus5Events,
          note: 'Bonus menyelesaikan $count event',
          date: e.date,
          createdAt: r.createdAt,
        ));
      }
    }
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