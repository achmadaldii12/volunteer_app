import 'package:flutter/material.dart';

class UserRank {
  final String userName;
  final int points;
  final int eventsCount;

  UserRank({
    required this.userName,
    required this.points,
    required this.eventsCount,
  });

  String get badgeTier {
    if (points >= 10000) return 'Expert 👑';
    if (points >= 5000) return 'Brilliant 🥇';
    if (points >= 2500) return 'Master 🥈';
    if (points >= 1000) return 'Cool 🥉';
    return 'Beginner 🌟';
  }
}

class AchievementScreen extends StatelessWidget {
  AchievementScreen({Key? key}) : super(key: key);

  final List<UserRank> _rankingList = [
    UserRank(userName: 'Achmad Aldi', points: 10450, eventsCount: 220),
    UserRank(userName: 'Siti Rahmawati', points: 5400, eventsCount: 115),
    UserRank(userName: 'Budi Santoso', points: 2800, eventsCount: 60),
    UserRank(userName: 'Deni Pratama', points: 1200, eventsCount: 28),
    UserRank(userName: 'Rina Wijaya', points: 850, eventsCount: 18),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = _rankingList.first; // Sudah menggunakan _rankingList yang benar

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement & Ranking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.emoji_events, size: 36, color: Colors.amber),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.userName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Badge: ${currentUser.badgeTier}',
                              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Poin: ${currentUser.points}', style: const TextStyle(color: Colors.white70)),
                        Text('Event Diikuti: ${currentUser.eventsCount}', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Syarat Level Badge (Max 50 Poin/Event):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(avatar: Text('🥉'), label: Text('Cool (1.000 Poin)')),
                Chip(avatar: Text('🥈'), label: Text('Master (2.500 Poin)')),
                Chip(avatar: Text('🥇'), label: Text('Brilliant (5.000 Poin)')),
                Chip(avatar: Text('👑'), label: Text('Expert (>=10.000 Poin)')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('🏆 Ranking Relawan Teratas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rankingList.length,
              itemBuilder: (context, index) {
                final user = _rankingList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey : Colors.brown.shade300),
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Badge: ${user.badgeTier}'),
                  trailing: Text('${user.points} Poin', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}