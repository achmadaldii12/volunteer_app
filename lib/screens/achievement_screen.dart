import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

const _redPrimary = Color(0xFFD32F2F); // Warna merah utama
const _redLight = Color(0xFFEF5350);  // Warna merah muda / gradasi

// ============================================================ helper format
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _n(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}

// ================================================================== LEVEL
class _Level {
  final int level;
  final String name;
  final int minPoints;
  const _Level(this.level, this.name, this.minPoints);
}

const _levels = <_Level>[
  _Level(1, 'Pemula', 0),
  _Level(2, 'Aktif', 300),
  _Level(3, 'Berpengalaman', 800),
  _Level(4, 'Brilliant', 1500),
  _Level(5, 'Expert', 2500),
  _Level(6, 'Master', 4000),
  _Level(7, 'Legend', 6000),
];

_Level _levelOf(int points) {
  var cur = _levels.first;
  for (final l in _levels) {
    if (points >= l.minPoints) cur = l;
  }
  return cur;
}

_Level? _nextOf(_Level l) => l.level >= _levels.length ? null : _levels[l.level];

// ============================================================= ACHIEVEMENT
int _attendedInCategory(AppState s, String category) {
  var n = 0;
  for (final r in s.attendedRegs) {
    final e = s.eventById(r.eventId);
    if (e != null && e.category == category) n++;
  }
  return n;
}

class _Ach {
  final String name, desc, unit;
  final IconData icon;
  final Color color;
  final int target;
  final int Function(AppState) value;
  _Ach(this.name, this.desc, this.unit, this.icon, this.color, this.target, this.value);
}

final List<_Ach> _achs = [
  _Ach('First Volunteer', 'Ikuti kegiatan pertamamu', 'kegiatan', Icons.military_tech,
      const Color(0xFFF59E0B), 1, (s) => s.totalEvents),
  _Ach('Eco Hero', 'Hadiri 1 kegiatan kategori Lingkungan', 'kegiatan', Icons.eco,
      const Color(0xFF16A34A), 1, (s) => _attendedInCategory(s, 'Lingkungan')),
  _Ach('Active Volunteer', 'Ikuti 5 kegiatan', 'kegiatan', Icons.groups,
      const Color(0xFF2196F3), 5, (s) => s.totalEvents),
  _Ach('Super Volunteer', 'Ikuti 10 kegiatan', 'kegiatan', Icons.emoji_events,
      const Color(0xFF9C27B0), 10, (s) => s.totalEvents),
  _Ach('Expert', 'Kumpulkan 2.500 poin (Level 5)', 'poin', Icons.workspace_premium,
      const Color(0xFFE8743B), 2500, (s) => s.totalPoints),
  _Ach('Jam Terbang', 'Berkontribusi selama 40 jam', 'jam', Icons.timer,
      const Color(0xFF0891B2), 40, (s) => s.totalHours),
  _Ach('Dermawan', 'Kumpulkan 1.000 poin', 'poin', Icons.savings,
      const Color(0xFF14B8A6), 1000, (s) => s.totalPoints),
  _Ach('Penolong Hebat', 'Bantu 5.000 orang', 'orang', Icons.diversity_3,
      const Color(0xFFDB2777), 5000, (s) => s.totalImpact),
];

// ================================================================ POIN/RANK
int _userPoints(AppState s, AppUser u, {int? withinDays}) {
  var total = withinDays == null ? u.pastPoints : 0;
  final now = DateTime.now();
  for (final r in s.regs) {
    if (r.userId != u.id || r.status != RegStatus.attended) continue;
    final e = s.eventById(r.eventId);
    if (e == null) continue;
    if (withinDays != null && now.difference(e.date).inDays > withinDays) continue;
    total += e.points;
  }
  return total;
}

