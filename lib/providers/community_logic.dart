import '../data/leaderboard_seed.dart';
import '../models/community.dart';
import '../models/models.dart';
import 'app_state.dart';

String _short(String s) {
  final t = s.trim().replaceAll('
', ' ');
  return t.length <= 70 ? t : '${t.substring(0, 70)}...';
}

/// Seluruh logika Komunitas Relawan. Data disimpan lewat AppState
/// (shared_preferences) sehingga tidak hilang saat aplikasi ditutup.
extension CommunityLogic on AppState {
  // ------------------------------------------------------------- admin
  bool get isCommAdmin => user != null && commAdmins.contains(user!.id);

  /// Mode admin untuk demo (tanpa backend, peran admin diatur lokal).
  void toggleCommAdmin() {
    final u = user;
    if (u == null) return;
    if (!commAdmins.remove(u.id)) commAdmins.add(u.id);
    commitCommunity();
  }

  // ------------------------------------------------------------ blokir
  bool isBlockedByMe(String userId) => user != null && commBlocked.contains('${user!.id}:$userId');

  String? blockUser(String userId) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    if (userId == u.id) return 'Kamu tidak dapat memblokir diri sendiri';
    commBlocked.add('${u.id}:$userId');
    commitCommunity();
    return null;
  }

  void unblockUser(String userId) {
    final u = user;
    if (u == null) return;
    commBlocked.remove('${u.id}:$userId');
    commitCommunity();
  }

  List<AppUser> get blockedUsers => users.where((x) => isBlockedByMe(x.id)).toList();

  // ----------------------------------------------------------- anggota
  /// Semua relawan terdaftar, diurutkan dari poin tertinggi.
  List<AppUser> get communityMembers {
    final list = List<AppUser>.from(users);
    list.sort((a, b) => pointsOf(b.id).compareTo(pointsOf(a.id)));
    return list;
  }

  // ------------------------------------------------------------- pesan
  CommMessage? messageById(String id) {
    for (final m in commMessages) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<CommMessage> roomMessages(String roomId) {
    final list =
        commMessages.where((m) => m.roomId == roomId && !isBlockedByMe(m.senderId)).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  List<CommMessage> latestDiscussions({int limit = 5}) {
    final list = commMessages.where((m) => !isBlockedByMe(m.senderId)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  int replyCount(String messageId) => commMessages.where((m) => m.replyToId == messageId).length;

  /// Jumlah anggota aktif ruang (pengirim pesan). Ruang Umum = seluruh anggota.
  int roomMemberCount(String roomId) {
    if (roomId == 'umum') return users.length;
    final ids = <String>{};
    for (final m in commMessages) {
      if (m.roomId == roomId) ids.add(m.senderId);
    }
    return ids.length;
  }

  // ---------------------------------------------------- belum dibaca
  int _lastRead(String roomId) {
    final u = user;
    if (u == null) return 0;
    return commLastRead['${u.id}:$roomId'] ?? 0;
  }

  int unreadInRoom(String roomId) {
    final u = user;
    if (u == null) return 0;
    final last = _lastRead(roomId);
    return commMessages
        .where((m) =>
            m.roomId == roomId &&
            m.senderId != u.id &&
            !isBlockedByMe(m.senderId) &&
            m.createdAt.millisecondsSinceEpoch > last)
        .length;
  }

  int get unreadCommTotal {
    var n = 0;
    for (final r in kRooms) {
      n += unreadInRoom(r.id);
    }
    return n;
  }

  void markRoomRead(String roomId) {
    final u = user;
    if (u == null) return;
    final key = '${u.id}:$roomId';
    final now = DateTime.now().millisecondsSinceEpoch;
    if ((commLastRead[key] ?? 0) >= now - 500) return;
    commLastRead[key] = now;
    commitCommunity();
  }

  // ---------------------------------------------------------- kirim
  /// Mengirim pesan teks atau undangan event ke sebuah ruang diskusi.
  /// Mengembalikan pesan error atau null jika berhasil.
  String? sendRoomMessage({
    required String roomId,
    String text = '',
    String? replyToId,
    String? eventId,
  }) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    final t = text.trim();
    if (eventId == null && t.isEmpty) return 'Pesan tidak boleh kosong';
    if (t.length > 500) return 'Pesan maksimal 500 karakter';
    if (eventId != null && eventById(eventId) == null) return 'Event tidak ditemukan';

    final msg = CommMessage(
      id: newId('cm'),
      roomId: roomId,
      senderId: u.id,
      senderName: u.name,
      text: t,
      type: eventId == null ? 'text' : 'invite',
      eventId: eventId,
      replyToId: replyToId,
      createdAt: DateTime.now(),
    );
    commMessages.add(msg);
    _notifyForMessage(msg);
    commitCommunity();
    return null;
  }

  void _pushNotif(String userId, String title, String body, String kind) {
    notifs.insert(
      0,
      Notif(
        id: newId('n'),
        userId: userId,
        title: title,
        body: body,
        kind: kind,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Notifikasi untuk anggota lain: balasan, undangan event, dan pesan baru.
  void _notifyForMessage(CommMessage m) {
    final room = roomById(m.roomId);
    CommMessage? replied;
    if (m.replyToId != null) replied = messageById(m.replyToId!);

    for (final u in users) {
      if (u.id == m.senderId) continue;
      if (u.id.startsWith(kSeedUserPrefix)) continue; // relawan awal tidak punya sesi
      if (commBlocked.contains('${u.id}:${m.senderId}')) continue; // pengirim diblokir
      if (replied != null && replied.senderId == u.id) {
        _pushNotif(u.id, 'Balasan dari ${m.senderName}', _short(m.text), 'comm_reply:${m.roomId}');
      } else if (m.isInvite) {
        final e = m.eventId == null ? null : eventById(m.eventId!);
        _pushNotif(u.id, 'Undangan event dari ${m.senderName}', e?.title ?? 'Ajakan kegiatan relawan',
            'comm_invite:${m.roomId}');
      } else {
        // pesan baru: gabungkan notifikasi belum dibaca agar tidak membanjiri
        final kind = 'comm_msg:${m.roomId}';
        notifs.removeWhere((n) => n.userId == u.id && n.kind == kind && !n.read);
        _pushNotif(u.id, 'Pesan baru di ${room.name}', '${m.senderName}: ${_short(m.text)}', kind);
      }
    }
  }

  // ------------------------------------------------------------ reaksi
  void toggleReaction(String messageId, String emoji) {
    final u = user;
    final m = messageById(messageId);
    if (u == null || m == null) return;
    final list = m.reactions.putIfAbsent(emoji, () => <String>[]);
    if (!list.remove(u.id)) list.add(u.id);
    if (list.isEmpty) m.reactions.remove(emoji);
    commitCommunity();
  }

  // ------------------------------------------------------------- hapus
  /// Pengguna hanya dapat menghapus pesan miliknya. Admin dapat menghapus pesan
  /// yang melanggar.
  String? deleteMessage(String messageId) {
    final u = user;
    final m = messageById(messageId);
    if (u == null) return 'Silakan login terlebih dahulu';
    if (m == null) return 'Pesan tidak ditemukan';
    if (m.senderId != u.id && !isCommAdmin) return 'Kamu hanya dapat menghapus pesan milikmu sendiri';
    commMessages.removeWhere((x) => x.id == messageId);
    commReports.removeWhere((r) => r.messageId == messageId);
    commitCommunity();
    return null;
  }

  // ----------------------------------------------------------- laporan
  bool hasReported(String messageId) {
    final u = user;
    if (u == null) return false;
    return commReports.any((r) => r.messageId == messageId && r.reporterId == u.id);
  }

  String? reportMessage(String messageId, String reason) {
    final u = user;
    final m = messageById(messageId);
    if (u == null) return 'Silakan login terlebih dahulu';
    if (m == null) return 'Pesan tidak ditemukan';
    if (m.senderId == u.id) return 'Kamu tidak dapat melaporkan pesanmu sendiri';
    if (hasReported(messageId)) return 'Kamu sudah melaporkan pesan ini';
    commReports.add(CommReport(
      id: newId('rp'),
      messageId: messageId,
      reporterId: u.id,
      reporterName: u.name,
      reason: reason,
      messageText: m.isInvite ? '[Undangan event] ${m.text}' : m.text,
      senderName: m.senderName,
      roomId: m.roomId,
      createdAt: DateTime.now(),
    ));
    commitCommunity();
    return null;
  }

  List<CommReport> get pendingReports {
    final list = List<CommReport>.from(commReports);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void dismissReport(String reportId) {
    commReports.removeWhere((r) => r.id == reportId);
    commitCommunity();
  }

  // ------------------------------------------------------- pengumuman
  /// Penting dulu, lalu terbaru.
  List<Announcement> get sortedAnnouncements {
    final list = List<Announcement>.from(announcements);
    list.sort((a, b) {
      if (a.important != b.important) return a.important ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  String? createAnnouncement({
    required String title,
    required String body,
    bool important = false,
    String? eventId,
  }) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    if (!isCommAdmin) return 'Hanya admin yang dapat membuat pengumuman';
    if (title.trim().isEmpty || body.trim().isEmpty) return 'Judul dan isi pengumuman wajib diisi';
    final a = Announcement(
      id: newId('an'),
      title: title.trim(),
      body: body.trim(),
      authorId: u.id,
      authorName: u.name,
      important: important,
      eventId: eventId,
      createdAt: DateTime.now(),
    );
    announcements.insert(0, a);
    for (final x in users) {
      if (x.id == u.id || x.id.startsWith(kSeedUserPrefix)) continue;
      _pushNotif(x.id, important ? 'Pengumuman penting' : 'Pengumuman baru', a.title, 'comm_announce:${a.id}');
    }
    commitCommunity();
    return null;
  }

  /// Hanya admin yang dapat menghapus pengumuman resmi.
  String? deleteAnnouncement(String id) {
    if (!isCommAdmin) return 'Hanya admin yang dapat menghapus pengumuman resmi';
    announcements.removeWhere((a) => a.id == id);
    notifs.removeWhere((n) => n.kind == 'comm_announce:$id');
    commitCommunity();
    return null;
  }

  // ----------------------------------------------------------- polling
  /// Aktif dulu, lalu terbaru.
  List<CommPoll> get sortedPolls {
    final list = List<CommPoll>.from(polls);
    list.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  String? createPoll({required String question, required List<String> options, int days = 3}) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    final q = question.trim();
    if (q.isEmpty) return 'Pertanyaan polling wajib diisi';
    final opts = <String>[];
    for (final o in options) {
      final t = o.trim();
      if (t.isEmpty) continue;
      if (opts.any((x) => x.toLowerCase() == t.toLowerCase())) return 'Pilihan tidak boleh sama';
      opts.add(t);
    }
    if (opts.length < 2) return 'Isi minimal 2 pilihan';
    if (opts.length > 5) return 'Maksimal 5 pilihan';
    final now = DateTime.now();
    polls.insert(
      0,
      CommPoll(
        id: newId('poll'),
        question: q,
        options: opts,
        creatorId: u.id,
        creatorName: u.name,
        createdAt: now,
        endsAt: now.add(Duration(days: days)),
      ),
    );
    commitCommunity();
    return null;
  }

  int? myVote(CommPoll p) => user == null ? null : p.votes[user!.id];

  /// Satu pengguna hanya dapat memberi satu suara untuk setiap polling.
  String? votePoll(String pollId, int index) {
    final u = user;
    if (u == null) return 'Silakan login terlebih dahulu';
    CommPoll? p;
    for (final x in polls) {
      if (x.id == pollId) p = x;
    }
    if (p == null) return 'Polling tidak ditemukan';
    if (!p.active) return 'Polling sudah berakhir';
    if (p.votes.containsKey(u.id)) return 'Kamu sudah memberikan suara';
    if (index < 0 || index >= p.options.length) return 'Pilihan tidak valid';
    p.votes[u.id] = index;
    commitCommunity();
    return null;
  }

  // ------------------------------------------------------- notifikasi
  List<Notif> get commNotifs =>
      notifs.where((n) => n.userId == user?.id && n.kind.startsWith('comm_')).toList();

  int get commNotifUnread => commNotifs.where((n) => !n.read).length;

  void markAllCommRead() {
    for (final n in commNotifs) {
      n.read = true;
    }
    commitCommunity();
  }

  void markCommNotifRead(String id) {
    for (final n in notifs) {
      if (n.id == id) n.read = true;
    }
    commitCommunity();
  }
}
