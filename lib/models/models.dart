import 'package:flutter/material.dart';

enum RegStatus { registered, attended, cancelled }

class AppUser {
  final String id;
  String name, email, password, phone, city, bio;
  int pastEvents, pastHours, pastPoints, pastImpact;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone = '',
    this.city = '',
    this.bio = '',
    this.pastEvents = 0,
    this.pastHours = 0,
    this.pastPoints = 0,
    this.pastImpact = 0,
  });

  String get firstName {
    final p = name.trim().split(RegExp(r'\s+'));
    return p.first.isEmpty ? 'Relawan' : p.first;
  }

  String get initials {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.first.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'email': email, 'password': password,
        'phone': phone, 'city': city, 'bio': bio,
        'pastEvents': pastEvents, 'pastHours': pastHours,
        'pastPoints': pastPoints, 'pastImpact': pastImpact,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        password: j['password'] as String,
        phone: (j['phone'] ?? '') as String,
        city: (j['city'] ?? '') as String,
        bio: (j['bio'] ?? '') as String,
        pastEvents: (j['pastEvents'] ?? 0) as int,
        pastHours: (j['pastHours'] ?? 0) as int,
        pastPoints: (j['pastPoints'] ?? 0) as int,
        pastImpact: (j['pastImpact'] ?? 0) as int,
      );
}

class EventModel {
  final String id, title, category, organizer, location, description, image, time;
  final DateTime date;
  final int quota, baseParticipants, points, hours, impact;
  final List<String> tasks;
  final int price; // 0 = Gratis, > 0 = Berbayar

  EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.organizer,
    required this.location,
    required this.description,
    required this.image,
    required this.time,
    required this.date,
    required this.quota,
    required this.baseParticipants,
    required this.points,
    required this.hours,
    required this.impact,
    required this.tasks,
    this.price = 0,
  });

  bool get isFinished =>
      DateTime(date.year, date.month, date.day, 23, 59).isBefore(DateTime.now());

  bool get isPaid => price > 0;

  String get priceText => isPaid
      ? 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
      : 'Gratis';
}

class Registration {
  final String id, userId, eventId, code;
  RegStatus status;
  final DateTime createdAt;

  Registration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.code,
    required this.createdAt,
    this.status = RegStatus.registered,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'userId': userId, 'eventId': eventId, 'code': code,
        'status': status.name, 'createdAt': createdAt.toIso8601String(),
      };

  factory Registration.fromJson(Map<String, dynamic> j) => Registration(
        id: j['id'] as String,
        userId: j['userId'] as String,
        eventId: j['eventId'] as String,
        code: j['code'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: RegStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => RegStatus.registered),
      );
}

class Notif {
  final String id, userId, title, body, kind;
  final DateTime createdAt;
  bool read;

  Notif({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'userId': userId, 'title': title, 'body': body, 'kind': kind,
        'createdAt': createdAt.toIso8601String(), 'read': read,
      };

  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
        id: j['id'] as String,
        userId: j['userId'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        kind: j['kind'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        read: (j['read'] ?? false) as bool,
      );
}

class FeedbackItem {
  final String id, userId, eventTitle, text;
  final int rating;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.eventTitle,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'userId': userId, 'eventTitle': eventTitle, 'text': text,
        'rating': rating, 'createdAt': createdAt.toIso8601String(),
      };

  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
        id: j['id'] as String,
        userId: j['userId'] as String,
        eventTitle: j['eventTitle'] as String,
        text: j['text'] as String,
        rating: j['rating'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

enum BadgeMetric { events, hours, points, impact }

class BadgeDef {
  final String name, desc;
  final IconData icon;
  final Color color;
  final BadgeMetric metric;
  final int target;
  const BadgeDef(this.name, this.desc, this.icon, this.color, this.metric, this.target);
}

const List<BadgeDef> kBadges = [
  BadgeDef('Beginner', 'Ikuti 1 kegiatan', Icons.shield, Color(0xFF4A90D9), BadgeMetric.events, 1),
  BadgeDef('Active Volunteer', 'Ikuti 5 kegiatan', Icons.local_fire_department, Color(0xFFE8743B), BadgeMetric.events, 5),
  BadgeDef('Super Volunteer', 'Ikuti 10 kegiatan', Icons.workspace_premium, Color(0xFF8E5BD6), BadgeMetric.events, 10),
  BadgeDef('Dermawan', 'Kumpulkan 1.000 poin', Icons.savings, Color(0xFF16A34A), BadgeMetric.points, 1000),
  BadgeDef('Jam Terbang', 'Berkontribusi 40 jam', Icons.timer, Color(0xFF0891B2), BadgeMetric.hours, 40),
  BadgeDef('Penolong Hebat', 'Bantu 5.000 orang', Icons.diversity_3, Color(0xFFDB2777), BadgeMetric.impact, 5000),
  BadgeDef('Legend', 'Ikuti 25 kegiatan', Icons.military_tech, Color(0xFFF59E0B), BadgeMetric.events, 25),
];