int _streak(AppState s) {
  final u = s.user;
  if (u == null) return 0;
  DateTime day0(DateTime x) => DateTime(x.year, x.month, x.day);
  final days = <DateTime>{};
  for (final r in s.regs) {
    if (r.userId != u.id || r.status == RegStatus.cancelled) continue;
    days.add(day0(r.createdAt));
    if (r.status == RegStatus.attended) {
      final e = s.eventById(r.eventId);
      if (e != null) days.add(day0(e.date));
    }
  }
  var d = day0(DateTime.now());
  if (!days.contains(d)) d = DateTime(d.year, d.month, d.day - 1);
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

class _Rival {
  final String name;
  final int all, month, week;
  const _Rival(this.name, this.all, this.month, this.week);
}

const _rivals = <_Rival>[
  _Rival('Siti Rahmawati', 5400, 900, 250),
  _Rival('Budi Santoso', 2800, 600, 180),
  _Rival('Dewi Lestari', 1900, 420, 120),
  _Rival('Rizky Pratama', 1450, 300, 90),
  _Rival('Nadia Putri', 980, 260, 100),
  _Rival('Fajar Nugroho', 760, 150, 60),
  _Rival('Maya Anggraini', 520, 120, 40),
  _Rival('Andi Wijaya', 310, 80, 20),
];

class _Entry {
  final String name;
  final int points;
  final int all;
  final bool me;
  _Entry(this.name, this.points, this.all, this.me);
}

// =================================================================== SCREEN
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});
  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  int period = 0; // 0 = Mingguan, 1 = Bulanan, 2 = Sepanjang Waktu
  final _boardKey = GlobalKey();

  static const _periods = ['Mingguan', 'Bulanan', 'Sepanjang Waktu'];

  List<_Entry> _entries(AppState s) {
    final days = period == 0 ? 7 : (period == 1 ? 30 : null);
    final list = <_Entry>[];
    for (final u in s.users) {
      list.add(_Entry(u.name, _userPoints(s, u, withinDays: days), _userPoints(s, u),
          u.id == s.user?.id));
    }
    for (final r in _rivals) {
      list.add(_Entry(r.name, period == 0 ? r.week : (period == 1 ? r.month : r.all), r.all, false));
    }
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  void _toLeaderboard() {
    final c = _boardKey.currentContext;
    if (c != null) {
      Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    }
  }

  void _showAch(AppState s, _Ach a) {
    final v = a.value(s);
    final done = v >= a.target;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          CircleAvatar(
              backgroundColor: (done ? a.color : Colors.grey).withOpacity(.18),
              child: Icon(done ? a.icon : Icons.lock_outline, color: done ? a.color : Colors.grey)),
          const SizedBox(width: 12),
          Expanded(child: Text(a.name)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.desc),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: (v / a.target).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                color: a.color,
                backgroundColor: Colors.grey.shade200),
          ),
          const SizedBox(height: 6),
          Text(done ? 'Achievement terbuka 🎉' : '${_n(v)} / ${_n(a.target)} ${a.unit}',
              style: const TextStyle(fontSize: 12)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _showAllAch(AppState s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .95,
        builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(16), children: [
          const Center(
              child: Text('Semua Achievement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          for (final a in _achs)
            Builder(builder: (_) {
              final v = a.value(s);
              final done = v >= a.target;
              return ListTile(
                leading: CircleAvatar(
                    backgroundColor: (done ? a.color : Colors.grey).withOpacity(.18),
                    child: Icon(done ? a.icon : Icons.lock_outline, color: done ? a.color : Colors.grey)),
                title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.desc, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                      value: (v / a.target).clamp(0.0, 1.0).toDouble(),
                      color: a.color,
                      backgroundColor: Colors.grey.shade200),
                ]),
                trailing: done
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Text('${((v / a.target).clamp(0.0, 1.0) * 100).round()}%'),
              );
            }),
        ]),
      ),
    );
  }

  void _explain(String title, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
      ),
    );
  }

  // Helper untuk membuat inisial nama dan warna latar belakang avatar profil
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _getAvatarColor(String name) {
    final hash = name.hashCode.abs();
    final colors = [
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green.shade700,
      Colors.deepOrange,
      Colors.purple,
      Colors.pink,
      Colors.blueGrey,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    final points = s.totalPoints;
    final level = _levelOf(points);
    final next = _nextOf(level);
    final progress = next == null
        ? 1.0
        : ((points - level.minPoints) / (next.minPoints - level.minPoints)).clamp(0.0, 1.0).toDouble();

    final entries = _entries(s);
    final myIndex = entries.indexWhere((e) => e.me);
    final shown = entries.take(10).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: _redPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Achievement & Ranking',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Lihat leaderboard',
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            onPressed: _toLeaderboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ------------------------------------------------ kartu profil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                  colors: [_redLight, _redPrimary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(children: [
              Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(u?.initials ?? '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _redPrimary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u?.name ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('${level.name} | Level ${level.level}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                const Expanded(
                    child: Text('Progress menuju level berikutnya',
                        style: TextStyle(color: Colors.white70, fontSize: 13))),
                Text('${(progress * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: progress, minHeight: 8, color: Colors.amber, backgroundColor: Colors.white24),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  next == null
                      ? 'Level maksimal tercapai 🎉'
                      : '${_n(next.minPoints - points)} poin lagi menuju Level ${next.level} (${next.name})',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(children: [
                  _stat(Icons.stars, _n(points), 'Total Poin',
                      () => _explain('Total Poin', 'Poin didapat setiap kali kehadiranmu pada sebuah kegiatan tercatat. Poin menentukan level dan peringkatmu.')),
                  const VerticalDivider(color: Colors.white24, width: 1, thickness: 1),
                  _stat(Icons.event_available, '${s.totalEvents}', 'Event Diikuti',
                      () => _explain('Event Diikuti', 'Jumlah kegiatan yang sudah kamu hadiri, termasuk riwayat sebelum memakai aplikasi.')),
                  const VerticalDivider(color: Colors.white24, width: 1, thickness: 1),
                  _stat(Icons.local_fire_department, '${_streak(s)}', 'Streak',
                      () => _explain('Streak', 'Jumlah hari berturut-turut kamu aktif, yaitu mendaftar atau menghadiri kegiatan. Aktiflah setiap hari agar streak bertambah!')),
                ]),
              ),
            ]),
          ),

          // ----------------------------------------- koleksi achievement
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Koleksi Achievement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => _showAllAch(s),
              child: const Text('Lihat Semua >',
                  style: TextStyle(color: _redPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final a in _achs.take(5)) _achItem(s, a),
            ]),
          ),

          // ----------------------------------------------- leaderboard
          SizedBox(height: 26, key: _boardKey),
          Row(children: [
            const Expanded(
                child: Text('Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < _periods.length; i++) _pill(i),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          if (myIndex >= 0)
            Text('Peringkatmu: #${myIndex + 1} dari ${entries.length} (${_periods[period]})',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(children: [
              for (var i = 0; i < shown.length; i++) ...[
                _row(i + 1, shown[i]),
                if (i < shown.length - 1) const Divider(height: 1),
              ],
              if (myIndex >= 10) ...[
                const Divider(height: 1),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('• • •', style: TextStyle(color: Colors.grey))),
                _row(myIndex + 1, entries[myIndex]),
              ],
            ]),
          ),

          // -------------------------------------------------- POSISI KAMU
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _redLight.withOpacity(0.4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _redPrimary,
                child: Text(u?.initials ?? 'AS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#${myIndex >= 0 ? myIndex + 1 : '-'} ${u?.name ?? 'Achmad Aldi'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(myIndex == 0 ? 'Kamu berada di peringkat pertama! 🌟' : 'Kamu berada di peringkat #${myIndex >= 0 ? myIndex + 1 : '-'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ),
              Text('${_n(points)} Poin',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _redPrimary)),
            ]),
          ),

          // -------------------------------------------------- VOLUNTEER OF THE MONTH
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volunteer of The Month',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber)),
                  GestureDetector(
                    onTap: () => _explain('Volunteer of the Month', 'Andi Pratama terpilih sebagai relawan terbaik bulan ini atas dedikasi luar biasanya.'),
                    child: Text('Lihat Detail >',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.amber.shade700,
                    child: const Text('AP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Andi Pratama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.star, size: 13, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('8.500 Poin  |  ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Icon(Icons.event, size: 13, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('15 Event', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ]),
                ),
              ]),
            ]),
          ),

          // -------------------------------------------------- riwayat poin
          const SizedBox(height: 26),
          const Text('Riwayat Poin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _history(s),
        ]),
      ),
    );
  }

  // ------------------------------------------------------------- sub widget
  Widget _stat(IconData icon, String value, String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _achItem(AppState s, _Ach a) {
    final done = a.value(s) >= a.target;
    final color = done ? a.color : Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showAch(s, a),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(.16),
              child: Icon(done ? a.icon : Icons.lock, color: color, size: 30)),
          const SizedBox(height: 6),
          Text(a.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: done ? null : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _pill(int i) {
    final sel = period == i;
    return GestureDetector(
      onTap: () => setState(() => period = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: sel ? _redPrimary : Colors.transparent, borderRadius: BorderRadius.circular(18)),
        child: Text(_periods[i],
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : Colors.black54)),
      ),
    );
  }

  Widget _row(int rank, _Entry e) {
    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank == 2
            ? const Color(0xFF94A3B8)
            : rank == 3
                ? const Color(0xFFB45309)
                : Colors.black45;
    
    final avatarBg = e.me ? _redPrimary : _getAvatarColor(e.name);
    final initials = _getInitials(e.name);

    return Container(
      color: e.me ? _redPrimary.withOpacity(.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(
            width: 28,
            child: rank <= 3
                ? Icon(Icons.emoji_events, color: rankColor, size: 22)
                : Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rankColor))),
        const SizedBox(width: 8),
        CircleAvatar(
            radius: 22,
            backgroundColor: avatarBg,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.me ? '${e.name} (Kamu)' : e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: e.me ? FontWeight.bold : FontWeight.w600)),
            Text(_levelOf(e.all).name, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        Text('${_n(e.points)} Poin',
            style: const TextStyle(color: _redPrimary, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _history(AppState s) {
    final u = s.user;
    final rows = <Widget>[];
    for (final r in s.attendedRegs) {
      final e = s.eventById(r.eventId);
      if (e == null) continue;
      rows.add(_HistoryRow(e.title, _date(e.date), e.points));
    }
    if (u != null && u.pastPoints > 0) {
      rows.add(_HistoryRow('Poin dari riwayat sebelumnya', '${u.pastEvents} kegiatan', u.pastPoints));
    }
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Text(
            'Belum ada poin. Hadiri kegiatan pertamamu untuk mulai mengumpulkan poin!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: rows),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String title, date;
  final int points;
  const _HistoryRow(this.title, this.date, this.points);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.add_task, color: Colors.green, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          Text('+$points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
        ]),
      );
}