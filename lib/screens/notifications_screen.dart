import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/app_state.dart';
import '../providers/profile_store.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String kind) {
    switch (kind) {
      case 'register':
        return Icons.check_circle_outline;
      case 'cancel':
        return Icons.cancel_outlined;
      case 'attend':
        return Icons.how_to_reg_outlined;
      case 'badge':
        return Icons.emoji_events_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final uid = s.user?.id;
    // Notifikasi yang dimatikan di Pengaturan Notifikasi tidak ditampilkan
    final items = s.myNotifs.where((n) => uid == null || st.allows(uid, n.kind)).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Row(children: [
          const Expanded(child: Text('Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          if (s.unreadCount > 0)
            TextButton(onPressed: s.markAllRead, child: const Text('Tandai dibaca')),
        ]),
      ),
      Expanded(
        child: items.isEmpty
            ? const EmptyState(Icons.notifications_off_outlined, 'Belum ada notifikasi',
                'Info pendaftaran dan pencapaianmu akan muncul di sini.')
            : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                for (final n in items)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    onTap: () => s.markRead(n.id),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(
                          backgroundColor: softOf(context),
                          child: Icon(_icon(n.kind), color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(n.body, style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(timeAgo(n.createdAt), style: TextStyle(fontSize: 11, color: muted(context))),
                        ]),
                      ),
                      if (!n.read)
                        Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                    ]),
                  ),
              ]),
      ),
    ]);
  }
}