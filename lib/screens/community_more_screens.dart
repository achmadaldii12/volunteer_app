import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/community.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/community_logic.dart';
import '../widgets/common.dart';
import 'community_room_screen.dart';
import 'community_widgets.dart';

// ============================================================
// DAFTAR ANGGOTA
// ============================================================
class CommunityMembersScreen extends StatefulWidget {
  const CommunityMembersScreen({super.key});

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final key = _q.trim().toLowerCase();
    final list = s.communityMembers.where((u) => key.isEmpty || u.name.toLowerCase().contains(key)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Anggota Komunitas')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Cari nama anggota...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: softOf(context),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${list.length} relawan', style: TextStyle(fontSize: 12, color: muted(context))),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(Icons.person_search, 'Anggota tidak ditemukan', 'Coba kata kunci lain.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final u = list[i];
                    final isMe = s.user?.id == u.id;
                    final blocked = s.isBlockedByMe(u.id);
                    return ListTile(
                      leading: CommAvatar(u.name, size: 44),
                      title: Row(children: [
                        Flexible(
                          child: Text(u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        if (isMe)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Kamu',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        if (blocked)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Diblokir',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                      ]),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          CommLevelChip(s.pointsOf(u.id)),
                          Text('${s.eventsOf(u.id)} event diikuti',
                              style: TextStyle(fontSize: 11, color: muted(context))),
                        ]),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showMemberProfile(context, u.id),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ============================================================
// PENGGUNA DIBLOKIR
// ============================================================
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.blockedUsers;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna Diblokir')),
      body: list.isEmpty
          ? const EmptyState(Icons.block, 'Belum ada pengguna diblokir',
              'Pengguna yang kamu blokir akan muncul di sini dan bisa dibuka kembali kapan saja.')
          : ListView(padding: const EdgeInsets.all(12), children: [
              for (final u in list)
                ListTile(
                  leading: CommAvatar(u.name, size: 42),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Pesannya disembunyikan', style: TextStyle(fontSize: 11, color: muted(context))),
                  trailing: OutlinedButton(
                    onPressed: () {
                      s.unblockUser(u.id);
                      commSnack(context, '${u.name} dibuka blokirnya');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('Buka Blokir'),
                  ),
                ),
            ]),
    );
  }
}

// ============================================================
// TINJAU LAPORAN (khusus admin)
// ============================================================
class CommunityReportsScreen extends StatelessWidget {
  const CommunityReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.pendingReports;

    Widget body;
    if (!s.isCommAdmin) {
      body = const EmptyState(Icons.lock_outline, 'Khusus admin', 'Hanya admin yang dapat meninjau laporan pesan.');
    } else if (list.isEmpty) {
      body = const EmptyState(Icons.verified_user_outlined, 'Tidak ada laporan',
          'Semua laporan sudah ditinjau. Komunitas aman terkendali!');
    } else {
      body = ListView(padding: const EdgeInsets.all(16), children: [
        for (final r in list)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF1F1B30) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: commA(AppColors.danger, .3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: commA(AppColors.danger, .12), borderRadius: BorderRadius.circular(8)),
                  child: Text(r.reason,
                      style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(timeAgo(r.createdAt), style: TextStyle(fontSize: 10.5, color: muted(context))),
              ]),
              const SizedBox(height: 10),
              Text('Pesan dari ${r.senderName} • ruang ${roomById(r.roomId).name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: softOf(context), borderRadius: BorderRadius.circular(10)),
                child: Text(r.messageText, maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.35)),
              ),
              const SizedBox(height: 6),
              Text('Dilaporkan oleh ${r.reporterName}', style: TextStyle(fontSize: 10.5, color: muted(context))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      s.dismissReport(r.id);
                      commSnack(context, 'Laporan diabaikan');
                    },
                    child: const Text('Abaikan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await confirmDialog(context,
                          title: 'Hapus pesan ini?',
                          message: 'Pesan yang melanggar akan dihapus permanen.',
                          yes: 'Hapus',
                          danger: true);
                      if (!ok || !context.mounted) return;
                      final err = s.deleteMessage(r.messageId);
                      commSnack(context, err ?? 'Pesan dihapus');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Hapus Pesan'),
                  ),
                ),
              ]),
            ]),
          ),
      ]);
    }

    return Scaffold(appBar: AppBar(title: const Text('Tinjau Laporan')), body: body);
  }
}

// ============================================================
// NOTIFIKASI KOMUNITAS
// ============================================================
class CommunityNotificationsScreen extends StatelessWidget {
  const CommunityNotificationsScreen({super.key});

  IconData _icon(String kind) {
    if (kind.startsWith('comm_announce')) return Icons.campaign_outlined;
    if (kind.startsWith('comm_reply')) return Icons.reply;
    if (kind.startsWith('comm_invite')) return Icons.event_available_outlined;
    return Icons.chat_bubble_outline;
  }

  void _open(BuildContext context, AppState s, Notif n) {
    s.markCommNotifRead(n.id);
    final idx = n.kind.indexOf(':');
    final type = idx < 0 ? n.kind : n.kind.substring(0, idx);
    final arg = idx < 0 ? '' : n.kind.substring(idx + 1);
    if (type == 'comm_announce') {
      Announcement? found;
      for (final a in s.announcements) {
        if (a.id == arg) found = a;
      }
      if (found == null) {
        commSnack(context, 'Pengumuman sudah dihapus');
      } else {
        showAnnouncementDetail(context, found);
      }
    } else if (arg.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityRoomScreen(arg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.commNotifs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Komunitas'),
        actions: [
          if (s.commNotifUnread > 0)
            TextButton(onPressed: s.markAllCommRead, child: const Text('Tandai dibaca')),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(Icons.notifications_off_outlined, 'Belum ada notifikasi',
              'Pesan baru, pengumuman, balasan, dan undangan event akan muncul di sini.')
          : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
              for (final n in items)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  onTap: () => _open(context, s, n),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(
                      backgroundColor: softOf(context),
                      child: Icon(_icon(n.kind), color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(timeAgo(n.createdAt), style: TextStyle(fontSize: 11, color: muted(context))),
                      ]),
                    ),
                    if (!n.read)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      ),
                  ]),
                ),
            ]),
    );
  }
}
