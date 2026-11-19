import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/community_seed.dart' show kDefaultAdminId;
import '../data/leaderboard_seed.dart' show kSeedUserPrefix;
import '../models/community.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import '../penyelenggara/organizer_store.dart';
import '../providers/activity_store.dart';
import '../providers/app_state.dart';
import '../providers/profile_store.dart';
import 'api_client.dart';
import 'api_config.dart';

typedef Json = Map<String, dynamic>;

/// Hasil login/registrasi lewat server.
/// handled=false  -> server tidak dapat dipakai (offline / akun tidak dikenal server);
///                   layar login memakai proses lokal bawaan.
/// handled=true   -> server sudah memutuskan; error==null berarti sukses.
class AuthOutcome {
  final bool handled;
  final String? error;
  const AuthOutcome(this.handled, this.error);
}

/// Satu "jenis data" yang disinkronkan.
class _Ad {
  final String type;
  final Map<String, Json> Function() snap; // id -> JSON milik perangkat ini yang boleh dikirim
  final bool Function(Json remote) apply; // terapkan data server; true bila ada yang berubah
  final void Function(String id)? remove; // dukungan: dihapus di server -> hapus lokal
  final bool canDelete; // kirim penghapusan lokal ke server
  final Json Function(String id, Json local)? payload;
  _Ad(this.type, this.snap, this.apply, {this.remove, this.canDelete = false, this.payload});
}

String _str(dynamic v, [String d = '']) => v == null ? d : v.toString();
int _int(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

/// Hash sederhana & stabil (djb2 32-bit) untuk mendeteksi perubahan data.
String _h(String s) {
  var a = 5381;
  var b = 52711;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    a = ((a << 5) + a + c) & 0xFFFFFFFF;
    b = ((b << 5) ^ (b >> 3) ^ c) & 0xFFFFFFFF;
  }
  return '${a.toRadixString(16)}-${b.toRadixString(16)}-${s.length}';
}

/// JSON kanonik (kunci diurutkan; {} dan [] dianggap sama) untuk membandingkan data.
String _canon(dynamic v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    if (keys.isEmpty) return '[]';
    return '{${keys.map((k) => '${jsonEncode(k)}:${_canon(v[k])}').join(',')}}';
  }
  if (v is List) return '[${v.map(_canon).join(',')}]';
  return jsonEncode(v);
}

bool _isSeedUser(String id) => id.startsWith(kSeedUserPrefix) || id == kDefaultAdminId;

/// ============================================================================
/// SINKRONISASI DENGAN BACKEND
/// Aplikasi tetap bekerja dengan data lokal (seperti sebelumnya). Layanan ini
/// mengirim perubahan ke server dan mengambil perubahan dari pengguna lain
/// (penyelenggara <-> relawan) secara berkala. Tanpa login server (mode demo /
/// offline), layanan ini tidak aktif dan aplikasi berjalan seperti biasa.
/// ============================================================================
class ApiSync with WidgetsBindingObserver {
  ApiSync._();
  static final ApiSync instance = ApiSync._();

  final ApiClient _api = ApiClient();
  final OrgStore _org = OrgStore.instance;
  AppState? _s;
  ProfileStore? _p;
  ActivityStore? _act;
  SharedPreferences? _prefs;
  late final List<_Ad> _ads;

  /// true bila siklus sinkronisasi terakhir berhasil.
  final ValueNotifier<bool> online = ValueNotifier<bool>(false);
  String? lastError;
  final List<String> lastRejected = [];

  bool _active = false, _busy = false, _again = false, _adopt = false, _pwBusy = false;
  String? _tokenUid, _lastUid;
  Timer? _timer, _debounce;
  Map<String, Map<String, String>> _synced = {};
  final Map<String, String> _avatarUrls = {};
  Uint8List? _avBytes;
  String _avHash = 'none';

  AppState get _st => _s!;

  // ------------------------------------------------------------------ setup
  Future<void> bind(AppState s, ProfileStore p, ActivityStore a) async {
    _s = s;
    _p = p;
    _act = a;
    _prefs = await SharedPreferences.getInstance();
    await ApiConfig.load();
    _api.token = _prefs!.getString('api_token');
    _tokenUid = _prefs!.getString('api_token_uid');
    _ads = _buildAdapters();
    s.addListener(_onApp);
    p.addListener(_onLocal);
    a.addListener(_onLocal);
    WidgetsBinding.instance.addObserver(this);
  }

  bool get hasSession => _active;

  Future<String> testConnection() async {
    final r = await _api.send('GET', 'health', timeout: const Duration(seconds: 8));
    if (r.network) return 'GAGAL: server tidak terjangkau. Pastikan Laragon menyala & alamat benar.';
    if (!r.ok) return 'GAGAL: ${r.error}';
    return r.json['database'] == true ? 'Terhubung. Server & database OK.' : 'Server aktif tetapi database belum siap. Jalankan setup.php.';
  }

