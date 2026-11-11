import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  int _leaderboardTab = 0; // 0: Mingguan, 1: Bulanan, 2: Sepanjang Waktu

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement & Ranking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.emoji_events, color: Colors.amber.shade300, size: 26),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- 1. Kartu Profil & Level (Nuansa Biru Elegan) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3F51B5).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                        ),
                        Icon(Icons.workspace_premium, color: Colors.amber.shade300, size: 28),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.user?.firstName ?? 'Achmad Aldi',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text('Expert | Level 5', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Progress menuju level berikutnya', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.85,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(Icons.stars, fmtNum(s.totalPoints), 'Total Poin'),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _StatItem(Icons.event_note, '${s.totalEvents}', 'Event Diikuti'),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _StatItem(Icons.local_fire_department, '12', 'Streak'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. Koleksi Achievement ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Koleksi Achievement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat Semua >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: const [
                _BadgeAvatar(Icons.military_tech, 'First Volunteer', Colors.amber, true),
                _BadgeAvatar(Icons.eco, 'Eco Hero', Colors.green, true),
                _BadgeAvatar(Icons.groups, 'Active Volunteer', Colors.blue, true),
                _BadgeAvatar(Icons.emoji_events, 'Super Volunteer', Colors.purple, true),
                _BadgeAvatar(Icons.lock, 'Expert', Colors.grey, false),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 3. Leaderboard dengan Filter Tab ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Leaderboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _LeaderboardTabButton('Mingguan', 0, _leaderboardTab, (val) => setState(() => _leaderboardTab = val)),
                    _LeaderboardTabButton('Bulanan', 1, _leaderboardTab, (val) => setState(() => _leaderboardTab = val)),
                    _LeaderboardTabButton('Sepanjang Waktu', 2, _leaderboardTab, (val) => setState(() => _leaderboardTab = val)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: [
                _LeaderboardRow('1', 'Achmad Aldi', 'Expert', '${fmtNum(s.totalPoints)} Poin', Colors.amber),
                const Divider(height: 20),
                _LeaderboardRow('2', 'Siti Rahmawati', 'Brilliant', '5.400 Poin', Colors.grey.shade400),
                const Divider(height: 20),
                _LeaderboardRow('3', 'Budi Santoso', 'Master', '2.800 Poin', Colors.brown.shade300),
                const Divider(height: 20),
                _LeaderboardRow('4', 'Deni Pratama', 'Cool', '1.200 Poin', Colors.transparent),
                const Divider(height: 20),
                _LeaderboardRow('5', 'Rina Wijaya', 'Beginner', '850 Poin', Colors.transparent),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 4. Posisi Kamu ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#1 Achmad Aldi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Kamu berada di peringkat pertama!', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('${fmtNum(s.totalPoints)} Poin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3F51B5))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 5. Volunteer of the Month ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Volunteer of The Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber)),
                    Text('Lihat Detail >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: Colors.amber, child: Icon(Icons.person, color: Colors.white, size: 32)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Andi Pratama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, size: 13, color: Colors.amber),
                              SizedBox(width: 4),
                              Text('8.500 Poin  |  ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Icon(Icons.event, size: 13, color: Colors.grey),
                              SizedBox(width: 4),
                              Text('15 Event', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 6. Riwayat Perolehan Poin ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Riwayat Perolehan Poin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat Semua >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HistoryRow('Festival Relawan 2025', '12 Okt 2025 • Event Selesai', '+40 Poin'),
          const Divider(height: 16),
          _HistoryRow('Aksi Bersih Lingkungan', '5 Okt 2025 • Event Selesai', '+50 Poin'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _BadgeAvatar extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool unlocked;

  const _BadgeAvatar(this.icon, this.label, this.color, this.unlocked);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: unlocked ? color.withOpacity(0.2) : Colors.grey.shade200,
            child: Icon(icon, color: unlocked ? color : Colors.grey, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: unlocked ? Colors.black87 : Colors.grey)),
        ],
      ),
    );
  }
}

class _LeaderboardTabButton extends StatelessWidget {
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LeaderboardTabButton(this.label, this.index, this.currentIndex, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3F51B5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final String rank;
  final String name;
  final String title;
  final String points;
  final Color badgeColor;

  const _LeaderboardRow(this.rank, this.name, this.title, this.points, this.badgeColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(rank, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: badgeColor != Colors.transparent ? Colors.amber.shade800 : Colors.grey)),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(radius: 18, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 20, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(points, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5))),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String title;
  final String date;
  final String points;

  const _HistoryRow(this.title, this.date, this.points);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.verified_outlined, color: Colors.green, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(date, style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Text(points, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
      ],
    );
  }
}