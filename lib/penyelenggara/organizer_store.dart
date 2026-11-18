import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/leaderboard_seed.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

const kStatusLabel = {
  'draft': 'Draft',
  'published': 'Published',
  'ongoing': 'Ongoing',
  'completed': 'Completed',
  'cancelled': 'Cancelled',
  'archived': 'Diarsipkan',
};
const kRegLabel = {
  'pending': 'Pending',
  'accepted': 'Accepted',
  'rejected': 'Rejected',
  'completed': 'Completed',
  'cancelled': 'Dibatalkan',
};

DateTime? _dt(dynamic v) => (v == null || v == '') ? null : DateTime.tryParse(v as String);

class EventMeta {
  String ownerId, status, requirements, contact;
  DateTime? deadline;
  bool requireApproval;
  EventMeta({
    required this.ownerId,
    this.status = 'published',
    this.deadline,
    this.requirements = '',
    this.contact = '',
    this.requireApproval = false,
  });
  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'status': status,
        'deadline': deadline?.toIso8601String() ?? '',
        'requirements': requirements,
        'contact': contact,
        'requireApproval': requireApproval,
      };
  factory EventMeta.fromJson(Map<String, dynamic> j) => EventMeta(
        ownerId: j['ownerId'] as String,
        status: (j['status'] ?? 'published') as String,
        deadline: _dt(j['deadline']),
        requirements: (j['requirements'] ?? '') as String,
        contact: (j['contact'] ?? '') as String,
        requireApproval: (j['requireApproval'] ?? false) as bool,
      );
}

class OrgCert {
  final String id, regId, userId, eventId, number;
  final DateTime issuedAt;
  OrgCert(this.id, this.regId, this.userId, this.eventId, this.number, this.issuedAt);
  Map<String, dynamic> toJson() => {
        'id': id, 'regId': regId, 'userId': userId, 'eventId': eventId,
        'number': number, 'issuedAt': issuedAt.toIso8601String(),
      };
  factory OrgCert.fromJson(Map<String, dynamic> j) => OrgCert(j['id'] as String, j['regId'] as String,
      j['userId'] as String, j['eventId'] as String, j['number'] as String, DateTime.parse(j['issuedAt'] as String));
}

class OrgMessage {
  final String id, ownerId, kind, title, body;
  final String? eventId;
  final int count;
  final DateTime createdAt;
  OrgMessage(this.id, this.ownerId, this.kind, this.title, this.body, this.eventId, this.count, this.createdAt);
  Map<String, dynamic> toJson() => {
        'id': id, 'ownerId': ownerId, 'kind': kind, 'title': title, 'body': body,
        'eventId': eventId, 'count': count, 'createdAt': createdAt.toIso8601String(),
      };
  factory OrgMessage.fromJson(Map<String, dynamic> j) => OrgMessage(
      j['id'] as String, j['ownerId'] as String, j['kind'] as String, j['title'] as String, j['body'] as String,
      j['eventId'] as String?, (j['count'] as num).toInt(), DateTime.parse(j['createdAt'] as String));
}

class OrgProfile {
  String name, desc, category, address, email, phone, social, pic, pj;
  OrgProfile({
    this.name = '', this.desc = '', this.category = 'Sosial', this.address = '',
    this.email = '', this.phone = '', this.social = '', this.pic = '', this.pj = '',
  });
  Map<String, dynamic> toJson() => {
        'name': name, 'desc': desc, 'category': category, 'address': address,
        'email': email, 'phone': phone, 'social': social, 'pic': pic, 'pj': pj,
      };
  factory OrgProfile.fromJson(Map<String, dynamic> j) => OrgProfile(
        name: (j['name'] ?? '') as String, desc: (j['desc'] ?? '') as String,
        category: (j['category'] ?? 'Sosial') as String, address: (j['address'] ?? '') as String,
        email: (j['email'] ?? '') as String, phone: (j['phone'] ?? '') as String,
        social: (j['social'] ?? '') as String, pic: (j['pic'] ?? '') as String, pj: (j['pj'] ?? '') as String,
      );
}

