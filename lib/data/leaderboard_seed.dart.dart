import '../models/models.dart';
import '../models/gamification.dart.dart';
import 'seed_data.dart';

/// Prefix id untuk relawan awal. Relawan ini disimpan di penyimpanan lokal
/// (sama seperti akun lain) dan poinnya dihitung dari riwayat poin masing-masing.
/// Saat aplikasi memakai backend, data ini diganti dengan data dari server.
const String kSeedUserPrefix = 'u_seed_';

class SeedPack {
  final List<AppUser> users;
  final List<PointEntry> entries;
  SeedPack(this.users, this.entries);
}

class _SeedVol {
  final String name, city;
  final int pastPoints, pastEvents;
  // (berapa hari lalu, jenis: e = event, k = koordinator, a = apresiasi)
  final List<(int, String)> recent;
  const _SeedVol(this.name, this.city, this.pastPoints, this.pastEvents, this.recent);
}

const List<_SeedVol> _seedVols = [
  _SeedVol('Achmad Aldi', 'Surabaya', 10100, 215, [(0, 'e'), (1, 'e'), (2, 'e'), (3, 'a'), (14, 'e')]),
  _SeedVol('Siti Rahmawati', 'Gresik', 9700, 205, [(1, 'e'), (2, 'e'), (4, 'e'), (4, 'a'), (9, 'e'), (15, 'e')]),
  _SeedVol('Budi Santoso', 'Sidoarjo', 7100, 150, [(2, 'e'), (3, 'e'), (6, 'k'), (10, 'e'), (18, 'e')]),
  _SeedVol('Dewi Lestari', 'Malang', 5300, 110, [(1, 'e'), (5, 'e'), (11, 'e'), (19, 'e'), (26, 'e')]),
  _SeedVol('Deni Pratama', 'Surabaya', 3900, 80, [(3, 'e'), (7, 'e'), (13, 'e'), (21, 'e')]),
  _SeedVol('Rina Wijaya', 'Lamongan', 2700, 58, [(1, 'e'), (2, 'e'), (8, 'e'), (16, 'e')]),
  _SeedVol('Fajar Nugroho', 'Gresik', 2100, 44, [(4, 'e'), (6, 'e'), (12, 'e')]),
  _SeedVol('Maya Putri', 'Surabaya', 1500, 32, [(2, 'e'), (9, 'e'), (14, 'e'), (23, 'e')]),
  _SeedVol('Rizky Ramadhan', 'Mojokerto', 1180, 26, [(5, 'e'), (8, 'e'), (17, 'e')]),
  _SeedVol('Nadia Safitri', 'Surabaya', 940, 20, [(1, 'e'), (3, 'e'), (6, 'k'), (11, 'e')]),
  _SeedVol('Agus Salim', 'Gresik', 720, 15, [(6, 'e'), (13, 'e'), (24, 'e')]),
  _SeedVol('Linda Kusuma', 'Sidoarjo', 520, 11, [(2, 'e'), (10, 'e')]),
  _SeedVol('Hendra Wijaya', 'Malang', 360, 8, [(8, 'e'), (27, 'e')]),
  _SeedVol('Putri Ayu', 'Surabaya', 210, 5, [(4, 'e'), (15, 'e')]),
  _SeedVol('Doni Saputra', 'Gresik', 90, 2, [(12, 'e'), (21, 'e')]),
];

SeedPack buildSeedVolunteers() {
  final events = buildSeedEvents();
  final now = DateTime.now();
  final users = <AppUser>[];
  final entries = <PointEntry>[];

  for (var i = 0; i < _seedVols.length; i++) {
    final v = _seedVols[i];
    final uid = '$kSeedUserPrefix${i + 1}';
    users.add(AppUser(
      id: uid,
      name: v.name,
      email: '${v.name.toLowerCase().replaceAll(' ', '.')}@volunteer.local',
      password: 'locked-$uid',
      city: v.city,
      pastEvents: v.pastEvents,
      pastPoints: v.pastPoints,
    ));

    // Poin dari kegiatan sebelumnya
    final past = now.subtract(const Duration(days: 365));
    entries.add(PointEntry(
      id: 'p_open_$uid',
      userId: uid,
      title: 'Poin dari kegiatan sebelumnya',
      type: PointType.opening,
      points: v.pastPoints,
      date: past,
      createdAt: past,
      note: 'Akumulasi poin sebelum sistem riwayat aktif',
    ));

    // Aktivitas terbaru (agar filter mingguan / bulanan bermakna)
    for (var j = 0; j < v.recent.length; j++) {
      final (daysAgo, kind) = v.recent[j];
      final ev = events[(i * 3 + j) % events.length];
      final at = now.subtract(Duration(days: daysAgo, hours: 1 + (i * 3 + j) % 9));
      late String type;
      late int pts;
      late String note;
      if (kind == 'k') {
        type = PointType.coordinator;
        pts = kPointsCoordinator;
        note = 'Menjadi koordinator kegiatan';
      } else if (kind == 'a') {
        type = PointType.appreciation;
        pts = kPointsAppreciation;
        note = 'Apresiasi dari panitia';
      } else {
        type = PointType.event;
        pts = kPointsPerEvent;
        note = 'Kehadiran terverifikasi oleh panitia';
      }
      entries.add(PointEntry(
        id: 'p_seed_${i + 1}_$j',
        userId: uid,
        eventId: ev.id,
        title: ev.title,
        category: ev.category,
        type: type,
        points: pts,
        note: note,
        date: at,
        createdAt: at,
      ));
    }
  }
  return SeedPack(users, entries);
}
