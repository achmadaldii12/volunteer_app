import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/community.dart';
import '../providers/app_state.dart';
import '../providers/community_logic.dart';
import '../widgets/common.dart';
import 'community_widgets.dart';

/// Ruang diskusi per kategori (Lingkungan, Pendidikan, Sosial, Umum).
class CommunityRoomScreen extends StatefulWidget {
  final String roomId;
  final String? replyToId; // bila dibuka dari tombol "Balas" di beranda komunitas
  const CommunityRoomScreen(this.roomId, {super.key, this.replyToId});

  @override
  State<CommunityRoomScreen> createState() => _CommunityRoomScreenState();
}

class _CommunityRoomScreenState extends State<CommunityRoomScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  CommMessage? _reply;
  int _lastCount = -1;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    if (widget.replyToId != null) _reply = s.messageById(widget.replyToId!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markRoomRead(widget.roomId);
      _toEnd(jump: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(max);
    } else {
      _scroll.animateTo(max, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _send() {
    final s = context.read<AppState>();
    final err = s.sendRoomMessage(roomId: widget.roomId, text: _ctrl.text, replyToId: _reply?.id);
    if (err != null) {
      commSnack(context, err);
      return;
    }
    _ctrl.clear();
    setState(() => _reply = null);
  }

  Future<void> _invite() async {
    final e = await pickEvent(context);
    if (e == null || !mounted) return;
    final s = context.read<AppState>();
    final note = _ctrl.text.trim().isEmpty ? 'Yuk ikutan kegiatan relawan bersama!' : _ctrl.text;
    final err = s.sendRoomMessage(roomId: widget.roomId, text: note, replyToId: _reply?.id, eventId: e.id);
    if (err != null) {
      commSnack(context, err);
      return;
    }
    _ctrl.clear();
    setState(() => _reply = null);
  }

  Future<void> _emoji() async {
    final e = await showEmojiPicker(context);
    if (e == null || !mounted) return;
    _ctrl.text = '${_ctrl.text}$e';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final room = roomById(widget.roomId);
    final msgs = s.roomMessages(widget.roomId);
    final reply = _reply;
    final dark = isDark(context);

    if (msgs.length != _lastCount) {
      final first = _lastCount == -1;
      _lastCount = msgs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _toEnd(jump: first);
        if (!first) context.read<AppState>().markRoomRead(widget.roomId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: commA(room.color, .15), shape: BoxShape.circle),
            child: Icon(room.icon, color: room.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('${s.roomMemberCount(room.id)} anggota aktif',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: muted(context))),
            ]),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang ruang ini',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Ruang ${room.name}'),
                content: Text('${room.desc}.\n\nTekan lama sebuah pesan (atau ikon titik tiga) untuk memberi reaksi, '
                    'membalas, melaporkan, memblokir, atau menghapus pesan milikmu.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: msgs.isEmpty
              ? EmptyState(Icons.forum_outlined, 'Belum ada pesan',
                  'Jadilah yang pertama memulai diskusi di ruang ${room.name}.')
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) {
                    final m = msgs[i];
                    return _Bubble(m, onReply: () => setState(() => _reply = m));
                  },
                ),
        ),
        if (reply != null)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            color: softOf(context),
            child: Row(children: [
              const Icon(Icons.reply, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Membalas ${reply.senderName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Text(reply.isInvite ? '📅 Undangan event' : reply.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: muted(context))),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _reply = null),
              ),
            ]),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1F1B24) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6, offset: const Offset(0, -1))],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                tooltip: 'Emoji',
                onPressed: _emoji,
              ),
              IconButton(
                icon: const Icon(Icons.event_available_outlined, color: AppColors.primary),
                tooltip: 'Ajak ke Event',
                onPressed: _invite,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
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
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// GELEMBUNG PESAN
// ============================================================
class _Bubble extends StatelessWidget {
  final CommMessage m;
  final VoidCallback onReply;
  const _Bubble(this.m, {required this.onReply});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.user;
    final isMe = me != null && m.senderId == me.id;
    final dark = isDark(context);
    final bg = isMe
        ? (dark ? const Color(0xFF4A1D1D) : const Color(0xFFFEE2E2))
        : (dark ? const Color(0xFF2A2430) : const Color(0xFFF3F4F6));
    final original = m.replyToId == null ? null : s.messageById(m.replyToId!);
    final ev = m.eventId == null ? null : s.eventById(m.eventId!);
    final maxW = (MediaQuery.of(context).size.width * .78).clamp(250.0, 520.0).toDouble();
    final cardW = (maxW - 24).clamp(220.0, 320.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => showMemberProfile(context, m.senderId),
              child: CommAvatar(m.senderName, size: 34),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: GestureDetector(
              onLongPress: () => showMessageActions(context, m, onReply: onReply),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                          child: Text(m.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 6),
                        CommLevelChip(s.pointsOf(m.senderId)),
                      ]),
                    ),
                  if (m.replyToId != null) ReplyQuote(original),
                  if (m.text.isNotEmpty) Text(m.text, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                  if (m.isInvite) ...[
                    const SizedBox(height: 8),
                    if (ev != null)
                      SizedBox(width: cardW, child: EventInviteCard(ev))
                    else
                      Text('Event tidak tersedia lagi.', style: TextStyle(fontSize: 11.5, color: muted(context))),
                  ],
                  if (m.reactions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 4, runSpacing: 4, children: [
                      for (final entry in m.reactions.entries)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => s.toggleReaction(m.id, entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: me != null && entry.value.contains(me.id)
                                  ? commA(AppColors.primary, .18)
                                  : commA(Colors.grey, .15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: me != null && entry.value.contains(me.id)
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text('${entry.key} ${entry.value.length}', style: const TextStyle(fontSize: 11.5)),
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(fmtClock(m.createdAt), style: TextStyle(fontSize: 10, color: muted(context))),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => showMessageActions(context, m, onReply: onReply),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.more_horiz, size: 16, color: muted(context)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
