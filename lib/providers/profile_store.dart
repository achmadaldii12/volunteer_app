import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import 'app_state.dart';

// ============================================================
// MODEL KECIL
// ============================================================
class MonthStat {
  final DateTime month;
  final int events, hours, points;
  const MonthStat(this.month, this.events, this.hours, this.points);
}

class BadgeStatus {
  final bool earned;
  final DateTime? date; // null + earned = diperoleh sebelum pencatatan riwayat
  const BadgeStatus(this.earned, this.date);
}

class JourneyItem {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const JourneyItem(this.date, this.icon, this.color, this.title, this.subtitle);
}

/// Kunci pengaturan notifikasi.
const List<String> kNotifKeys = ['event', 'reminder', 'community', 'announce', 'points', 'badge'];

// ============================================================
// PROFILE STORE
// Menyimpan pengaturan tampilan (bahasa, ukuran teks, kontras, animasi) dan data
// tambahan profil per akun (foto, target pribadi, pengaturan notifikasi, dll.)
// di penyimpanan lokal (shared_preferences).
// ============================================================
class ProfileStore extends ChangeNotifier {
  SharedPreferences? _p;

  // ---- pengaturan tampilan (berlaku untuk seluruh aplikasi) ----
  String language = 'id'; // 'id' atau 'en'
  double textScale = 1.0;
  bool highContrast = false;
  bool screenReader = false;
  bool reduceMotion = false;
  final DateTime sessionStart = DateTime.now();

  bool get isEnglish => language == 'en';

  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Uint8List?> _avatars = {};

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _p = p;
    language = p.getString('pf_lang') ?? 'id';
    textScale = p.getDouble('pf_text_scale') ?? 1.0;
    highContrast = p.getBool('pf_contrast') ?? false;
    screenReader = p.getBool('pf_reader') ?? false;
    reduceMotion = p.getBool('pf_reduce_motion') ?? false;
    notifyListeners();
  }

  void setLanguage(String v) {
    language = v;
    _p?.setString('pf_lang', v);
    notifyListeners();
  }

  void setTextScale(double v) {
    textScale = v;
    _p?.setDouble('pf_text_scale', v);
    notifyListeners();
  }

  void setHighContrast(bool v) {
    highContrast = v;
    _p?.setBool('pf_contrast', v);
    notifyListeners();
  }

  void setScreenReader(bool v) {
    screenReader = v;
    _p?.setBool('pf_reader', v);
    notifyListeners();
  }

  void setReduceMotion(bool v) {
    reduceMotion = v;
    _p?.setBool('pf_reduce_motion', v);
    notifyListeners();
  }

  // ---- data per akun ----
  Map<String, dynamic> _u(String id) {
    final cached = _users[id];
    if (cached != null) return cached;
    Map<String, dynamic> m = {};
    final raw = _p?.getString('pf_user_$id');
    if (raw != null) {
      try {
        m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        m = {};
      }
    }
    _users[id] = m;
    return m;
  }

  void _write(String id) => _p?.setString('pf_user_$id', jsonEncode(_u(id)));

  void _saveUser(String id) {
    _write(id);
    notifyListeners();
  }

  /// Menghapus semua data tambahan akun (dipakai saat akun dihapus).
  void clearUser(String id) {
    _users.remove(id);
    _avatars.remove(id);
    _p?.remove('pf_user_$id');
    notifyListeners();
  }

  // foto profil
  Uint8List? avatarOf(String id) {
    if (_avatars.containsKey(id)) return _avatars[id];
    final b64 = _u(id)['avatar'] as String?;
    Uint8List? bytes;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        bytes = null;
      }
    }
    _avatars[id] = bytes;
    return bytes;
  }

  void setAvatar(String id, Uint8List? bytes) {
    _avatars[id] = bytes;
    if (bytes == null) {
      _u(id).remove('avatar');
    } else {
      _u(id)['avatar'] = base64Encode(bytes);
    }
    _saveUser(id);
  }

  // target pribadi
  int goalEvents(String id) => (_u(id)['goalEvents'] as num?)?.toInt() ?? 4;
  int goalHours(String id) => (_u(id)['goalHours'] as num?)?.toInt() ?? 10;

  void setGoals(String id, int events, int hours) {
    _u(id)['goalEvents'] = events;
    _u(id)['goalHours'] = hours;
    _saveUser(id);
  }

  bool goalNotified(String id, String key) {
    final l = _u(id)['goalNotified'];
    return l is List && l.contains(key);
  }

  void markGoalNotified(String id, String key) {
    final l = List<String>.from((_u(id)['goalNotified'] as List?) ?? const []);
    if (!l.contains(key)) l.add(key);
    _u(id)['goalNotified'] = l;
    _write(id); // tanpa notifyListeners (dipanggil saat build)
  }

  // pengaturan notifikasi
  bool notifOn(String id, String key) => (_u(id)['n_$key'] as bool?) ?? true;

  void setNotif(String id, String key, bool v) {
    _u(id)['n_$key'] = v;
    _saveUser(id);
  }

  /// Apakah notifikasi dengan jenis [kind] boleh ditampilkan untuk pengguna ini.
  bool allows(String userId, String kind) {
    String key;
    if (kind.startsWith('comm_announce')) {
      key = 'announce';
    } else if (kind.startsWith('comm_')) {
      key = 'community';
    } else if (kind == 'attend') {
      key = 'points';
    } else if (kind == 'badge') {
      key = 'badge';
    } else if (kind == 'register' || kind == 'cancel') {
      key = 'reminder';
    } else {
      key = 'event';
    }
    return notifOn(userId, key);
  }

  // verifikasi email (lokal)
  bool emailVerified(String id, String email) => _u(id)['verifiedEmail'] == email.trim().toLowerCase();

  void setEmailVerified(String id, String email) {
    _u(id)['verifiedEmail'] = email.trim().toLowerCase();
    _saveUser(id);
  }

  // tanggal bergabung
  DateTime joinedAt(String id, {DateTime? evidence}) {
    final ms = (_u(id)['joinedAt'] as num?)?.toInt();
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    final d = evidence ?? DateTime.now();
    _u(id)['joinedAt'] = d.millisecondsSinceEpoch;
    _write(id);
    return d;
  }

  // laporan masalah / saran / pesan ke admin (disimpan lokal)
  List<Map<String, dynamic>> tickets(String id) {
    final raw = (_u(id)['tickets'] as List?) ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void addTicket(String id, String type, String text) {
    final list = tickets(id);
    list.insert(0, {'type': type, 'text': text, 'at': DateTime.now().millisecondsSinceEpoch});
    _u(id)['tickets'] = list;
    _saveUser(id);
  }
}

