import 'package:flutter/material.dart';

/// Pengganti withOpacity (tidak deprecated di Flutter terbaru).
Color commA(Color c, double o) => c.withAlpha((o * 255).round().clamp(0, 255).toInt());

// ============================================================
// RUANG DISKUSI PER KATEGORI
// ============================================================
class RoomDef {
  final String id, name, desc;
  final IconData icon;
  final Color color;
  const RoomDef(this.id, this.name, this.desc, this.icon, this.color);
}

const List<RoomDef> kRooms = [
  RoomDef('lingkungan', 'Lingkungan', 'Diskusi aksi peduli lingkungan', Icons.eco, Color(0xFF15803D)),
  RoomDef('pendidikan', 'Pendidikan', 'Diskusi kegiatan edukasi dan mengajar', Icons.menu_book, Color(0xFF2563EB)),
  RoomDef('sosial', 'Sosial', 'Diskusi kegiatan sosial dan kemanusiaan', Icons.volunteer_activism, Color(0xFFDB2777)),
  RoomDef('umum', 'Umum', 'Ngobrol santai antar relawan', Icons.groups, Color(0xFFDC2626)),
];

RoomDef roomById(String id) {
  for (final r in kRooms) {
    if (r.id == id) return r;
  }
  return kRooms.last;
}

const List<String> kReactionEmojis = ['👍', '❤️', '😂', '🙏', '👏', '🔥'];
const List<String> kQuickEmojis = ['😊', '😂', '👍', '❤️', '🙏', '🔥', '👏', '🎉', '🌱', '💪', '🤝', '😍'];
const List<String> kReportReasons = [
  'Spam atau promosi',
  'Ujaran kebencian / SARA',
  'Bahasa kasar atau pelecehan',
  'Membagikan data pribadi',
  'Penipuan atau tautan berbahaya',
  'Lainnya',
];

// ============================================================
// PESAN
// ============================================================
class CommMessage {
  final String id, roomId, senderId, senderName, text, type;
  final String? eventId, replyToId;
  final DateTime createdAt;
  final Map<String, List<String>> reactions; // emoji -> daftar id pengguna

  CommMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.type = 'text', // 'text' atau 'invite'
    this.eventId,
    this.replyToId,
    Map<String, List<String>>? reactions,
  }) : reactions = reactions ?? <String, List<String>>{};

  bool get isInvite => type == 'invite';

  int get reactionCount {
    var n = 0;
    for (final l in reactions.values) {
      n += l.length;
    }
    return n;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'type': type,
        'eventId': eventId,
        'replyToId': replyToId,
        'createdAt': createdAt.toIso8601String(),
        'reactions': reactions,
      };

  factory CommMessage.fromJson(Map<String, dynamic> j) {
    final raw = j['reactions'];
    final r = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        r[k.toString()] = List<String>.from(v as List);
      });
    }
    return CommMessage(
      id: j['id'] as String,
      roomId: j['roomId'] as String,
      senderId: j['senderId'] as String,
      senderName: (j['senderName'] ?? '') as String,
      text: (j['text'] ?? '') as String,
      type: (j['type'] ?? 'text') as String,
      eventId: j['eventId'] as String?,
      replyToId: j['replyToId'] as String?,
      createdAt: DateTime.parse(j['createdAt'] as String),
      reactions: r,
    );
  }
}

// ============================================================
// PENGUMUMAN RESMI (hanya admin)
// ============================================================
class Announcement {
  final String id, title, body, authorId, authorName;
  final bool important;
  final String? eventId;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.important = false,
    this.eventId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'authorId': authorId,
        'authorName': authorName,
        'important': important,
        'eventId': eventId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        authorId: (j['authorId'] ?? '') as String,
        authorName: (j['authorName'] ?? 'Admin') as String,
        important: (j['important'] ?? false) as bool,
        eventId: j['eventId'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ============================================================
// POLLING (satu suara per pengguna)
// ============================================================
class CommPoll {
  final String id, question, creatorId, creatorName;
  final List<String> options;
  final Map<String, int> votes; // userId -> index pilihan (1 pengguna = 1 suara)
  final DateTime createdAt, endsAt;

  CommPoll({
    required this.id,
    required this.question,
    required this.options,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.endsAt,
    Map<String, int>? votes,
  }) : votes = votes ?? <String, int>{};

  bool get active => DateTime.now().isBefore(endsAt);
  int get total => votes.length;

  int count(int i) {
    var n = 0;
    for (final v in votes.values) {
      if (v == i) n++;
    }
    return n;
  }

  int percent(int i) => total == 0 ? 0 : ((count(i) * 100) / total).round();

  String get statusText {
    if (!active) return 'Berakhir';
    final d = endsAt.difference(DateTime.now());
    if (d.inDays >= 1) return 'Aktif • ${d.inDays} hari lagi';
    if (d.inHours >= 1) return 'Aktif • ${d.inHours} jam lagi';
    return 'Aktif • segera berakhir';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'votes': votes,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'createdAt': createdAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
      };

  factory CommPoll.fromJson(Map<String, dynamic> j) {
    final v = <String, int>{};
    final raw = j['votes'];
    if (raw is Map) {
      raw.forEach((k, val) {
        v[k.toString()] = (val as num).toInt();
      });
    }
    return CommPoll(
      id: j['id'] as String,
      question: (j['question'] ?? '') as String,
      options: List<String>.from(j['options'] as List),
      creatorId: (j['creatorId'] ?? '') as String,
      creatorName: (j['creatorName'] ?? '') as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      endsAt: DateTime.parse(j['endsAt'] as String),
      votes: v,
    );
  }
}

// ============================================================
// LAPORAN PESAN
// ============================================================
class CommReport {
  final String id, messageId, reporterId, reporterName, reason, messageText, senderName, roomId;
  final DateTime createdAt;

  CommReport({
    required this.id,
    required this.messageId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.messageText,
    required this.senderName,
    required this.roomId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'messageId': messageId,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reason': reason,
        'messageText': messageText,
        'senderName': senderName,
        'roomId': roomId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommReport.fromJson(Map<String, dynamic> j) => CommReport(
        id: j['id'] as String,
        messageId: j['messageId'] as String,
        reporterId: (j['reporterId'] ?? '') as String,
        reporterName: (j['reporterName'] ?? '') as String,
        reason: (j['reason'] ?? '') as String,
        messageText: (j['messageText'] ?? '') as String,
        senderName: (j['senderName'] ?? '') as String,
        roomId: (j['roomId'] ?? 'umum') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
