import 'package:flutter/material.dart';
import 'models.dart';

// ============================================================
// ATURAN POIN (sesuai ketentuan)
// ============================================================
const int kPointsPerEvent = 40; // menyelesaikan 1 event
const int kPointsCoordinator = 10; // menjadi koordinator kegiatan
const int kPointsBonus5Events = 50; // bonus tiap kelipatan 5 event
const int kPointsAppreciation = 10; // apresiasi dari panitia

class PointType {
  static const event = 'event';
  static const coordinator = 'coordinator';
  static const bonus = 'bonus';
  static const appreciation = 'appreciation';
  static const opening = 'opening'; // poin awal / riwayat sebelum fitur ini ada
}

// ============================================================
// RIWAYAT POIN (disimpan permanen)
// ============================================================
class PointEntry {
  final String id, userId, title, category, type, note;
  final String? eventId;
  final int points;
  final DateTime date; // tanggal kegiatan
  final DateTime createdAt; // kapan poin diberikan
  final bool verified; // true = sudah diverifikasi panitia

  PointEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.points,
    required this.date,
    required this.createdAt,
    this.eventId,
    this.category = '',
    this.note = '',
    this.verified = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'userId': userId, 'eventId': eventId, 'title': title,
        'category': category, 'type': type, 'note': note, 'points': points,
        'date': date.toIso8601String(), 'createdAt': createdAt.toIso8601String(),
        'verified': verified,
      };

  factory PointEntry.fromJson(Map<String, dynamic> j) => PointEntry(
        id: j['id'] as String,
        userId: j['userId'] as String,
        eventId: j['eventId'] as String?,
        title: (j['title'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        type: (j['type'] ?? PointType.event) as String,
        note: (j['note'] ?? '') as String,
        points: (j['points'] ?? 0) as int,
        date: DateTime.parse(j['date'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        verified: (j['verified'] ?? true) as bool,
      );
}

// ============================================================
// LEVEL
// ============================================================
class LevelDef {
  final String name;
  final int min;
  final int? max; // null = tanpa batas atas
  final IconData icon;
  final Color color;
  const LevelDef(this.name, this.min, this.max, this.icon, this.color);

  String get rangeText => max == null
      ? '${_n(min)}+ poin'
      : '${_n(min)} - ${_n(max!)} poin';

  static String _n(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

const List<LevelDef> kLevels = [
  LevelDef('Beginner', 0, 999, Icons.eco, Color(0xFF64748B)),
  LevelDef('Cool', 1000, 2499, Icons.ac_unit, Color(0xFF0EA5E9)),
  LevelDef('Master', 2500, 4999, Icons.military_tech, Color(0xFF8B5CF6)),
  LevelDef('Brilliant', 5000, 9999, Icons.auto_awesome, Color(0xFFF59E0B)),
  LevelDef('Expert', 10000, null, Icons.workspace_premium, Color(0xFFEAB308)),
];

int levelIndexOf(int points) {
  var idx = 0;
  for (var i = 0; i < kLevels.length; i++) {
    if (points >= kLevels[i].min) idx = i;
  }
  return idx;
}

LevelDef levelOf(int points) => kLevels[levelIndexOf(points)];

class LevelProgress {
  final LevelDef level;
  final LevelDef? next;
  final double progress; // 0.0 - 1.0
  final int remaining; // poin menuju level berikutnya
  const LevelProgress(this.level, this.next, this.progress, this.remaining);
}

LevelProgress levelProgress(int points) {
  final i = levelIndexOf(points);
  final cur = kLevels[i];
  if (i == kLevels.length - 1) return LevelProgress(cur, null, 1.0, 0);
  final nxt = kLevels[i + 1];
  final span = nxt.min - cur.min;
  final done = points - cur.min;
  return LevelProgress(cur, nxt, (done / span).clamp(0.0, 1.0).toDouble(), nxt.min - points);
}

// ============================================================
// ACHIEVEMENT / BADGE
// ============================================================
enum AchMetric { started, events, lingkungan, edukasi, points }

class AchBadge {
  final String id, name, desc;
  final IconData icon;
  final Color color;
  final AchMetric metric;
  final int target;
  const AchBadge(this.id, this.name, this.desc, this.icon, this.color, this.metric, this.target);
}

const List<AchBadge> kAchBadges = [
  AchBadge('beginner', 'Beginner', 'Mulai kegiatan volunteer pertamamu (mendaftar 1 kegiatan)',
      Icons.rocket_launch, Color(0xFF3B82F6), AchMetric.started, 1),
  AchBadge('first', 'First Volunteer', 'Selesaikan 1 event',
      Icons.military_tech, Color(0xFFF59E0B), AchMetric.events, 1),
  AchBadge('active', 'Active Volunteer', 'Selesaikan 5 event',
      Icons.groups, Color(0xFF2563EB), AchMetric.events, 5),
  AchBadge('super', 'Super Volunteer', 'Selesaikan 10 event',
      Icons.emoji_events, Color(0xFF8B5CF6), AchMetric.events, 10),
  AchBadge('eco', 'Eco Hero', 'Selesaikan 5 kegiatan bertema Lingkungan',
      Icons.eco, Color(0xFF16A34A), AchMetric.lingkungan, 5),
  AchBadge('edu', 'Education Hero', 'Selesaikan 5 kegiatan bertema Edukasi',
      Icons.school, Color(0xFF0EA5E9), AchMetric.edukasi, 5),
  AchBadge('expert', 'Expert', 'Capai minimal 10.000 poin',
      Icons.workspace_premium, Color(0xFFEAB308), AchMetric.points, 10000),
];

// ============================================================
// RANKING
// ============================================================
enum RankPeriod { weekly, monthly, allTime }

extension RankPeriodX on RankPeriod {
  String get label {
    switch (this) {
      case RankPeriod.weekly:
        return 'Mingguan';
      case RankPeriod.monthly:
        return 'Bulanan';
      case RankPeriod.allTime:
        return 'Sepanjang Waktu';
    }
  }
}

class RankEntry {
  final AppUser user;
  final int points; // poin pada periode terpilih
  final int totalPoints; // poin sepanjang waktu (untuk level)
  final int events; // event diselesaikan pada periode terpilih
  final int rank;
  final bool isMe;
  const RankEntry({
    required this.user,
    required this.points,
    required this.totalPoints,
    required this.events,
    required this.rank,
    required this.isMe,
  });

  RankEntry withRank(int r) => RankEntry(
      user: user, points: points, totalPoints: totalPoints, events: events, rank: r, isMe: isMe);
}

// ============================================================
// VOLUNTEER OF THE MONTH
// ============================================================
class MonthlyStar {
  final AppUser user;
  final int points, events, activeWeeks, contribution, score;
  final bool isMe;
  const MonthlyStar({
    required this.user,
    required this.points,
    required this.events,
    required this.activeWeeks,
    required this.contribution,
    required this.score,
    required this.isMe,
  });
}

class MonthlyBoard {
  final DateTime month;
  final List<MonthlyStar> stars; // urut dari terbaik
  const MonthlyBoard(this.month, this.stars);
  MonthlyStar? get winner => stars.isEmpty ? null : stars.first;
}

// ============================================================
// POPUP PENGHARGAAN
// ============================================================
enum CelebrationKind { points, badge, level }

class Celebration {
  final CelebrationKind kind;
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final int points;
  const Celebration({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.points = 0,
  });
}
