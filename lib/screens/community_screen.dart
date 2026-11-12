import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/community.dart';
import '../providers/app_state.dart';
import '../providers/community_logic.dart';
import 'community_more_screens.dart';
import 'community_room_screen.dart';
import 'community_widgets.dart';

// ============================================================
// BERANDA KOMUNITAS RELAWAN
// Pengumuman, ruang diskusi, polling, anggota, diskusi terbaru, dan kirim pesan cepat.
// ============================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final PageController _pageCtrl = PageController();
  String _roomId = 'umum';
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Color _surface(BuildContext c) => Theme.of(c).colorScheme.surface;
  Color _border(BuildContext c) => Colors.grey.withAlpha(60);

  void _openRoom(String roomId, {String? replyToId}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityRoomScreen(roomId, replyToId: replyToId)),
    );
  }

  // ------------------------------------------------------------ aksi
  void _showRules() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: const [
          Icon(Icons.shield_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Aturan Komunitas'),
        ]),
        content: const SingleChildScrollView(
          child: Text(
            '1. Hormati sesama relawan, jaga kesantunan dalam berdiskusi.\n'
            '2. Dilarang spam, promosi, SARA, dan ujaran kebencian.\n'
            '3. Jangan membagikan data pribadi (nomor telepon, alamat, dan sejenisnya).\n'
            '4. Gunakan fitur Laporkan atau Blokir bila menemukan pelanggaran.\n'
            '5. Pengumuman resmi hanya dibuat dan dihapus oleh admin.\n'
            '6. Pelanggaran berulang dapat dikenakan sanksi.',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
      ),
    );
  }

  void _onMenu(String v) {
    final s = context.read<AppState>();
    switch (v) {
      case 'members':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityMembersScreen()));
        break;
      case 'blocked':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
        break;
      case 'reports':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityReportsScreen()));
        break;
      case 'announce':
        _createAnnouncement();
        break;
      case 'admin':
        s.toggleCommAdmin();
        commSnack(context, s.isCommAdmin ? 'Mode admin aktif (demo)' : 'Mode admin dimatikan');
        break;
      case 'rules':
        _showRules();
        break;
    }
  }

  Future<void> _invite() async {
    final e = await pickEvent(context);
    if (e == null || !mounted) return;
    final s = context.read<AppState>();
    final note = _ctrl.text.trim().isEmpty ? 'Yuk ikutan kegiatan relawan bersama!' : _ctrl.text;
    final err = s.sendRoomMessage(roomId: _roomId, text: note, eventId: e.id);
    if (err != null) {
      commSnack(context, err);
      return;
    }
    _ctrl.clear();
    _afterSend();
  }

  Future<void> _emoji() async {
    final e = await showEmojiPicker(context);
    if (e == null || !mounted) return;
    _ctrl.text = '${_ctrl.text}$e';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  void _send() {
    final s = context.read<AppState>();
    final err = s.sendRoomMessage(roomId: _roomId, text: _ctrl.text);
    if (err != null) {
      commSnack(context, err);
      return;
    }
    _ctrl.clear();
    _afterSend();
  }

  void _afterSend() {
    FocusScope.of(context).unfocus();
    final room = roomById(_roomId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Terkirim ke ruang ${room.name}'),
      action: SnackBarAction(label: 'Buka', onPressed: () => _openRoom(room.id)),
    ));
  }

  void _createAnnouncement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreateAnnouncementSheet(),
      ),
    );
  }

  void _createPoll() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreatePollSheet(),
      ),
    );
  }

  void _showAllPolls() {
    final s = context.read<AppState>();
    final polls = s.sortedPolls;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        maxChildSize: .95,
        minChildSize: .4,
        builder: (c, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            const Text('Semua Polling', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Satu suara untuk setiap polling.', style: TextStyle(fontSize: 12, color: muted(context))),
            const SizedBox(height: 14),
            for (final p in polls)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(context)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(p.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    _StatusChip(p.statusText, p.active),
                  ]),
                  const SizedBox(height: 10),
                  PollOptions(p),
                  Text('${p.total} suara • dibuat ${p.creatorName}',
                      style: TextStyle(fontSize: 11, color: muted(context))),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  void _showAllRooms() {
    final s = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Semua Ruang Diskusi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            for (final r in kRooms)
              Builder(builder: (_) {
                final ms = s.roomMessages(r.id);
                final last = ms.isEmpty ? null : ms.last;
                final unread = s.unreadInRoom(r.id);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: commA(r.color, .15),
                    child: Icon(r.icon, color: r.color),
                  ),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    last == null ? r.desc : '${last.senderName}: ${last.isInvite ? '📅 Undangan event' : last.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: unread > 0 ? _Badge(unread) : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openRoom(r.id);
                  },
                );
              }),
          ]),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final notifCount = s.commNotifUnread;
    final reportCount = s.commReports.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunitas Relawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Aturan komunitas',
            onPressed: _showRules,
          ),
          Stack(alignment: Alignment.center, children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Notifikasi komunitas',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityNotificationsScreen()),
              ),
            ),
            if (notifCount > 0)
              Positioned(right: 6, top: 6, child: IgnorePointer(child: _Badge(notifCount))),
          ]),
          PopupMenuButton<String>(
            onSelected: _onMenu,
            itemBuilder: (_) => [
              const PopupMenuItem<String>(value: 'members', child: Text('Daftar Anggota')),
              const PopupMenuItem<String>(value: 'blocked', child: Text('Pengguna Diblokir')),
              if (s.isCommAdmin) const PopupMenuItem<String>(value: 'announce', child: Text('Buat Pengumuman')),
              if (s.isCommAdmin)
                PopupMenuItem<String>(value: 'reports', child: Text('Tinjau Laporan ($reportCount)')),
              PopupMenuItem<String>(
                value: 'admin',
                child: Text(s.isCommAdmin ? 'Mode Admin (demo): AKTIF' : 'Mode Admin (demo): mati'),
              ),
              const PopupMenuItem<String>(value: 'rules', child: Text('Aturan Komunitas')),
            ],
          ),
        ],
      ),
      body: s.user == null
          ? const Center(child: Text('Silakan login untuk membuka komunitas'))
          : Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.only(bottom: 12), children: [
                  _rulesBanner(context),
                  _announcements(context, s),
                  CommSectionHeader('Ruang Diskusi', action: 'Lihat Semua', onAction: _showAllRooms),
                  _rooms(context, s),
                  _pollCard(context, s),
                  CommSectionHeader('Anggota Relawan', action: 'Lihat Semua', onAction: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityMembersScreen()));
                  }),
                  _members(context, s),
                  CommSectionHeader('Diskusi Terbaru', action: 'Lihat Semua', onAction: _showAllRooms),
                  _latest(context, s),
                ]),
              ),
              _composer(context),
            ]),
    );
  }

  // ------------------------------------------------------- banner aturan
  Widget _rulesBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF3A3115) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Jaga kesantunan berinteraksi. Klik ikon (i) untuk membaca pedoman.',
              style: TextStyle(fontSize: 12, height: 1.3)),
        ),
        InkWell(onTap: _showRules, child: const Icon(Icons.chevron_right, size: 20)),
      ]),
    );
  }

  // --------------------------------------------------------- pengumuman
  Widget _announcements(BuildContext context, AppState s) {
    final anns = s.sortedAnnouncements;
    final cur = _page >= anns.length ? 0 : _page;
    return Column(children: [
      if (s.isCommAdmin)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _createAnnouncement,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Buat Pengumuman'),
            ),
          ),
        ),
      if (anns.isNotEmpty) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 176,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: anns.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (ctx, i) => _AnnounceCard(anns[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < anns.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == cur ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == cur ? AppColors.primary : Colors.grey.withAlpha(110),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ]),
      ],
    ]);
  }

  // ------------------------------------------------------- ruang diskusi
  Widget _rooms(BuildContext context, AppState s) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: kRooms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 84,
      ),
      itemBuilder: (ctx, i) {
        final r = kRooms[i];
        final unread = s.unreadInRoom(r.id);
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRoom(r.id),
          child: Stack(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: commA(r.color, isDark(context) ? .16 : .09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: commA(r.color, .35)),
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: commA(r.color, .18), shape: BoxShape.circle),
                  child: Icon(r.icon, color: r.color, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${s.roomMemberCount(r.id)} anggota',
                        style: TextStyle(fontSize: 11, color: muted(context))),
                  ]),
                ),
              ]),
            ),
            if (unread > 0) Positioned(right: 8, top: 8, child: _Badge(unread)),
          ]),
        );
      },
    );
  }

  // --------------------------------------------------------------- polling
  Widget _pollCard(BuildContext context, AppState s) {
    final polls = s.sortedPolls;
    final p = polls.isEmpty ? null : polls.first;
    final my = p == null ? null : s.myVote(p);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Polling Komunitas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          if (p != null) _StatusChip(p.statusText, p.active),
        ]),
        const SizedBox(height: 10),
        if (p == null)
          Text('Belum ada polling. Buat polling pertama untuk komunitas!',
              style: TextStyle(fontSize: 13, color: muted(context)))
        else ...[
          Text(p.question, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 10),
          PollOptions(p),
          Text(
            '${p.total} suara • dibuat ${p.creatorName}${my != null ? ' • suaramu tercatat' : ''}',
            style: TextStyle(fontSize: 11, color: muted(context)),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (p != null)
            Expanded(
              child: OutlinedButton(
                onPressed: _showAllPolls,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Lihat Hasil'),
              ),
            ),
          if (p != null) const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _createPoll,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Polling'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // --------------------------------------------------------------- anggota
  Widget _members(BuildContext context, AppState s) {
    final list = s.communityMembers.take(10).toList();
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final u = list[i];
          final first = u.name.trim().split(' ').first;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showMemberProfile(context, u.id),
            child: SizedBox(
              width: 70,
              child: Column(children: [
                CommAvatar(u.name, size: 52),
                const SizedBox(height: 6),
                Text(first, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                CommLevelChip(s.pointsOf(u.id)),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------- diskusi terbaru
  Widget _latest(BuildContext context, AppState s) {
    final list = s.latestDiscussions(limit: 5);
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Belum ada diskusi. Mulai percakapan pertama!', style: TextStyle(color: muted(context))),
        ),
      );
    }
    final dark = isDark(context);
    return Column(children: [
      for (final m in list)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () => showMemberProfile(context, m.senderId),
              child: CommAvatar(m.senderName, size: 42),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(m.senderName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showMessageActions(context, m, onReply: () => _openRoom(m.roomId, replyToId: m.id)),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.more_horiz, size: 20)),
                  ),
                ]),
                const SizedBox(height: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openRoom(m.roomId),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF2A2430) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (m.text.isNotEmpty) Text(m.text, style: const TextStyle(fontSize: 13, height: 1.35)),
                      if (m.isInvite) ...[
                        const SizedBox(height: 8),
                        Builder(builder: (_) {
                          final ev = m.eventId == null ? null : s.eventById(m.eventId!);
                          if (ev == null) {
                            return Text('Event tidak tersedia lagi.',
                                style: TextStyle(fontSize: 11.5, color: muted(context)));
                          }
                          return EventInviteCard(ev);
                        }),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('${fmtClock(m.createdAt)} • ${roomById(m.roomId).name}',
                      style: TextStyle(fontSize: 10.5, color: muted(context))),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.favorite, size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('${m.reactionCount}', style: TextStyle(fontSize: 10.5, color: muted(context))),
                  ]),
                  Text('${s.replyCount(m.id)} balasan', style: TextStyle(fontSize: 10.5, color: muted(context))),
                ]),
              ]),
            ),
          ]),
        ),
    ]);
  }

  // --------------------------------------------------------------- composer
  Widget _composer(BuildContext context) {
    final room = roomById(_roomId);
    final dark = isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F1B24) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              initialValue: _roomId,
              onSelected: (v) => setState(() => _roomId = v),
              itemBuilder: (_) => [
                for (final r in kRooms) PopupMenuItem<String>(value: r.id, child: Text(r.name)),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: commA(room.color, .12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: commA(room.color, .4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(room.icon, size: 14, color: room.color),
                  const SizedBox(width: 4),
                  Text('Kirim ke ${room.name}',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: room.color)),
                  Icon(Icons.arrow_drop_down, size: 18, color: room.color),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.event_available_outlined, size: 16, color: AppColors.primary),
              label: const Text('Ajak ke Event', style: TextStyle(fontSize: 11.5)),
              onPressed: _invite,
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
              tooltip: 'Emoji',
              onPressed: _emoji,
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  counterText: '',
                  filled: true,
                  fillColor: softOf(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                tooltip: 'Kirim',
                onPressed: _send,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ============================================================
// KOMPONEN KECIL
// ============================================================
class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
      child: Text(count > 99 ? '99+' : '$count',
          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final bool active;
  const _StatusChip(this.text, this.active);

  @override
  Widget build(BuildContext context) {
    final c = active ? AppColors.success : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: commA(c, .14), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

/// Kartu pengumuman (merah) pada carousel.
class _AnnounceCard extends StatelessWidget {
  final Announcement a;
  const _AnnounceCard(this.a);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ev = a.eventId == null ? null : s.eventById(a.eventId!);
    return GestureDetector(
      onTap: () => showAnnouncementDetail(context, a),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: commA(AppColors.primary, .35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.circle, size: 8, color: AppColors.primary),
                    SizedBox(width: 5),
                    Text('Pengumuman',
                        style: TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ]),
                ),
                if (a.important) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Penting',
                        style: TextStyle(color: Color(0xFF78350F), fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              const SizedBox(height: 8),
              Text(a.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 4),
              Text(a.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
              const Spacer(),
              Row(children: [
                const Icon(Icons.event, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(fmtDate(ev?.date ?? a.createdAt),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                if (ev != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.group_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('${s.participants(ev)} Peserta',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.campaign_rounded, size: 58, color: Colors.white.withAlpha(220)),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Pilihan polling: memilih (1 suara) atau menampilkan hasil otomatis.
class PollOptions extends StatelessWidget {
  final CommPoll p;
  const PollOptions(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final my = s.myVote(p);
    final showResult = my != null || !p.active;

    return Column(children: [
      for (var i = 0; i < p.options.length; i++)
        if (showResult)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Row(children: [
                    Flexible(
                      child: Text(p.options[i],
                          style: TextStyle(fontSize: 12.5, fontWeight: my == i ? FontWeight.w800 : FontWeight.w500)),
                    ),
                    if (my == i)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                      ),
                  ]),
                ),
                Text('${p.percent(i)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.total == 0 ? 0.0 : p.count(i) / p.total,
                  minHeight: 8,
                  backgroundColor: commA(AppColors.primary, .12),
                  valueColor: AlwaysStoppedAnimation<Color>(my == i ? AppColors.primary : AppColors.primaryLight),
                ),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final err = s.votePoll(p.id, i);
                commSnack(context, err ?? 'Suaramu tercatat. Terima kasih!');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: commA(AppColors.primary, .5)),
                ),
                child: Row(children: [
                  const Icon(Icons.radio_button_off, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p.options[i], style: const TextStyle(fontSize: 13))),
                ]),
              ),
            ),
          ),
      const SizedBox(height: 2),
    ]);
  }
}

// ============================================================
// FORM: BUAT PENGUMUMAN (admin)
// ============================================================
class _CreateAnnouncementSheet extends StatefulWidget {
  const _CreateAnnouncementSheet();

  @override
  State<_CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<_CreateAnnouncementSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _important = true;
  String _eventId = '';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    final s = context.read<AppState>();
    final err = s.createAnnouncement(
      title: _title.text,
      body: _body.text,
      important: _important,
      eventId: _eventId.isEmpty ? null : _eventId,
    );
    if (err != null) {
      commSnack(context, err);
      return;
    }
    Navigator.pop(context);
    commSnack(context, 'Pengumuman diterbitkan');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final events = s.query(sort: EventSort.soonest, upcomingOnly: true).take(40).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Buat Pengumuman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Pengumuman resmi akan dikirim ke seluruh anggota.',
            style: TextStyle(fontSize: 12, color: muted(context))),
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _body,
          maxLines: 4,
          maxLength: 600,
          decoration: const InputDecoration(labelText: 'Isi pengumuman', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        const Text('Tautkan event (opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        DropdownButton<String>(
          isExpanded: true,
          value: _eventId,
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('Tanpa event')),
            for (final e in events)
              DropdownMenuItem<String>(
                value: e.id,
                child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _eventId = v ?? ''),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: const Text('Tandai sebagai penting'),
          subtitle: const Text('Pengumuman penting tampil paling atas', style: TextStyle(fontSize: 11)),
          value: _important,
          onChanged: (v) => setState(() => _important = v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Terbitkan Pengumuman', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// FORM: BUAT POLLING
// ============================================================
class _CreatePollSheet extends StatefulWidget {
  const _CreatePollSheet();

  @override
  State<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<_CreatePollSheet> {
  final _question = TextEditingController();
  final List<TextEditingController> _opts = [TextEditingController(), TextEditingController()];
  int _days = 3;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final s = context.read<AppState>();
    final err = s.createPoll(
      question: _question.text,
      options: _opts.map((c) => c.text).toList(),
      days: _days,
    );
    if (err != null) {
      commSnack(context, err);
      return;
    }
    Navigator.pop(context);
    commSnack(context, 'Polling dibuat');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Buat Polling', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Setiap anggota hanya dapat memberi satu suara.',
            style: TextStyle(fontSize: 12, color: muted(context))),
        const SizedBox(height: 14),
        TextField(
          controller: _question,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Pertanyaan', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _opts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _opts[i],
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: 'Pilihan ${i + 1}',
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (_opts.length > 2)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                  onPressed: () => setState(() {
                    final c = _opts.removeAt(i);
                    c.dispose();
                  }),
                ),
            ]),
          ),
        if (_opts.length < 5)
          TextButton.icon(
            onPressed: () => setState(() => _opts.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: const Text('Tambah pilihan'),
          ),
        const SizedBox(height: 4),
        const Text('Durasi polling', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (final d in const [1, 3, 7])
            ChoiceChip(
              label: Text('$d hari'),
              selected: _days == d,
              selectedColor: AppColors.primary,
              showCheckmark: false,
              labelStyle: TextStyle(color: _days == d ? Colors.white : null, fontSize: 12),
              onSelected: (_) => setState(() => _days = d),
            ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Terbitkan Polling', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}