// ============================================================
// AKUN: ubah email & hapus akun (memakai data AppState yang sudah ada)
// ============================================================
extension ProfileAccount on AppState {
  /// Mengubah email akun. Mengembalikan pesan error atau null jika berhasil.
  String? updateEmail(String newEmail) {
    final u = user;
    if (u == null) return 'Sesi berakhir, silakan login kembali';
    final e = newEmail.trim().toLowerCase();
    final err = validateEmail(e);
    if (err != null) return err;
    if (e == u.email.toLowerCase()) return null;
    if (users.any((x) => x.id != u.id && x.email.toLowerCase() == e)) {
      return 'Email sudah dipakai akun lain';
    }
    u.email = e;
    commitCommunity();
    return null;
  }

  /// Menghapus akun beserta datanya. Memerlukan password untuk konfirmasi.
  String? deleteAccount(String password) {
    final u = user;
    if (u == null) return 'Sesi berakhir, silakan login kembali';
    if (u.password != password) return 'Password salah';
    final id = u.id;
    users.removeWhere((x) => x.id == id);
    regs.removeWhere((r) => r.userId == id);
    notifs.removeWhere((n) => n.userId == id);
    feedbacks.removeWhere((f) => f.userId == id);
    pointEntries.removeWhere((p) => p.userId == id);
    bookmarks.removeWhere((k) => k.startsWith('$id:'));
    commMessages.removeWhere((m) => m.senderId == id);
    for (final m in commMessages) {
      m.reactions.forEach((k, l) => l.remove(id));
      m.reactions.removeWhere((k, l) => l.isEmpty);
    }
    for (final p in polls) {
      p.votes.remove(id);
    }
    commReports.removeWhere((r) => r.reporterId == id);
    commBlocked.removeWhere((k) => k.startsWith('$id:') || k.endsWith(':$id'));
    commLastRead.removeWhere((k, v) => k.startsWith('$id:'));
    commAdmins.remove(id);
    sessionUserId = null;
    commitCommunity();
    return null;
  }
}

// ============================================================
// DATA PROFIL: statistik bulanan, tanggal badge, perjalanan volunteer
// ============================================================
extension ProfileData on AppState {
  List<PointEntry> _eventEntries(String uid) {
    final l = pointEntries
        .where((e) => e.userId == uid && e.verified && e.type == PointType.event)
        .toList();
    l.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return l;
  }

  int _hoursOf(PointEntry e) {
    final id = e.eventId;
    if (id == null) return 0;
    return eventById(id)?.hours ?? 0;
  }

  /// Statistik satu bulan (berdasarkan poin yang sudah diverifikasi).
  MonthStat monthStat(String uid, DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    var ev = 0, h = 0, pts = 0;
    for (final e in pointEntries) {
      if (e.userId != uid || !e.verified || e.type == PointType.opening) continue;
      if (e.createdAt.isBefore(start) || !e.createdAt.isBefore(end)) continue;
      pts += e.points;
      if (e.type == PointType.event) {
        ev++;
        h += _hoursOf(e);
      }
    }
    return MonthStat(start, ev, h, pts);
  }