Map<String, dynamic> eventToJson(EventModel e) => {
      'id': e.id, 'title': e.title, 'category': e.category, 'organizer': e.organizer,
      'location': e.location, 'description': e.description, 'image': e.image, 'time': e.time,
      'date': e.date.toIso8601String(), 'quota': e.quota, 'baseParticipants': e.baseParticipants,
      'points': e.points, 'hours': e.hours, 'impact': e.impact, 'tasks': e.tasks, 'price': e.price,
    };

EventModel eventFromJson(Map<String, dynamic> j) => EventModel(
      id: j['id'] as String, title: j['title'] as String, category: j['category'] as String,
      organizer: j['organizer'] as String, location: j['location'] as String,
      description: j['description'] as String, image: (j['image'] ?? '') as String,
      time: j['time'] as String, date: DateTime.parse(j['date'] as String),
      quota: (j['quota'] as num).toInt(), baseParticipants: (j['baseParticipants'] as num).toInt(),
      points: (j['points'] as num).toInt(), hours: (j['hours'] as num).toInt(),
      impact: (j['impact'] as num).toInt(), tasks: List<String>.from(j['tasks'] as List),
      price: ((j['price'] ?? 0) as num).toInt(),
    );

/// Data & aksi penyelenggara. Tersimpan lokal (shared_preferences), sama seperti
/// sisa aplikasi. Bila nanti memakai backend, ganti isi method ini dengan
/// pemanggilan API tanpa mengubah halaman UI.
class OrgStore extends ChangeNotifier {
  OrgStore._();
  static final OrgStore instance = OrgStore._();

  final Map<String, EventMeta> meta = {};
  final Map<String, EventModel> custom = {};
  final Set<String> deleted = {};
  final Map<String, String> approvals = {}, checkIns = {}, checkOuts = {};
  final List<OrgCert> certs = [];
  final List<OrgMessage> messages = [];
  final Map<String, OrgProfile> profiles = {};
  bool notifNewReg = true, defaultApproval = true, seeded = false, _loaded = false;
  int _n = 0;

  String newId(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}_${_n++}';