  // -------------------------------------------------------------- lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.resumed) {
      _restartTimer();
      syncNow();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onApp() {
    final s = _s;
    if (s == null || !s.ready) return;
    _checkAccountDeleted();
    final uid = s.sessionUserId;
    if (uid != _lastUid) {
      _lastUid = uid;
      _sessionChanged(uid);
    }
    _checkPassword();
    if (_active) _schedule();
  }

  void _onLocal() {
    if (_active) _schedule();
  }

  void _sessionChanged(String? uid) {
    _stop();
    _synced = {};
    _avatarUrls.clear();
    _avBytes = null;
    _avHash = 'none';
    if (uid == null) {
      _clearToken();
      return;
    }
    if (_tokenUid == uid && (_api.token ?? '').isNotEmpty) {
      _loadSynced(uid);
      _start();
    }
  }

  void _start() {
    _active = true;
    _restartTimer();
    syncNow();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => syncNow());
  }

  void _stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _debounce?.cancel();
    _debounce = null;
    online.value = false;
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), syncNow);
  }

  Future<void> _clearToken() async {
    final t = _api.token;
    if (t != null && t.isNotEmpty) {
      // beri tahu server (abaikan hasilnya)
      unawaited(_api.send('POST', 'auth/logout', timeout: const Duration(seconds: 6)));
    }
    _api.token = null;
    _tokenUid = null;
    await _prefs?.remove('api_token');
    await _prefs?.remove('api_token_uid');
  }

  // ------------------------------------------------- persistensi status sync
  void _loadSynced(String uid) {
    _adopt = true;
    final raw = _prefs?.getString('api_synced_$uid');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map;
      final out = <String, Map<String, String>>{};
      m.forEach((k, v) {
        out[k.toString()] = (v as Map).map((a, b) => MapEntry(a.toString(), b.toString()));
      });
      _synced = out;
      _adopt = false;
    } catch (_) {
      _synced = {};
      _adopt = true;
    }
  }

  void _saveSynced() {
    final uid = _tokenUid;
    if (uid == null) return;
    _prefs?.setString('api_synced_$uid', jsonEncode(_synced));
  }

  // --------------------------------------------- akun: password & hapus akun
  String _pwHash(String pw) => _h(pw);

  void _checkPassword() {
    final u = _st.user;
    if (!_active || u == null || u.id != _tokenUid || u.password.isEmpty || _pwBusy) return;
    final h = _pwHash(u.password);
    final saved = _prefs?.getString('api_pw_h');
    if (saved == null) {
      _prefs?.setString('api_pw_h', h);
      return;
    }
    if (saved == h) return;
    _pwBusy = true;
    _api.send('POST', 'auth/password', body: {'newPassword': u.password}).then((r) {
      _pwBusy = false;
      if (r.ok) _prefs?.setString('api_pw_h', h);
    });
  }

  void _checkAccountDeleted() {
    final id = _tokenUid;
    if (!_active || id == null) return;
    if (_st.userById(id) == null) {
      _stop();
      _api.send('POST', 'auth/delete').then((_) => _clearToken());
    }
  }

  // ------------------------------------------------------- login & register
  Future<AuthOutcome> login(AppState s, String email, String password) async {
    final r = await _api.send('POST', 'auth/login', body: {'email': email.trim(), 'password': password});
    if (r.network) return const AuthOutcome(false, null);
    if (r.status == 404) return const AuthOutcome(false, null); // akun lokal/demo: pakai login lokal
    if (!r.ok) return AuthOutcome(true, r.error ?? 'Login gagal');
    return _finishAuth(s, r.json, password, welcome: false);
  }

  Future<AuthOutcome> register(AppState s, String name, String email, String password) async {
    final r = await _api.send('POST', 'auth/register',
        body: {'name': name.trim(), 'email': email.trim(), 'password': password});
    if (r.network) return const AuthOutcome(false, null);
    if (!r.ok) return AuthOutcome(true, r.error ?? 'Pendaftaran gagal');
    return _finishAuth(s, r.json, password, welcome: true);
  }

  Future<AuthOutcome> _finishAuth(AppState s, Json data, String password, {required bool welcome}) async {
    final token = _str(data['token']);
    final uj = data['user'];
    if (token.isEmpty || uj is! Map) return const AuthOutcome(true, 'Respons server tidak valid');
    final j = Map<String, dynamic>.from(uj);
    final id = _str(j['id']);
    _api.token = token;
    _tokenUid = id;
    await _prefs?.setString('api_token', token);
    await _prefs?.setString('api_token_uid', id);
    await _prefs?.setString('api_pw_h', _pwHash(password));

    final role = _str(j['role'], 'volunteer');
    var u = s.userById(id);
    if (u == null) {
      u = AppUser(
        id: id,
        name: _str(j['name'], 'Relawan'),
        email: _str(j['email']),
        password: password,
        phone: _str(j['phone']),
        city: _str(j['city']),
        bio: _str(j['bio']),
        role: role,
      );
      s.users.add(u);
    } else {
      u.password = password;
      u.role = role;
      if (_str(j['name']).isNotEmpty) u.name = _str(j['name']);
      if (_str(j['email']).isNotEmpty) u.email = _str(j['email']);
    }
    if (welcome) {
      s.notifs.insert(
          0,
          Notif(
              id: s.newId('n'),
              userId: id,
              title: 'Selamat datang di Volunteer!',
              body: 'Yuk, cari kegiatan pertamamu dan mulai memberi dampak.',
              kind: 'info',
              createdAt: DateTime.now()));
    }
    s.sessionUserId = id;
    s.tab = 0;
    s.commitCommunity(); // memicu _onApp -> sesi dimulai
    return const AuthOutcome(true, null);
  }

  // ----------------------------------------------------------- siklus sinkron
  Future<void> syncNow() async {
    if (!_active || _s == null) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      if (_adopt) {
        await _pull(); // perangkat/akun baru: data server menang, lalu kirim yang hanya ada di perangkat
        _adopt = false;
        await _push();
      } else {
        await _push();
        await _pull();
      }
      _saveSynced();
      online.value = true;
      lastError = null;
    } catch (e) {
      online.value = false;
      lastError = e.toString();
    } finally {
      _busy = false;
      if (_again) {
        _again = false;
        _schedule();
      }
    }
  }

  void _checkAuth(ApiResponse r) {
    if (r.status == 401) {
      _stop();
      _clearToken();
      throw Exception('Sesi server berakhir. Login ulang untuk melanjutkan sinkronisasi.');
    }
  }

  Future<void> _push() async {
    if (_st.user == null) return;
    // setiap entri: [type, id, hash, payload]
    final entries = <List<dynamic>>[];
    final deleted = <String, List<String>>{};

    for (final ad in _ads) {
      final snap = ad.snap();
      final syn = _synced.putIfAbsent(ad.type, () => <String, String>{});
      for (final e in snap.entries) {
        final raw = jsonEncode(e.value);
        final h = _h(raw);
        if (syn[e.key] == h) continue;
        if (ad.type == 'avatar' && e.value['hash'] == 'none' && !syn.containsKey(e.key)) {
          syn[e.key] = h; // tidak ada foto & belum pernah sinkron: jangan hapus foto di server
          continue;
        }
        final pl = ad.payload != null ? ad.payload!(e.key, e.value) : e.value;
        entries.add([ad.type, e.key, h, pl]);
      }
      if (ad.canDelete) {
        for (final id in syn.keys) {
          if (!snap.containsKey(id)) (deleted[ad.type] ??= <String>[]).add(id);
        }
      }
    }
    if (entries.isEmpty && deleted.isEmpty) return;

    // Bagi menjadi beberapa kiriman (<= ~2,5 MB) agar tidak melebihi post_max_size PHP
    final batches = <List<List<dynamic>>>[];
    var cur = <List<dynamic>>[];
    var size = 0;
    for (final en in entries) {
      final len = jsonEncode(en[3]).length;
      if (cur.isNotEmpty && size + len > 2500000) {
        batches.add(cur);
        cur = <List<dynamic>>[];
        size = 0;
      }
      cur.add(en);
      size += len;
    }
    if (cur.isNotEmpty || batches.isEmpty) batches.add(cur);

    lastRejected.clear();
    for (var i = 0; i < batches.length; i++) {
      final changes = <String, List<Json>>{};
      for (final en in batches[i]) {
        (changes[en[0] as String] ??= <Json>[]).add(en[3] as Json);
      }
      final last = i == batches.length - 1;
      final res = await _api.send('POST', 'sync/push',
          body: {'changes': changes, 'deleted': last ? deleted : <String, List<String>>{}},
          timeout: const Duration(seconds: 120));
      _checkAuth(res);
      if (!res.ok) throw Exception(res.error ?? 'Gagal mengirim data');

      for (final en in batches[i]) {
        _synced.putIfAbsent(en[0] as String, () => <String, String>{})[en[1] as String] = en[2] as String;
      }
      if (last) {
        deleted.forEach((type, ids) {
          final syn = _synced.putIfAbsent(type, () => <String, String>{});
          for (final id in ids) {
            syn.remove(id);
          }
        });
      }
      final av = res.json['avatarUrls'];
      if (av is Map) {
        av.forEach((k, v) => _avatarUrls[k.toString()] = _str(v));
      }
      final rej = res.json['rejected'];
      if (rej is List) {
        for (final r in rej) {
          if (r is Map) lastRejected.add('${r['type']}/${r['id']}: ${r['reason']}');
        }
      }
    }
  }

  Future<void> _pull() async {
    final r = await _api.send('GET', 'sync/pull');
    _checkAuth(r);
    if (!r.ok) throw Exception(r.error ?? 'Gagal mengambil data');
    final ents = r.json['entities'];
    if (ents is! Map) return;
    var changed = false;

    for (final ad in _ads) {
      final raw = ents[ad.type];
      if (raw is! List) continue;
      final syn = _synced.putIfAbsent(ad.type, () => <String, String>{});
      final before = ad.snap();
      final seen = <String>{};
      final taken = <String>[];

      for (final item in raw) {
        if (item is! Map) continue;
        final j = Map<String, dynamic>.from(item);
        final id = _str(j['id']);
        if (id.isEmpty) continue;
        seen.add(id);
        final local = before[id];
        // perubahan lokal yang belum terkirim tidak ditimpa
        if (local != null && syn.containsKey(id) && syn[id] != _h(jsonEncode(local))) continue;
        try {
          if (ad.apply(j)) changed = true;
          taken.add(id);
        } catch (_) {/* satu data rusak tidak boleh menggagalkan semuanya */}
      }

      if (taken.isNotEmpty) {
        final after = ad.snap();
        for (final id in taken) {
          final a = after[id];
          if (a != null) syn[id] = _h(jsonEncode(a));
        }
      }

      if (ad.remove != null) {
        final gone = syn.keys.where((id) => !seen.contains(id)).toList();
        for (final id in gone) {
          final local = before[id];
          if (local == null) {
            syn.remove(id);
          } else if (_h(jsonEncode(local)) == syn[id]) {
            ad.remove!(id); // sudah dihapus di server
            syn.remove(id);
            changed = true;
          }
        }
      }
    }
    if (changed) _flush();
  }

  void _flush() {
    unawaited(_org.save());
    _st.commitCommunity();
    _org.setFlags(); // menyimpan + memberi tahu halaman penyelenggara
  }

  // ====================================================================
  // ADAPTER PER JENIS DATA
  // ====================================================================
  List<_Ad> _buildAdapters() => [
        _Ad('user', _snapUser, _applyUser),
        _Ad('avatar', _snapAvatar, (j) => false, payload: _avatarPayload),
        _Ad('event', _snapEvent, _applyEvent, payload: _eventPayload),
        _Ad('reg', _snapReg, _applyReg),
        _Ad('notif', _snapNotif, _applyNotif),
        _Ad('point', _snapPoint, _applyPoint),
        _Ad('cert', _snapCert, _applyCert),
        _Ad('orgmsg', _snapOrgMsg, _applyOrgMsg),
        _Ad('feedback', _snapFeedback, _applyFeedback),
        _Ad('cmsg', _snapCmsg, _applyCmsg, canDelete: true, remove: (id) {
          _st.commMessages.removeWhere((m) => m.id == id);
        }),
        _Ad('announce', _snapAnnounce, _applyAnnounce, canDelete: true, remove: (id) {
          _st.announcements.removeWhere((a) => a.id == id);
        }),
        _Ad('poll', _snapPoll, _applyPoll, canDelete: true, remove: (id) {
          _st.polls.removeWhere((p) => p.id == id);
        }),
        _Ad('report', _snapReport, _applyReport, canDelete: true, remove: (id) {
          _st.commReports.removeWhere((r) => r.id == id);
        }),
        _Ad('orgprofile', _snapOrgProfile, _applyOrgProfile),
        _Ad('kv', _snapKv, _applyKv),
      ];

  bool get _isOrg => _st.user?.role == kOrgRole;

  // ------------------------------------------------------------------ user
  Map<String, Json> _snapUser() {
    final u = _st.user;
    if (u == null) return {};
    return {
      u.id: {
        'id': u.id, 'name': u.name, 'email': u.email, 'phone': u.phone, 'city': u.city,
        'bio': u.bio, 'role': u.role,
      }
    };
  }

  bool _applyUser(Json j) {
    final id = _str(j['id']);
    if (id.isEmpty) return false;
    var changed = false;
    var u = _st.userById(id);
    final name = _str(j['name']);
    if (u == null) {
      u = AppUser(
        id: id,
        name: name.isEmpty ? 'Relawan' : name,
        email: _str(j['email']),
        password: '',
        phone: _str(j['phone']),
        city: _str(j['city']),
        bio: _str(j['bio']),
        pastEvents: _int(j['pastEvents']),
        pastHours: _int(j['pastHours']),
        pastPoints: _int(j['pastPoints']),
        pastImpact: _int(j['pastImpact']),
        role: _str(j['role'], 'volunteer'),
      );
      _st.users.add(u);
      changed = true;
    } else {
      if (name.isNotEmpty && u.name != name) {
        u.name = name;
        changed = true;
      }
      final email = _str(j['email']);
      if (email.isNotEmpty && u.email != email) {
        u.email = email;
        changed = true;
      }
      final phone = _str(j['phone']);
      if (phone.isNotEmpty && u.phone != phone) {
        u.phone = phone;
        changed = true;
      }
      if (u.city != _str(j['city'])) {
        u.city = _str(j['city']);
        changed = true;
      }
      if (u.bio != _str(j['bio'])) {
        u.bio = _str(j['bio']);
        changed = true;
      }
      final role = _str(j['role'], u.role);
      if (u.role != role) {
        u.role = role;
        changed = true;
      }
      if (u.pastEvents != _int(j['pastEvents'])) {
        u.pastEvents = _int(j['pastEvents']);
        changed = true;
      }
      if (u.pastHours != _int(j['pastHours'])) {
        u.pastHours = _int(j['pastHours']);
        changed = true;
      }
      if (u.pastPoints != _int(j['pastPoints'])) {
        u.pastPoints = _int(j['pastPoints']);
        changed = true;
      }
      if (u.pastImpact != _int(j['pastImpact'])) {
        u.pastImpact = _int(j['pastImpact']);
        changed = true;
      }
    }
    _syncAvatar(id, _str(j['avatarUrl']));
    return changed;
  }

  // ---------------------------------------------------------------- avatar
  Map<String, Json> _snapAvatar() {
    final u = _st.user;
    final p = _p;
    if (u == null || p == null) return {};
    final b = p.avatarOf(u.id);
    var h = 'none';
    if (b != null) {
      if (!identical(b, _avBytes)) {
        _avBytes = b;
        _avHash = '${b.length}:${Object.hashAll(b)}';
      }
      h = _avHash;
    }
    return {u.id: {'id': u.id, 'hash': h}};
  }

  Json _avatarPayload(String id, Json local) {
    final b = _p?.avatarOf(id);
    if (b == null) return {'userId': id, 'remove': true};
    return {'userId': id, 'dataUri': 'data:image/jpeg;base64,${base64Encode(b)}'};
  }

  void _syncAvatar(String id, String url) {
    final p = _p;
    if (p == null) return;
    final known = _avatarUrls[id] ?? '';
    if (url == known) return;
    _avatarUrls[id] = url;
    if (url.isEmpty) {
      if (p.avatarOf(id) != null) p.setAvatar(id, null);
      _markAvatarSynced(id);
    } else {
      unawaited(_downloadAvatar(id, url));
    }
  }

  Future<void> _downloadAvatar(String id, String url) async {
    try {
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
      if (r.statusCode != 200 || r.bodyBytes.isEmpty) {
        _avatarUrls.remove(id);
        return;
      }
      _p?.setAvatar(id, r.bodyBytes);
      _markAvatarSynced(id);
    } catch (_) {
      _avatarUrls.remove(id);
    }
  }

  void _markAvatarSynced(String id) {
    if (id != _st.sessionUserId) return;
    final a = _snapAvatar()[id];
    if (a == null) return;
    _synced.putIfAbsent('avatar', () => <String, String>{})[id] = _h(jsonEncode(a));
  }

  // ----------------------------------------------------------------- event
  final Map<String, String> _assetData = {}; // path aset -> data URI (untuk diunggah ke server)

  Json _eventPayload(String id, Json local) {
    final img = _str(local['image']);
    final d = _assetData[img];
    if (d == null) return local;
    final j = Map<String, dynamic>.from(local);
    j['image'] = d; // server menyimpannya sebagai file di uploads/events/
    return j;
  }

  /// Memasukkan SEMUA event bawaan aplikasi (seed_data.dart, termasuk fotonya) ke database.
  /// Aman dipanggil berulang: hanya event yang belum ada di server yang dikirim, sehingga
  /// event yang kamu tambahkan di kode nanti ikut masuk saat tombol ini ditekan lagi.
  Future<String> uploadLocalEvents() async {
    final me = _st.user;
    if (me == null || me.role != kOrgRole) return 'Hanya akun penyelenggara yang dapat mengunggah event.';
    if (!_active) return 'Belum terhubung ke server. Login lewat server lalu coba lagi.';
    var added = 0;
    for (final e in List<EventModel>.from(_st.events)) {
      if (_org.meta.containsKey(e.id) || _org.custom.containsKey(e.id) || _org.deleted.contains(e.id)) continue;
      if (e.image.startsWith('assets/') && !_assetData.containsKey(e.image)) {
        try {
          final bd = await rootBundle.load(e.image);
          final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
          _assetData[e.image] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } catch (_) {/* foto tidak ditemukan: kirim tanpa unggah gambar */}
      }
      _org.custom[e.id] = e;
      _org.meta[e.id] = EventMeta(ownerId: me.id, status: 'published');
      added++;
    }
    if (added == 0) return 'Semua event bawaan sudah ada di server.';
    _flush();
    await syncNow();
    return online.value
        ? '$added event beserta fotonya dikirim ke database.'
        : 'Tersimpan di perangkat, tetapi gagal terkirim: ${lastError ?? 'server tidak terjangkau'}';
  }

  Map<String, Json> _snapEvent() {
    final me = _st.user;
    final out = <String, Json>{};
    if (me == null || me.role != kOrgRole) return out;
    final ids = <String>{..._org.custom.keys, ..._org.meta.keys};
    for (final id in ids) {
      final e = _org.custom[id] ?? _st.eventById(id);
      if (e == null) continue;
      if (_org.ownerOf(e) != me.id) continue;
      final j = Map<String, dynamic>.from(eventToJson(e));
      j['meta'] = _org.metaOf(e).toJson();
      out[id] = j;
    }
    for (final id in _org.deleted) {
      out[id] = {'id': id, 'deleted': true};
    }
    return out;
  }

  bool _applyEvent(Json j) {
    final id = _str(j['id']);
    if (id.isEmpty) return false;
    if (j['deleted'] == true) {
      final had = _org.deleted.contains(id) == false ||
          _st.events.any((x) => x.id == id) ||
          _org.custom.containsKey(id);
      _org.custom.remove(id);
      _org.meta.remove(id);
      _org.deleted.add(id);
      _st.events.removeWhere((x) => x.id == id);
      return had;
    }
    final e = eventFromJson(j);
    final mj = j['meta'];
    final m = mj is Map
        ? EventMeta.fromJson(Map<String, dynamic>.from(mj))
        : EventMeta(ownerId: kDemoOrgId, status: 'published');
    final old = _org.custom[id] ?? _st.eventById(id);
    var changed = true;
    if (old != null && _org.meta.containsKey(id)) {
      changed = _canon(eventToJson(old)) != _canon(eventToJson(e)) ||
          _canon(_org.meta[id]!.toJson()) != _canon(m.toJson());
    }
    _org.deleted.remove(id);
    _org.custom[id] = e;
    _org.meta[id] = m;
    if (m.status == 'draft') {
      if (_st.events.any((x) => x.id == id)) changed = true;
      _st.events.removeWhere((x) => x.id == id);
    } else {
      final i = _st.events.indexWhere((x) => x.id == id);
      if (i >= 0) {
        _st.events[i] = e;
      } else {
        _st.events.insert(0, e);
        changed = true;
      }
    }
    return changed;
  }

  // ---------------------------------------------------------- pendaftaran
  Json _regJson(Registration r) {
    final j = Map<String, dynamic>.from(r.toJson());
    j['approval'] = _org.approvals[r.id] ?? '';
    j['checkIn'] = _org.checkIns[r.id] ?? '';
    j['checkOut'] = _org.checkOuts[r.id] ?? '';
    return j;
  }

  Map<String, Json> _snapReg() {
    final me = _st.user;
    final out = <String, Json>{};
    if (me == null) return out;
    final own = _isOrg ? _org.myEvents(_st, me.id).map((e) => e.id).toSet() : <String>{};
    for (final r in _st.regs) {
      if (_isSeedUser(r.userId)) continue;
      if (r.userId == me.id || own.contains(r.eventId)) out[r.id] = _regJson(r);
    }
    return out;
  }

  bool _applyReg(Json j) {
    final r = Registration.fromJson(j);
    final i = _st.regs.indexWhere((x) => x.id == r.id);
    var changed = false;
    final a = _str(j['approval']);
    final ci = _str(j['checkIn']);
    final co = _str(j['checkOut']);
    if (i >= 0) {
      final o = _st.regs[i];
      final newCode = r.code.isEmpty ? o.code : r.code; // kode disamarkan untuk relawan lain
      if (o.status != r.status || o.code != newCode) {
        _st.regs[i] = Registration(
            id: o.id, userId: o.userId, eventId: o.eventId, code: newCode, createdAt: o.createdAt, status: r.status);
        changed = true;
      }
    } else {
      _st.regs.add(r);
      changed = true;
    }
    if ((_org.approvals[r.id] ?? '') != a) {
      if (a.isEmpty) {
        _org.approvals.remove(r.id);
      } else {
        _org.approvals[r.id] = a;
      }
      changed = true;
    }
    if ((_org.checkIns[r.id] ?? '') != ci) {
      if (ci.isEmpty) {
        _org.checkIns.remove(r.id);
      } else {
        _org.checkIns[r.id] = ci;
      }
      changed = true;
    }
    if ((_org.checkOuts[r.id] ?? '') != co) {
      if (co.isEmpty) {
        _org.checkOuts.remove(r.id);
      } else {
        _org.checkOuts[r.id] = co;
      }
      changed = true;
    }
    return changed;
  }

  // ----------------------------------------------------------- notifikasi
  Map<String, Json> _snapNotif() {
    final out = <String, Json>{};
    if (_st.user == null) return out;
    for (final n in _st.notifs) {
      if (_isSeedUser(n.userId)) continue;
      out[n.id] = n.toJson();
    }
    return out;
  }

  bool _applyNotif(Json j) {
    final n = Notif.fromJson(j);
    final i = _st.notifs.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      if (n.read && !_st.notifs[i].read) {
        _st.notifs[i].read = true;
        return true;
      }
      return false;
    }
    var pos = 0;
    while (pos < _st.notifs.length && _st.notifs[pos].createdAt.isAfter(n.createdAt)) {
      pos++;
    }
    _st.notifs.insert(pos, n);
    return true;
  }

  // ----------------------------------------------------------------- poin
  Map<String, Json> _snapPoint() {
    final out = <String, Json>{};
    if (_st.user == null) return out;
    for (final e in _st.pointEntries) {
      if (_isSeedUser(e.userId)) continue;
      out[e.id] = e.toJson();
    }
    return out;
  }

  bool _applyPoint(Json j) {
    final e = PointEntry.fromJson(j);
    if (_st.pointEntries.any((x) => x.id == e.id)) return false;
    _st.pointEntries.add(e);
    return true;
  }

  // ----------------------------------------------------------- sertifikat
  Map<String, Json> _snapCert() {
    final out = <String, Json>{};
    if (!_isOrg) return out;
    for (final c in _org.certs) {
      if (_isSeedUser(c.userId)) continue;
      out[c.id] = c.toJson();
    }
    return out;
  }

  bool _applyCert(Json j) {
    final c = OrgCert.fromJson(j);
    if (_org.certs.any((x) => x.id == c.id)) return false;
    _org.certs.add(c);
    return true;
  }

  // ------------------------------------------------ pesan penyelenggara
  Map<String, Json> _snapOrgMsg() {
    final me = _st.user;
    final out = <String, Json>{};
    if (me == null || !_isOrg) return out;
    for (final m in _org.messages) {
      if (m.ownerId == me.id) out[m.id] = m.toJson();
    }
    return out;
  }

  bool _applyOrgMsg(Json j) {
    final m = OrgMessage.fromJson(j);
    if (_org.messages.any((x) => x.id == m.id)) return false;
    _org.messages.add(m);
    _org.messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return true;
  }

  // ------------------------------------------------------------- feedback
  Map<String, Json> _snapFeedback() {
    final me = _st.user;
    final out = <String, Json>{};
    if (me == null) return out;
    for (final f in _st.feedbacks) {
      if (f.userId == me.id) out[f.id] = f.toJson();
    }
    return out;
  }

  bool _applyFeedback(Json j) {
    final f = FeedbackItem.fromJson(j);
    if (_st.feedbacks.any((x) => x.id == f.id)) return false;
    _st.feedbacks.add(f);
    _st.feedbacks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return true;
  }

  // ------------------------------------------------------------ komunitas
  Map<String, Json> _snapCmsg() {
    final out = <String, Json>{};
    if (_st.user == null) return out;
    for (final m in _st.commMessages) {
      if (_isSeedUser(m.senderId)) continue;
      out[m.id] = m.toJson();
    }
    return out;
  }

  bool _applyCmsg(Json j) {
    final m = CommMessage.fromJson(j);
    final i = _st.commMessages.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      if (_canon(_st.commMessages[i].toJson()) == _canon(m.toJson())) return false;
      _st.commMessages[i] = m;
      return true;
    }
    _st.commMessages.add(m);
    return true;
  }

  Map<String, Json> _snapAnnounce() {
    final out = <String, Json>{};
    if (_st.user == null) return out;
    for (final a in _st.announcements) {
      if (_isSeedUser(a.authorId)) continue;
      out[a.id] = a.toJson();
    }
    return out;
  }

  bool _applyAnnounce(Json j) {
    final a = Announcement.fromJson(j);
    final i = _st.announcements.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      if (_canon(_st.announcements[i].toJson()) == _canon(a.toJson())) return false;
      _st.announcements[i] = a;
      return true;
    }
    _st.announcements.add(a);
    return true;
  }

  Map<String, Json> _snapPoll() {
    final out = <String, Json>{};
    if (_st.user == null) return out;
    for (final p in _st.polls) {
      if (_isSeedUser(p.creatorId)) continue;
      out[p.id] = p.toJson();
    }
    return out;
  }

  bool _applyPoll(Json j) {
    final p = CommPoll.fromJson(j);
    final i = _st.polls.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      if (_canon(_st.polls[i].toJson()) == _canon(p.toJson())) return false;
      _st.polls[i] = p;
      return true;
    }
    _st.polls.add(p);
    return true;
  }

  Map<String, Json> _snapReport() {
    final out = <String, Json>{};
    if (_st.user == null) return out;
    for (final r in _st.commReports) {
      if (_isSeedUser(r.reporterId)) continue;
      out[r.id] = r.toJson();
    }
    return out;
  }

  bool _applyReport(Json j) {
    final r = CommReport.fromJson(j);
    if (_st.commReports.any((x) => x.id == r.id)) return false;
    _st.commReports.add(r);
    return true;
  }

  // ---------------------------------------------------- profil penyelenggara
  Map<String, Json> _snapOrgProfile() {
    final me = _st.user;
    final out = <String, Json>{};
    if (me == null || !_isOrg) return out;
    final p = _org.profiles[me.id];
    if (p == null) return out;
    final j = Map<String, dynamic>.from(p.toJson());
    j['id'] = me.id;
    out[me.id] = j;
    return out;
  }

  bool _applyOrgProfile(Json j) {
    final id = _str(j['id']);
    if (id.isEmpty) return false;
    final p = OrgProfile.fromJson(j);
    final old = _org.profiles[id];
    if (old != null && _canon(old.toJson()) == _canon(p.toJson())) return false;
    _org.profiles[id] = p;
    return true;
  }

  // ------------------------------------------- data kecil per pengguna (kv)
  Map<String, dynamic> _readPrefMap(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return <String, dynamic>{};
    try {
      final d = jsonDecode(raw);
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, Json> _snapKv() {
    final me = _st.user;
    final out = <String, Json>{};
    if (me == null) return out;
    final syn = _synced['kv'] ?? <String, String>{};
    void put(String key, dynamic value, bool empty) {
      final id = '${me.id}:$key';
      if (empty && !syn.containsKey(id)) return;
      out[id] = {'id': id, 'userId': me.id, 'key': key, 'value': value};
    }

    final pre = '${me.id}:';
    final bm = _st.bookmarks.where((x) => x.startsWith(pre)).toList()..sort();
    put('bookmarks', bm, bm.isEmpty);
    final bl = _st.commBlocked.where((x) => x.startsWith(pre)).toList()..sort();
    put('blocked', bl, bl.isEmpty);
    final lr = <String, int>{};
    _st.commLastRead.forEach((k, v) {
      if (k.startsWith(pre)) lr[k] = v;
    });
    put('lastread', lr, lr.isEmpty);
    final pf = _readPrefMap('pf_user_${me.id}')..remove('avatar');
    put('profile_extra', pf, pf.isEmpty);
    final ac = _readPrefMap('act_user_${me.id}');
    put('activity_extra', ac, ac.isEmpty);
    return out;
  }

  bool _applyKv(Json j) {
    final me = _st.user;
    if (me == null) return false;
    final key = _str(j['key']);
    final val = j['value'];
    final pre = '${me.id}:';
    switch (key) {
      case 'bookmarks':
        {
          final remote = (val is List ? val : <dynamic>[]).map((e) => e.toString()).where((x) => x.startsWith(pre)).toSet();
          final local = _st.bookmarks.where((x) => x.startsWith(pre)).toSet();
          if (remote.length == local.length && remote.containsAll(local)) return false;
          _st.bookmarks.removeWhere((x) => x.startsWith(pre));
          _st.bookmarks.addAll(remote);
          return true;
        }
      case 'blocked':
        {
          final remote = (val is List ? val : <dynamic>[]).map((e) => e.toString()).where((x) => x.startsWith(pre)).toSet();
          final local = _st.commBlocked.where((x) => x.startsWith(pre)).toSet();
          if (remote.length == local.length && remote.containsAll(local)) return false;
          _st.commBlocked.removeWhere((x) => x.startsWith(pre));
          _st.commBlocked.addAll(remote);
          return true;
        }
      case 'lastread':
        {
          var changed = false;
          if (val is Map) {
            val.forEach((k, v) {
              final key2 = k.toString();
              if (!key2.startsWith(pre)) return;
              final n = _int(v);
              if (n > (_st.commLastRead[key2] ?? 0)) {
                _st.commLastRead[key2] = n;
                changed = true;
              }
            });
          }
          return changed;
        }
      case 'profile_extra':
        {
          final map = val is Map ? Map<String, dynamic>.from(val) : <String, dynamic>{};
          final cur = _readPrefMap('pf_user_${me.id}');
          final avatar = cur['avatar'];
          final cmp = Map<String, dynamic>.from(cur)..remove('avatar');
          if (_canon(cmp) == _canon(map)) return false;
          final merged = Map<String, dynamic>.from(map);
          if (avatar != null) merged['avatar'] = avatar;
          _prefs?.setString('pf_user_${me.id}', jsonEncode(merged));
          _p?.reloadUser(me.id);
          return true;
        }
      case 'activity_extra':
        {
          final map = val is Map ? Map<String, dynamic>.from(val) : <String, dynamic>{};
          final cur = _readPrefMap('act_user_${me.id}');
          if (_canon(cur) == _canon(map)) return false;
          _prefs?.setString('act_user_${me.id}', jsonEncode(map));
          _act?.reloadUser(me.id);
          return true;
        }
    }
    return false;
  }
}