  /// Statistik [months] bulan terakhir, dari yang terlama ke bulan ini.
  List<MonthStat> monthlyStats(String uid, {int months = 6}) {
    final now = DateTime.now();
    final list = <MonthStat>[];
    for (var i = months - 1; i >= 0; i--) {
      list.add(monthStat(uid, DateTime(now.year, now.month - i)));
    }
    return list;
  }

  /// Aktivitas paling awal yang tercatat (untuk memperkirakan tanggal bergabung).
  DateTime? earliestActivity(String uid) {
    DateTime? best;
    void consider(DateTime d) {
      if (best == null || d.isBefore(best!)) best = d;
    }

    for (final r in regs) {
      if (r.userId == uid) consider(r.createdAt);
    }
    for (final n in notifs) {
      if (n.userId == uid) consider(n.createdAt);
    }
    for (final e in pointEntries) {
      if (e.userId == uid && e.type != PointType.opening) consider(e.createdAt);
    }
    return best;
  }

  /// Status badge + tanggal diperoleh (dihitung dari riwayat poin).
  BadgeStatus badgeStatus(String uid, AchBadge b) {
    if (!achEarned(uid, b)) return const BadgeStatus(false, null);
    final u = userById(uid);
    final past = u?.pastEvents ?? 0;
    DateTime? d;

    switch (b.metric) {
      case AchMetric.started:
        for (final r in regs) {
          if (r.userId == uid && (d == null || r.createdAt.isBefore(d))) d = r.createdAt;
        }
        break;
      case AchMetric.events:
        final evAll = _eventEntries(uid);
        final need = b.target - past;
        if (need > 0 && need <= evAll.length) d = evAll[need - 1].createdAt;
        break;
      case AchMetric.lingkungan:
      case AchMetric.edukasi:
        final cat = b.metric == AchMetric.lingkungan ? 'Lingkungan' : 'Edukasi';
        final evCat = _eventEntries(uid).where((e) => e.category == cat).toList();
        if (b.target <= evCat.length) d = evCat[b.target - 1].createdAt;
        break;
      case AchMetric.points:
        final all = pointEntries.where((e) => e.userId == uid && e.verified).toList();
        all.sort((a, c) => a.createdAt.compareTo(c.createdAt));
        var cum = 0;
        for (final e in all) {
          cum += e.points;
          if (cum >= b.target) {
            if (e.type != PointType.opening) d = e.createdAt;
            break;
          }
        }
        break;
    }
    return BadgeStatus(true, d);
  }

  /// Linimasa perjalanan volunteer (dari awal bergabung sampai sekarang).
  List<JourneyItem> journeyOf(String uid, DateTime joined) {
    final u = userById(uid);
    final items = <JourneyItem>[];
    const red = Color(0xFFDC2626);

    items.add(JourneyItem(joined, Icons.flag_rounded, red, 'Bergabung di Volunteer',
        'Awal perjalananmu sebagai relawan'));

    if (u != null && u.pastEvents > 0) {
      items.add(JourneyItem(joined, Icons.history, const Color(0xFF64748B), 'Riwayat sebelum pencatatan',
          '${u.pastEvents} kegiatan dan ${fmtNum(u.pastPoints)} poin tercatat sebagai riwayat awal'));
    }

    final ev = _eventEntries(uid);
    if (ev.isNotEmpty) {
      items.add(JourneyItem(ev.first.createdAt, Icons.event_available, const Color(0xFF2563EB),
          'Event pertama di aplikasi', ev.first.title));
    }

    for (final b in kAchBadges) {
      final st = badgeStatus(uid, b);
      if (st.earned) {
        items.add(JourneyItem(st.date ?? joined, b.icon, b.color, 'Badge ${b.name}', b.desc));
      }
    }

    final all = pointEntries.where((e) => e.userId == uid && e.verified).toList();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    var cum = 0;
    var lvl = 0;
    for (final e in all) {
      cum += e.points;
      final li = levelIndexOf(cum);
      while (lvl < li) {
        lvl++;
        if (e.type != PointType.opening) {
          items.add(JourneyItem(e.createdAt, kLevels[lvl].icon, kLevels[lvl].color,
              'Naik ke level ${kLevels[lvl].name}', 'Total ${fmtNum(cum)} poin'));
        }
      }
    }

    final recent = ev.length > 6 ? ev.sublist(ev.length - 6) : ev;
    for (final e in recent) {
      items.add(JourneyItem(e.createdAt, Icons.volunteer_activism, red, e.title,
          '+${e.points} poin • ${_hoursOf(e)} jam kontribusi'));
    }

    final indexed = items.asMap().entries.toList();
    indexed.sort((a, b) {
      final c = a.value.date.compareTo(b.value.date);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }
}
