import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final earned = s.earnedBadges;
    final locked = kBadges.where((b) => !s.isEarned(b)).toList()
      ..sort((a, b) => s.badgeProgress(b).compareTo(s.badgeProgress(a)));
    final next = locked.isEmpty ? null : locked.first;

    Widget stat(String v, String l) => Column(children: [
          Text(v, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text(l, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]);

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 20),
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
          child: Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const Text('Achievement',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                stat(fmtNum(s.totalPoints), 'Total Poin'),
                stat('${earned.length}', 'Badge'),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader('Badge Saya',
                onAll: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AllBadgesScreen()))),
            const SizedBox(height: 12),
            if (earned.isEmpty)
              Text('Belum ada badge. Ikuti kegiatan pertamamu!', style: TextStyle(color: muted(context)))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [for (final b in earned.take(3)) BadgeCircle(b, true)],
              ),
            const SizedBox(height: 20),
            if (next != null)
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Badge berikutnya: ${next.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(next.desc, style: TextStyle(fontSize: 12, color: muted(context))),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: s.badgeProgress(next), minHeight: 8, color: next.color,
                        backgroundColor: softOf(context)),
                  ),
                  const SizedBox(height: 4),
                  Text('${fmtNum(s.metricValue(next.metric))} / ${fmtNum(next.target)}',
                      style: const TextStyle(fontSize: 11)),
                ]),
              ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Peringkat Volunteer', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('#${s.rank}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    Text('dari ${fmtNum(AppState.leaderboardSize)} volunteer',
                        style: TextStyle(fontSize: 11, color: muted(context))),
                  ]),
                ),
                const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class BadgeCircle extends StatelessWidget {
  final BadgeDef b;
  final bool earned;
  const BadgeCircle(this.b, this.earned, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = earned ? b.color : Colors.grey;
    return SizedBox(
      width: 90,
      child: Column(children: [
        CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(.18),
            child: Icon(earned ? b.icon : Icons.lock_outline, color: color, size: 30)),
        const SizedBox(height: 6),
        Text(b.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
      ]),
    );
  }
}

class AllBadgesScreen extends StatelessWidget {
  const AllBadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Badge')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .95,
        children: [
          for (final b in kBadges)
            AppCard(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                BadgeCircle(b, s.isEarned(b)),
                const SizedBox(height: 4),
                Text(b.desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted(context))),
                const SizedBox(height: 6),
                if (s.isEarned(b))
                  StatusChip('Diperoleh', b.color)
                else
                  Text('${(s.badgeProgress(b) * 100).round()}%', style: const TextStyle(fontSize: 11)),
              ]),
            ),
        ],
      ),
    );
  }
}