  // ------------------------------------------------------------- persistence
  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final raw = (await SharedPreferences.getInstance()).getString('org_data');
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    Map<String, dynamic> m(String k) => Map<String, dynamic>.from((j[k] ?? {}) as Map);
    m('meta').forEach((k, v) => meta[k] = EventMeta.fromJson(Map<String, dynamic>.from(v as Map)));
    m('custom').forEach((k, v) => custom[k] = eventFromJson(Map<String, dynamic>.from(v as Map)));
    m('profiles').forEach((k, v) => profiles[k] = OrgProfile.fromJson(Map<String, dynamic>.from(v as Map)));
    m('approvals').forEach((k, v) => approvals[k] = v as String);
    m('checkIns').forEach((k, v) => checkIns[k] = v as String);
    m('checkOuts').forEach((k, v) => checkOuts[k] = v as String);
    deleted.addAll(List<String>.from((j['deleted'] ?? []) as List));
    certs.addAll(((j['certs'] ?? []) as List).map((e) => OrgCert.fromJson(Map<String, dynamic>.from(e as Map))));
    messages.addAll(((j['messages'] ?? []) as List).map((e) => OrgMessage.fromJson(Map<String, dynamic>.from(e as Map))));
    notifNewReg = (j['notifNewReg'] ?? true) as bool;
    defaultApproval = (j['defaultApproval'] ?? true) as bool;
    seeded = (j['seeded'] ?? false) as bool;
  }

  Future<void> save() async {
    final j = {
      'meta': meta.map((k, v) => MapEntry(k, v.toJson())),
      'custom': custom.map((k, v) => MapEntry(k, eventToJson(v))),
      'profiles': profiles.map((k, v) => MapEntry(k, v.toJson())),
      'approvals': approvals, 'checkIns': checkIns, 'checkOuts': checkOuts,
      'deleted': deleted.toList(),
      'certs': certs.map((e) => e.toJson()).toList(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'notifNewReg': notifNewReg, 'defaultApproval': defaultApproval, 'seeded': seeded,
    };
    await (await SharedPreferences.getInstance()).setString('org_data', jsonEncode(j));
  }

  void _commit(AppState s) {
    s.commitCommunity(); // simpan + refresh sisi relawan
    save();
    notifyListeners();
  }

  /// Dipanggil dari AppState.init(): menerapkan event buatan penyelenggara ke
  /// daftar event relawan (supaya muncul di Cari Event) dan mengisi data contoh.
  Future<void> applyTo(AppState s) async {
    await _load();
    s.events.removeWhere((e) => deleted.contains(e.id));
    for (final e in custom.values) {
      if (meta[e.id]?.status == 'draft') continue;
      _put(s, e);
    }
    if (!seeded && _seedDemo(s)) {
      seeded = true;
      await save();
      s.commitCommunity();
    }
  }

  void _put(AppState s, EventModel e) {
    final i = s.events.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      s.events[i] = e;
    } else {
      s.events.insert(0, e);
    }
  }

  /// DATA CONTOH untuk preview. Hapus method ini bila memakai data produksi.
  bool _seedDemo(AppState s) {
    final seedUsers = s.users.where((u) => u.id.startsWith(kSeedUserPrefix)).take(6).toList();
    if (seedUsers.length < 3) return false;
    final now = DateTime.now();
    void add(int i, String ev, String st, int ago) {
      final e = s.eventById(ev);
      if (e == null) return;
      final id = 'rd_${ev}_$i';
      if (s.regs.any((r) => r.id == id)) return;
      final u = seedUsers[i % seedUsers.length];
      final reg = Registration(
          id: id, userId: u.id, eventId: ev,
          code: 'VOL${e.date.year}${e.date.month.toString().padLeft(2, '0')}${e.date.day.toString().padLeft(2, '0')}${(900 + i)}',
          createdAt: now.subtract(Duration(days: ago)));
      if (st == 'rejected') reg.status = RegStatus.cancelled;
      approvals[id] = st;
      s.regs.add(reg);
    }

    add(0, 'e1', 'pending', 1);
    add(1, 'e3', 'pending', 2);
    add(2, 'e4', 'pending', 1);
    add(3, 'e1', 'accepted', 3);
    add(4, 'e1', 'accepted', 4);
    add(5, 'e2', 'rejected', 5);
    return true;
  }

  // ------------------------------------------------------------------ events
  String ownerOf(EventModel e) => meta[e.id]?.ownerId ?? kDemoOrgId;
  EventMeta metaOf(EventModel e) =>
      meta[e.id] ?? EventMeta(ownerId: kDemoOrgId, status: 'published', requireApproval: false);

  List<EventModel> myEvents(AppState s, String uid) {
    final m = <String, EventModel>{};
    for (final e in s.events) {
      if (ownerOf(e) == uid) m[e.id] = e;
    }
    for (final e in custom.values) {
      if (ownerOf(e) == uid) m[e.id] = e;
    }
    final l = m.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  String statusOf(EventModel e) {
    final st = metaOf(e).status;
    if (st != 'published') return st;
    final n = DateTime.now();
    if (e.isFinished) return 'completed';
    if (e.date.year == n.year && e.date.month == n.month && e.date.day == n.day) return 'ongoing';
    return 'published';
  }

  List<Registration> activeRegsOf(AppState s, String eventId) =>
      s.regs.where((r) => r.eventId == eventId && r.status != RegStatus.cancelled).toList();

  void _push(AppState s, String userId, String title, String body, String kind) {
    s.notifs.insert(0, Notif(id: s.newId('n'), userId: userId, title: title, body: body, kind: kind, createdAt: DateTime.now()));
  }

  /// Simpan event. publish=false -> draft (tidak tampil di aplikasi relawan).
  void saveEvent(AppState s, EventModel e, EventMeta m, {required bool publish}) {
    final existed = s.events.any((x) => x.id == e.id);
    m.status = publish ? 'published' : (m.status == 'published' && existed ? 'published' : 'draft');
    meta[e.id] = m;
    custom[e.id] = e;
    if (m.status == 'draft') {
      s.events.removeWhere((x) => x.id == e.id);
    } else {
      _put(s, e);
      if (existed) {
        for (final r in activeRegsOf(s, e.id)) {
          _push(s, r.userId, 'Informasi event diperbarui', 'Penyelenggara memperbarui detail "${e.title}". Cek jadwal & lokasi terbaru.', 'info');
        }
      }
    }
    _commit(s);
  }

  /// Hapus permanen. Hanya boleh bila belum ada relawan aktif.
  String? deleteEvent(AppState s, EventModel e) {
    if (activeRegsOf(s, e.id).isNotEmpty) return 'Event sudah punya pendaftar. Batalkan event agar relawan mendapat notifikasi.';
    custom.remove(e.id);
    meta.remove(e.id);
    deleted.add(e.id);
    s.events.removeWhere((x) => x.id == e.id);
    _commit(s);
    return null;
  }

  void cancelEvent(AppState s, EventModel e) {
    final m = metaOf(e)..status = 'cancelled';
    meta[e.id] = m;
    final c = EventModel(
      id: e.id, title: e.title.startsWith('[Dibatalkan]') ? e.title : '[Dibatalkan] ${e.title}',
      category: e.category, organizer: e.organizer, location: e.location, description: e.description,
      image: e.image, time: e.time, date: e.date, quota: e.baseParticipants, baseParticipants: e.baseParticipants,
      points: e.points, hours: e.hours, impact: e.impact, tasks: e.tasks, price: e.price,
    );
    custom[e.id] = c;
    _put(s, c);
    for (final r in s.regs.where((r) => r.eventId == e.id && r.status == RegStatus.registered)) {
      r.status = RegStatus.cancelled;
      _push(s, r.userId, 'Event dibatalkan', 'Mohon maaf, "${e.title}" dibatalkan oleh penyelenggara.', 'cancel');
    }
    _commit(s);
  }

  String? setArchived(AppState s, EventModel e, bool archive) {
    final st = statusOf(e);
    if (archive && st != 'completed' && st != 'cancelled') return 'Hanya event selesai/dibatalkan yang dapat diarsipkan';
    final m = metaOf(e);
    meta[e.id] = m..status = archive ? 'archived' : (e.title.startsWith('[Dibatalkan]') ? 'cancelled' : 'published');
    _commit(s);
    return null;
  }

  // ----------------------------------------------------------- registrations
  String regState(AppState s, Registration r) {
    if (approvals[r.id] == 'rejected') return 'rejected';
    if (r.status == RegStatus.cancelled) return 'cancelled';
    if (r.status == RegStatus.attended) return 'completed';
    final a = approvals[r.id];
    if (a != null) return a;
    final e = s.eventById(r.eventId);
    return (e != null && metaOf(e).requireApproval) ? 'pending' : 'accepted';
  }

  List<Registration> regsFor(AppState s, Iterable<String> eventIds) {
    final ids = eventIds.toSet();
    final l = s.regs.where((r) => ids.contains(r.eventId)).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  void decide(AppState s, Registration r, bool accept) {
    final e = s.eventById(r.eventId);
    approvals[r.id] = accept ? 'accepted' : 'rejected';
    if (!accept && r.status == RegStatus.registered) r.status = RegStatus.cancelled;
    _push(
        s, r.userId,
        accept ? 'Pendaftaran diterima' : 'Pendaftaran ditolak',
        accept
            ? 'Selamat! Pendaftaranmu di ${e?.title ?? 'kegiatan'} diterima. Tunjukkan QR saat hadir.'
            : 'Maaf, pendaftaranmu di ${e?.title ?? 'kegiatan'} belum dapat diterima.',
        accept ? 'register' : 'cancel');
    _commit(s);
  }

  // -------------------------------------------------------------- attendance
  String? checkIn(AppState s, String regId) {
    final r = s.regs.where((x) => x.id == regId).toList();
    if (r.isEmpty) return 'Pendaftaran tidak ditemukan';
    if (regState(s, r.first) == 'pending') return 'Pendaftaran belum diterima';
    final err = s.orgCheckIn(regId);
    if (err != null) return err;
    checkIns[regId] = DateTime.now().toIso8601String();
    _commit(s);
    return null;
  }

  String? checkInByCode(AppState s, String code, Set<String> eventIds) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return 'Masukkan kode relawan';
    for (final r in s.regs) {
      if (eventIds.contains(r.eventId) && r.code.toUpperCase() == c) return checkIn(s, r.id);
    }
    return 'Kode tidak ditemukan pada event ini';
  }

  String? checkOut(AppState s, String regId) {
    if (!checkIns.containsKey(regId)) return 'Relawan belum check-in';
    checkOuts[regId] = DateTime.now().toIso8601String();
    _commit(s);
    return null;
  }

  // ------------------------------------------------------------ certificates
  bool eligible(Registration r) =>
      r.status == RegStatus.attended && (!checkIns.containsKey(r.id) || checkOuts.containsKey(r.id));

  OrgCert? certOf(String regId) {
    for (final c in certs) {
      if (c.regId == regId) return c;
    }
    return null;
  }

  String? issueCertificate(AppState s, Registration r) {
    if (!eligible(r)) return 'Belum memenuhi ketentuan kehadiran (check-in & check-out)';
    if (certOf(r.id) != null) return 'Sertifikat sudah diterbitkan';
    final e = s.eventById(r.eventId);
    final n = DateTime.now();
    certs.add(OrgCert(newId('c'), r.id, r.userId, r.eventId,
        'VOL/CERT/${n.year}/${(certs.length + 1).toString().padLeft(4, '0')}', n));
    _push(s, r.userId, 'Sertifikat tersedia', 'Sertifikat ${e?.title ?? 'kegiatan'} sudah diterbitkan. Cek di Riwayat.', 'attend');
    _commit(s);
    return null;
  }

  // ----------------------------------------------------------------- messages
  int send(AppState s, {required String ownerId, required String kind, required String title, required String body, String? eventId}) {
    final ids = <String>{};
    if (eventId == null) {
      for (final u in s.users) {
        if (u.role != kOrgRole && !u.id.startsWith(kSeedUserPrefix)) ids.add(u.id);
      }
    } else {
      for (final r in activeRegsOf(s, eventId)) {
        ids.add(r.userId);
      }
    }
    for (final id in ids) {
      _push(s, id, title, body, 'info');
    }
    messages.insert(0, OrgMessage(newId('m'), ownerId, kind, title, body, eventId, ids.length, DateTime.now()));
    _commit(s);
    return ids.length;
  }

  // ------------------------------------------------------------------ profile
  OrgProfile profileOf(AppUser u) =>
      profiles.putIfAbsent(u.id, () => OrgProfile(name: u.name, email: u.email, phone: u.phone, address: u.city, pj: u.name));

  void saveProfile(AppState s, AppUser u, OrgProfile p) {
    profiles[u.id] = p;
    u.name = p.name.trim().isEmpty ? u.name : p.name.trim();
    _commit(s);
  }

  void setFlags({bool? newReg, bool? approval}) {
    if (newReg != null) notifNewReg = newReg;
    if (approval != null) defaultApproval = approval;
    save();
    notifyListeners();
  }
}
