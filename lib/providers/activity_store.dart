import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'app_state.dart';

// ============================================================
// WARNA & GAYA HALAMAN AKTIVITAS SAYA
// ============================================================
const Color kActRed = Color(0xFFE92323);
const Color kActPink = Color(0xFFFFF1F1);

ButtonStyle actFilledStyle({EdgeInsetsGeometry? padding}) => ElevatedButton.styleFrom(
      backgroundColor: kActRed,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const StadiumBorder(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );

ButtonStyle actOutlineStyle({EdgeInsetsGeometry? padding}) => OutlinedButton.styleFrom(
      foregroundColor: kActRed,
      side: const BorderSide(color: kActRed),
      shape: const StadiumBorder(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
    );

// ============================================================
// MODEL
// ============================================================
class CoordRequest {
  final String id, eventId, reason, experience;
  final DateTime createdAt;
  String status; // pending | approved | rejected
  DateTime? decidedAt;
  CoordRequest({
    required this.id,
    required this.eventId,
    required this.reason,
    required this.experience,
    required this.createdAt,
    this.status = 'pending',
    this.decidedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'eventId': eventId, 'reason': reason, 'experience': experience,
        'createdAt': createdAt.toIso8601String(), 'status': status,
        'decidedAt': decidedAt?.toIso8601String(),
      };

  factory CoordRequest.fromJson(Map<String, dynamic> j) => CoordRequest(
        id: j['id'] as String,
        eventId: j['eventId'] as String,
        reason: (j['reason'] ?? '') as String,
        experience: (j['experience'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: (j['status'] ?? 'pending') as String,
        decidedAt: j['decidedAt'] == null ? null : DateTime.parse(j['decidedAt'] as String),
      );
}

class EvalRecord {
  final String eventId, comment, suggestion;
  final int rating, organizer, coordination;
  final DateTime createdAt;
  const EvalRecord({
    required this.eventId,
    required this.rating,
    required this.organizer,
    required this.coordination,
    required this.comment,
    required this.suggestion,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId, 'rating': rating, 'organizer': organizer, 'coordination': coordination,
        'comment': comment, 'suggestion': suggestion, 'createdAt': createdAt.toIso8601String(),
      };

  factory EvalRecord.fromJson(Map<String, dynamic> j) => EvalRecord(
        eventId: j['eventId'] as String,
        rating: (j['rating'] as num).toInt(),
        organizer: (j['organizer'] as num).toInt(),
        coordination: (j['coordination'] as num).toInt(),
        comment: (j['comment'] ?? '') as String,
        suggestion: (j['suggestion'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class ExperienceNote {
  final String id, eventId, experience, learned, contribution;
  final DateTime createdAt, updatedAt;
  const ExperienceNote({
    required this.id,
    required this.eventId,
    required this.experience,
    required this.learned,
    required this.contribution,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'eventId': eventId, 'experience': experience, 'learned': learned,
        'contribution': contribution, 'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ExperienceNote.fromJson(Map<String, dynamic> j) => ExperienceNote(
        id: j['id'] as String,
        eventId: j['eventId'] as String,
        experience: (j['experience'] ?? '') as String,
        learned: (j['learned'] ?? '') as String,
        contribution: (j['contribution'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class Complaint {
  final String id, eventId, category, description;
  final DateTime createdAt;
  String status; // sent | processing | done
  Complaint({
    required this.id,
    required this.eventId,
    required this.category,
    required this.description,
    required this.createdAt,
    this.status = 'sent',
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'eventId': eventId, 'category': category, 'description': description,
        'createdAt': createdAt.toIso8601String(), 'status': status,
      };

  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
        id: j['id'] as String,
        eventId: (j['eventId'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: (j['status'] ?? 'sent') as String,
      );
}

class Appreciation {
  final String id, fromId, fromName, toId, toName, type, message;
  final DateTime createdAt;
  const Appreciation({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'fromId': fromId, 'fromName': fromName, 'toId': toId, 'toName': toName,
        'type': type, 'message': message, 'createdAt': createdAt.toIso8601String(),
      };

  factory Appreciation.fromJson(Map<String, dynamic> j) => Appreciation(
        id: j['id'] as String,
        fromId: (j['fromId'] ?? '') as String,
        fromName: (j['fromName'] ?? '') as String,
        toId: (j['toId'] ?? '') as String,
        toName: (j['toName'] ?? '') as String,
        type: (j['type'] ?? 'thanks') as String,
        message: (j['message'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class AttendanceRecord {
  final String regId;
  final DateTime checkIn, checkOut, verifiedAt;
  const AttendanceRecord({
    required this.regId,
    required this.checkIn,
    required this.checkOut,
    required this.verifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'regId': regId, 'checkIn': checkIn.toIso8601String(), 'checkOut': checkOut.toIso8601String(),
        'verifiedAt': verifiedAt.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        regId: j['regId'] as String,
        checkIn: DateTime.parse(j['checkIn'] as String),
        checkOut: DateTime.parse(j['checkOut'] as String),
        verifiedAt: DateTime.parse(j['verifiedAt'] as String),
      );
}

class ApprType {
  final String id, label;
  final IconData icon;
  const ApprType(this.id, this.label, this.icon);
}

const List<ApprType> kApprTypes = [
  ApprType('thanks', 'Terima Kasih', Icons.favorite),
  ApprType('hard', 'Kerja Keras', Icons.fitness_center),
  ApprType('inspire', 'Inspiratif', Icons.lightbulb),
  ApprType('team', 'Tim Solid', Icons.groups),
  ApprType('kind', 'Ramah & Peduli', Icons.sentiment_satisfied_alt),
];

ApprType apprTypeOf(String id) {
  for (final t in kApprTypes) {
    if (t.id == id) return t;
  }
  return kApprTypes.first;
}

const List<String> kComplaintCategories = [
  'Keselamatan',
  'Koordinasi panitia',
  'Fasilitas & perlengkapan',
  'Jadwal & waktu',
  'Konsumsi',
  'Lainnya',
];

class EventWindow {
  final DateTime start, end;
  const EventWindow(this.start, this.end);
}

class AttendanceInfo {
  final DateTime date;
  final DateTime? checkIn, checkOut, verifiedAt;
  final Duration? duration;
  final String status; // Hadir | Tidak Hadir | Menunggu Verifikasi
  final String verification;
  const AttendanceInfo({
    required this.date,
    required this.status,
    required this.verification,
    this.checkIn,
    this.checkOut,
    this.duration,
    this.verifiedAt,
  });
}

// ============================================================
// ACTIVITY STORE (penyimpanan lokal, per akun)
// ============================================================
class ActivityStore extends ChangeNotifier {
  SharedPreferences? _p;
  final Map<String, Map<String, dynamic>> _users = {};
  List<Appreciation> _apps = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _p = p;
    final raw = p.getString('act_apps');
    if (raw == null) {
      _seedAppreciations();
    } else {
      try {
        _apps = (jsonDecode(raw) as List)
            .map((e) => Appreciation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        _apps = [];
      }
    }
    notifyListeners();
  }

  /// Contoh apresiasi awal untuk akun demo agar halaman tidak kosong.
  void _seedAppreciations() {
    final now = DateTime.now();
    _apps = [
      Appreciation(
        id: 'ap_seed_1',
        fromId: 'u_seed_2',
        fromName: 'Siti Rahmawati',
        toId: 'u_demo',
        toName: 'Kamu',
        type: 'thanks',
        message: 'Terima kasih sudah membantu di lapangan, semangatmu menular!',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Appreciation(
        id: 'ap_seed_2',
        fromId: 'u_seed_3',
        fromName: 'Budi Santoso',
        toId: 'u_demo',
        toName: 'Kamu',
        type: 'team',
        message: 'Kerja sama timnya luar biasa. Sampai ketemu di kegiatan berikutnya!',
        createdAt: now.subtract(const Duration(days: 9)),
      ),
    ];
    _saveApps();
  }

  void _saveApps() {
    _p?.setString('act_apps', jsonEncode(_apps.map((e) => e.toJson()).toList()));
  }

  // ---- penyimpanan per akun ----
  Map<String, dynamic> _u(String id) {
    final cached = _users[id];
    if (cached != null) return cached;
    Map<String, dynamic> m = {};
    final raw = _p?.getString('act_user_$id');
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

  void _write(String id) => _p?.setString('act_user_$id', jsonEncode(_u(id)));

  void _save(String id) {
    _write(id);
    notifyListeners();
  }

  List<Map<String, dynamic>> _list(String uid, String key) {
    final raw = (_u(uid)[key] as List?) ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _newId(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}';

  /// Dipakai sinkronisasi backend: muat ulang data akun dari penyimpanan.
  void reloadUser(String id) {
    _users.remove(id);
    notifyListeners();
  }

  /// Menghapus seluruh data aktivitas akun (dipakai saat akun dihapus).
  void clearUser(String id) {
    _users.remove(id);
    _p?.remove('act_user_$id');
    _apps.removeWhere((a) => a.fromId == id || a.toId == id);
    _saveApps();
    notifyListeners();
  }

  // ------------------------------------------------ koordinator
  List<CoordRequest> requests(String uid) {
    final l = _list(uid, 'requests').map(CoordRequest.fromJson).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  String? submitRequest(String uid, {required String eventId, required String reason, required String experience}) {
    if (eventId.isEmpty) return 'Pilih event yang ingin kamu koordinasikan';
    if (reason.trim().length < 15) return 'Alasan pengajuan minimal 15 karakter';
    if (experience.trim().length < 10) return 'Pengalaman relawan minimal 10 karakter';
    if (requests(uid).any((r) => r.eventId == eventId && r.status != 'rejected')) {
      return 'Kamu sudah mengajukan diri untuk event ini';
    }
    final l = _list(uid, 'requests');
    l.add(CoordRequest(
      id: _newId('cr'),
      eventId: eventId,
      reason: reason.trim(),
      experience: experience.trim(),
      createdAt: DateTime.now(),
    ).toJson());
    _u(uid)['requests'] = l;
    _save(uid);
    return null;
  }

  void decideRequest(String uid, String id, bool approve) {
    final l = _list(uid, 'requests');
    for (final m in l) {
      if (m['id'] == id && m['status'] == 'pending') {
        m['status'] = approve ? 'approved' : 'rejected';
        m['decidedAt'] = DateTime.now().toIso8601String();
      }
    }
    _u(uid)['requests'] = l;
    _save(uid);
  }

  bool isCoordinator(String uid, String eventId) =>
      requests(uid).any((r) => r.eventId == eventId && r.status == 'approved');

  bool hasCoordinatorStatus(String uid) => requests(uid).any((r) => r.status == 'approved');

  // ------------------------------------------------ evaluasi
  List<EvalRecord> evals(String uid) => _list(uid, 'evals').map(EvalRecord.fromJson).toList();

  EvalRecord? evalOf(String uid, String eventId) {
    for (final e in evals(uid)) {
      if (e.eventId == eventId) return e;
    }
    return null;
  }

  String? saveEval(String uid, EvalRecord e) {
    if (e.rating < 1 || e.organizer < 1 || e.coordination < 1) {
      return 'Beri rating bintang (1-5) untuk semua penilaian';
    }
    final l = _list(uid, 'evals')..removeWhere((m) => m['eventId'] == e.eventId);
    l.add(e.toJson());
    _u(uid)['evals'] = l;
    _save(uid);
    return null;
  }

  // ------------------------------------------------ catatan pengalaman
  List<ExperienceNote> notes(String uid) {
    final l = _list(uid, 'notes').map(ExperienceNote.fromJson).toList();
    l.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return l;
  }

  String? saveNote(String uid,
      {String? id, required String eventId, required String experience, String learned = '', String contribution = ''}) {
    if (eventId.isEmpty) return 'Pilih kegiatan terlebih dahulu';
    if (experience.trim().length < 10) return 'Tulis pengalamanmu minimal 10 karakter';
    final l = _list(uid, 'notes');
    final now = DateTime.now();
    if (id != null) {
      var found = false;
      for (var i = 0; i < l.length; i++) {
        if (l[i]['id'] == id) {
          final old = ExperienceNote.fromJson(l[i]);
          l[i] = ExperienceNote(
            id: id,
            eventId: eventId,
            experience: experience.trim(),
            learned: learned.trim(),
            contribution: contribution.trim(),
            createdAt: old.createdAt,
            updatedAt: now,
          ).toJson();
          found = true;
        }
      }
      if (!found) return 'Catatan tidak ditemukan';
    } else {
      l.add(ExperienceNote(
        id: _newId('nt'),
        eventId: eventId,
        experience: experience.trim(),
        learned: learned.trim(),
        contribution: contribution.trim(),
        createdAt: now,
        updatedAt: now,
      ).toJson());
    }
    _u(uid)['notes'] = l;
    _save(uid);
    return null;
  }

  void deleteNote(String uid, String id) {
    final l = _list(uid, 'notes')..removeWhere((m) => m['id'] == id);
    _u(uid)['notes'] = l;
    _save(uid);
  }

  // ------------------------------------------------ pengingat
  bool remindOn(String uid, String key) => (_u(uid)['r_$key'] as bool?) ?? true;

  void setRemind(String uid, String key, bool v) {
    _u(uid)['r_$key'] = v;
    _save(uid);
  }

  bool remindEvent(String uid, String regId) {
    final off = _u(uid)['offRegs'];
    return !(off is List && off.contains(regId));
  }

  void setRemindEvent(String uid, String regId, bool on) {
    final off = List<String>.from((_u(uid)['offRegs'] as List?) ?? const []);
    off.remove(regId);
    if (!on) off.add(regId);
    _u(uid)['offRegs'] = off;
    _save(uid);
  }

  bool pushed(String uid, String key) {
    final l = _u(uid)['pushed'];
    return l is List && l.contains(key);
  }

  void markPushed(String uid, String key) {
    final l = List<String>.from((_u(uid)['pushed'] as List?) ?? const []);
    if (!l.contains(key)) l.add(key);
    _u(uid)['pushed'] = l;
    _write(uid); // tanpa notifyListeners (dipanggil saat build)
  }

  // ------------------------------------------------ kehadiran
  AttendanceRecord? attendance(String uid, String regId) {
    for (final m in _list(uid, 'attendance')) {
      if (m['regId'] == regId) return AttendanceRecord.fromJson(m);
    }
    return null;
  }

  void recordAttendance(String uid, AttendanceRecord r) {
    final l = _list(uid, 'attendance')..removeWhere((m) => m['regId'] == r.regId);
    l.add(r.toJson());
    _u(uid)['attendance'] = l;
    _save(uid);
  }

  // ------------------------------------------------ pengaduan
  List<Complaint> complaints(String uid) {
    final l = _list(uid, 'complaints').map(Complaint.fromJson).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  String? addComplaint(String uid, {required String eventId, required String category, required String description}) {
    if (category.isEmpty) return 'Pilih kategori masalah';
    if (description.trim().length < 15) return 'Deskripsi kendala minimal 15 karakter';
    final l = _list(uid, 'complaints');
    l.add(Complaint(
      id: _newId('cp'),
      eventId: eventId,
      category: category,
      description: description.trim(),
      createdAt: DateTime.now(),
    ).toJson());
    _u(uid)['complaints'] = l;
    _save(uid);
    return null;
  }

  /// Simulasi tindak lanjut admin: Terkirim -> Diproses -> Selesai.
  void advanceComplaint(String uid, String id) {
    final l = _list(uid, 'complaints');
    for (final m in l) {
      if (m['id'] == id) {
        if (m['status'] == 'sent') {
          m['status'] = 'processing';
        } else if (m['status'] == 'processing') {
          m['status'] = 'done';
        }
      }
    }
    _u(uid)['complaints'] = l;
    _save(uid);
  }

  // ------------------------------------------------ apresiasi relawan
  List<Appreciation> given(String uid) {
    final l = _apps.where((a) => a.fromId == uid).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  List<Appreciation> received(String uid) {
    final l = _apps.where((a) => a.toId == uid).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  String? sendAppreciation({
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
    required String type,
    required String message,
  }) {
    if (toId.isEmpty) return 'Pilih relawan yang ingin diapresiasi';
    if (toId == fromId) return 'Kamu tidak dapat mengapresiasi diri sendiri';
    if (message.trim().length < 5) return 'Tulis pesan positif minimal 5 karakter';
    final today = DateTime.now();
    final dup = _apps.any((a) =>
        a.fromId == fromId &&
        a.toId == toId &&
        a.type == type &&
        a.createdAt.year == today.year &&
        a.createdAt.month == today.month &&
        a.createdAt.day == today.day);
    if (dup) return 'Kamu sudah mengirim apresiasi yang sama kepada relawan ini hari ini';
    _apps.add(Appreciation(
      id: _newId('ap'),
      fromId: fromId,
      fromName: fromName,
      toId: toId,
      toName: toName,
      type: type,
      message: message.trim(),
      createdAt: DateTime.now(),
    ));
    _saveApps();
    notifyListeners();
    return null;
  }
}

// ============================================================
// DATA TURUNAN DARI APPSTATE: jadwal event, kehadiran, pengingat
// ============================================================
extension ActivityData on AppState {
  /// Jadwal mulai & selesai event (dibaca dari teks jam, mis. "08.00 - 12.00 WIB").
  EventWindow eventWindow(EventModel e) {
    final m = RegExp(r'(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})').firstMatch(e.time);
    var sh = 8, sm = 0, eh = 12, em = 0;
    if (m != null) {
      sh = int.parse(m.group(1)!);
      sm = int.parse(m.group(2)!);
      eh = int.parse(m.group(3)!);
      em = int.parse(m.group(4)!);
    }
    final d = e.date;
    final start = DateTime(d.year, d.month, d.day, sh, sm);
    var end = DateTime(d.year, d.month, d.day, eh, em);
    if (!end.isAfter(start)) end = start.add(Duration(hours: e.hours > 0 ? e.hours : 3));
    return EventWindow(start, end);
  }

  bool eventOngoing(EventModel e) {
    final w = eventWindow(e);
    final n = DateTime.now();
    return !n.isBefore(w.start) && n.isBefore(w.end);
  }

  /// Persentase waktu kegiatan yang sudah berjalan (0.0 - 1.0).
  double eventProgress(EventModel e) {
    final w = eventWindow(e);
    final total = w.end.difference(w.start).inSeconds;
    if (total <= 0) return 0;
    final done = DateTime.now().difference(w.start).inSeconds;
    return (done / total).clamp(0.0, 1.0).toDouble();
  }

  String startsInText(EventModel e) {
    final w = eventWindow(e);
    final left = w.start.difference(DateTime.now());
    if (left.isNegative) return 'Event sudah dimulai';
    if (left.inDays >= 1) return 'Event akan dimulai dalam ${left.inDays} hari';
    if (left.inHours >= 1) return 'Event akan dimulai dalam ${left.inHours} jam';
    return 'Event akan dimulai dalam ${left.inMinutes < 1 ? 1 : left.inMinutes} menit';
  }

  String remainingText(EventModel e) {
    final w = eventWindow(e);
    final left = w.end.difference(DateTime.now());
    if (left.isNegative) return 'Kegiatan telah berakhir';
    if (left.inHours >= 1) return 'Sisa Waktu: ${left.inHours} Jam ${left.inMinutes % 60} Menit';
    return 'Sisa Waktu: ${left.inMinutes} Menit';
  }

  /// Rincian kehadiran satu pendaftaran.
  AttendanceInfo attendanceInfo(ActivityStore st, Registration r, EventModel e) {
    final w = eventWindow(e);
    if (r.status == RegStatus.attended) {
      final rec = st.attendance(r.userId, r.id);
      final ci = rec?.checkIn ?? w.start;
      final co = rec?.checkOut ?? w.end;
      return AttendanceInfo(
        date: ci,
        checkIn: ci,
        checkOut: co,
        duration: co.difference(ci),
        verifiedAt: rec?.verifiedAt,
        status: 'Hadir',
        verification: 'Terverifikasi oleh panitia',
      );
    }
    if (r.status == RegStatus.cancelled) {
      return AttendanceInfo(date: w.start, status: 'Tidak Hadir', verification: 'Pendaftaran dibatalkan');
    }
    if (e.isFinished) {
      return AttendanceInfo(date: w.start, status: 'Tidak Hadir', verification: 'Kehadiran tidak terverifikasi');
    }
    return AttendanceInfo(date: w.start, status: 'Menunggu Verifikasi', verification: 'Menunggu verifikasi panitia');
  }

  /// Poin yang sudah diperoleh dari satu event.
  int pointsFromEvent(String uid, String eventId) {
    var t = 0;
    for (final p in pointEntries) {
      if (p.userId == uid && p.verified && p.eventId == eventId) t += p.points;
    }
    return t;
  }

  /// Jumlah pendaftaran (tidak dibatalkan) per bulan pendaftaran, [months] bulan terakhir.
  List<int> joinedPerMonth(String uid, {int months = 6}) {
    final now = DateTime.now();
    final out = <int>[];
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      var c = 0;
      for (final r in regs) {
        if (r.userId == uid &&
            r.status != RegStatus.cancelled &&
            r.createdAt.year == m.year &&
            r.createdAt.month == m.month) {
          c++;
        }
      }
      out.add(c);
    }
    return out;
  }
}

/// Mengirim pengingat H-3, H-1, dan jam mulai untuk event yang sudah didaftarkan.
/// Aman dipanggil berulang: setiap pengingat hanya dikirim satu kali.
void runReminders(AppState s, ActivityStore st) {
  final u = s.user;
  if (u == null) return;
  final now = DateTime.now();
  var changed = false;

  void push(String key, String title, String body, bool enabled) {
    if (!enabled || st.pushed(u.id, key)) return;
    st.markPushed(u.id, key);
    s.notifs.insert(
      0,
      Notif(id: s.newId('n'), userId: u.id, title: title, body: body, kind: 'register', createdAt: now),
    );
    changed = true;
  }

  for (final r in s.regs) {
    if (r.userId != u.id || r.status != RegStatus.registered) continue;
    if (!st.remindEvent(u.id, r.id)) continue;
    final e = s.eventById(r.eventId);
    if (e == null) continue;
    final w = s.eventWindow(e);
    final left = w.start.difference(now);
    if (left.isNegative) continue;
    final hhmm = '${w.start.hour.toString().padLeft(2, '0')}.${w.start.minute.toString().padLeft(2, '0')}';
    if (left.inHours <= 72) {
      push('${r.id}:h3', 'Pengingat H-3', '${e.title} akan dimulai dalam 3 hari. Siapkan dirimu!',
          st.remindOn(u.id, 'h3'));
    }
    if (left.inHours <= 24) {
      push('${r.id}:h1', 'Pengingat H-1', 'Besok ada kegiatan ${e.title} pukul $hhmm. Jangan lupa hadir!',
          st.remindOn(u.id, 'h1'));
    }
    if (left.inMinutes <= 60) {
      push('${r.id}:start', 'Kegiatan segera dimulai', '${e.title} dimulai pukul $hhmm. Siapkan tiket QR-mu.',
          st.remindOn(u.id, 'start'));
    }
  }
  if (changed) s.commitCommunity();
}