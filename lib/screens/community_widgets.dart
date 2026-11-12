import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/community.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../providers/community_logic.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';

// ============================================================
// UTILITAS KECIL
// ============================================================
String _two(int n) => n.toString().padLeft(2, '0');

/// Waktu kirim pesan: jam hari ini, atau tanggal singkat + jam untuk pesan lama.
String fmtClock(DateTime d) {
  final now = DateTime.now();
  final hm = '${_two(d.hour)}.${_two(d.minute)}';
  if (d.year == now.year && d.month == now.month && d.day == now.day) return hm;
  return '${d.day}/${d.month} $hm';
}

void commSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String yes = 'Ya',
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes, style: TextStyle(color: danger ? AppColors.danger : null, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return ok == true;
}

const RoundedRectangleBorder _sheetShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)));

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(90),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}

// ============================================================
// AVATAR & LEVEL
// ============================================================
class CommAvatar extends StatelessWidget {
  final String name;
  final double size;
  const CommAvatar(this.name, {super.key, this.size = 40});

  static const _palette = [
    Color(0xFFDC2626), Color(0xFF2563EB), Color(0xFF15803D), Color(0xFFDB2777),
    Color(0xFF7C3AED), Color(0xFFEA580C), Color(0xFF0D9488), Color(0xFF4F46E5),
  ];

  String get _initials {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.first.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    var h = 0;
    for (final r in name.runes) {
      h = (h * 31 + r) & 0x7fffffff;
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _palette[h % _palette.length]),
      child: Text(_initials,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * .38)),
    );
  }
}

class CommLevelChip extends StatelessWidget {
  final int points;
  const CommLevelChip(this.points, {super.key});

  @override
  Widget build(BuildContext context) {
    final lv = levelOf(points);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: commA(lv.color, .16), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(lv.icon, size: 10, color: lv.color),
        const SizedBox(width: 3),
        Text(lv.name, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: lv.color)),
      ]),
    );
  }
}

class CommSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const CommSectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(children: [
                Text(action!,
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ============================================================
// KARTU UNDANGAN EVENT (terhubung ke detail + pendaftaran event)
// ============================================================
class EventInviteCard extends StatelessWidget {
  final EventModel event;
  const EventInviteCard(this.event, {super.key});

  void _open(BuildContext context) {
    // Halaman detail event memiliki tombol Daftar Relawan -> biodata -> pembayaran (bila berbayar)
    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final reg = s.regOf(event.id);
    final label = reg != null ? 'Sudah Terdaftar' : (event.isFinished ? 'Kegiatan Selesai' : 'Gabung Event');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF2A2430) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: commA(AppColors.primary, .25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => _open(context),
          child: Row(children: [
            EventImage(event, width: 66, height: 66, radius: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.25)),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.event, size: 12, color: muted(context)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(fmtDate(event.date),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: muted(context))),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.group_outlined, size: 12, color: muted(context)),
                  const SizedBox(width: 4),
                  Text('${s.participants(event)} Peserta',
                      style: TextStyle(fontSize: 11, color: muted(context))),
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _open(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Lihat Detail', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _open(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: reg != null ? Colors.grey : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ============================================================
// KUTIPAN BALASAN
// ============================================================
class ReplyQuote extends StatelessWidget {
  final CommMessage? original;
  const ReplyQuote(this.original, {super.key});

  @override
  Widget build(BuildContext context) {
    final o = original;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: commA(AppColors.primary, .08),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o?.senderName ?? 'Pesan',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text(
          o == null ? 'Pesan telah dihapus' : (o.isInvite ? '📅 Undangan event' : o.text),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: muted(context)),
        ),
      ]),
    );
  }
}

// ============================================================
// KEAMANAN: LAPORKAN & BLOKIR
// ============================================================
Future<void> showReportDialog(BuildContext context, CommMessage m) async {
  final s = context.read<AppState>();
  var reason = kReportReasons.first;
  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Row(children: const [
          Icon(Icons.flag_outlined, color: AppColors.danger),
          SizedBox(width: 8),
          Text('Laporkan Pesan'),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pesan dari ${m.senderName} akan ditinjau admin. Pilih alasan laporan:',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            for (final r in kReportReasons)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  reason == r ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: reason == r ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
                title: Text(r, style: const TextStyle(fontSize: 13)),
                onTap: () => setSt(() => reason = r),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Kirim Laporan'),
          ),
        ],
      ),
    ),
  );
  if (send == true && context.mounted) {
    final err = s.reportMessage(m.id, reason);
    commSnack(context, err ?? 'Laporan terkirim. Terima kasih sudah menjaga komunitas.');
  }
}

Future<void> confirmBlock(BuildContext context, String userId, String name) async {
  final ok = await confirmDialog(
    context,
    title: 'Blokir $name?',
    message: 'Pesan $name tidak akan ditampilkan lagi dan kamu tidak menerima notifikasi darinya. '
        'Kamu dapat membuka blokir kapan saja lewat menu Pengguna Diblokir.',
    yes: 'Blokir',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  final err = context.read<AppState>().blockUser(userId);
  commSnack(context, err ?? '$name diblokir');
}

// ============================================================
// MENU AKSI PESAN: reaksi, balas, salin, laporkan, blokir, hapus
// ============================================================
void showMessageActions(BuildContext context, CommMessage m, {VoidCallback? onReply}) {
  final s = context.read<AppState>();
  final me = s.user;
  final mine = me != null && m.senderId == me.id;
  final canDelete = mine || s.isCommAdmin;
  final reported = s.hasReported(m.id);

  showModalBottomSheet(
    context: context,
    shape: _sheetShape,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          const _Handle(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final e in kReactionEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.pop(sheet);
                    s.toggleReaction(m.id, e);
                  },
                  child: Padding(padding: const EdgeInsets.all(6), child: Text(e, style: const TextStyle(fontSize: 26))),
                ),
            ]),
          ),
          const Divider(height: 8),
          if (onReply != null)
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Balas'),
              onTap: () {
                Navigator.pop(sheet);
                onReply();
              },
            ),
          if (m.text.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Salin teks'),
              onTap: () {
                Navigator.pop(sheet);
                Clipboard.setData(ClipboardData(text: m.text));
                commSnack(context, 'Teks disalin');
              },
            ),
          if (!mine)
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(reported ? 'Sudah dilaporkan' : 'Laporkan pesan'),
              onTap: reported
                  ? null
                  : () {
                      Navigator.pop(sheet);
                      showReportDialog(context, m);
                    },
            ),
          if (!mine)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text('Blokir ${m.senderName}'),
              onTap: () {
                Navigator.pop(sheet);
                confirmBlock(context, m.senderId, m.senderName);
              },
            ),
          if (canDelete)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(mine ? 'Hapus pesan' : 'Hapus pesan (admin)',
                  style: const TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheet);
                final ok = await confirmDialog(context,
                    title: 'Hapus pesan?',
                    message: 'Pesan ini akan dihapus permanen.',
                    yes: 'Hapus',
                    danger: true);
                if (!ok || !context.mounted) return;
                final err = s.deleteMessage(m.id);
                if (err != null) commSnack(context, err);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    ),
  );
}

// ============================================================
// EMOJI & PEMILIH EVENT
// ============================================================
Future<String?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    shape: _sheetShape,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final e in kQuickEmojis)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(sheet, e),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            ),
        ]),
      ),
    ),
  );
}

Future<EventModel?> pickEvent(BuildContext context) {
  return showModalBottomSheet<EventModel>(
    context: context,
    isScrollControlled: true,
    shape: _sheetShape,
    builder: (sheet) => const _EventPickerSheet(),
  );
}

class _EventPickerSheet extends StatefulWidget {
  const _EventPickerSheet();

  @override
  State<_EventPickerSheet> createState() => _EventPickerSheetState();
}

class _EventPickerSheetState extends State<_EventPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.query(q: _q, sort: EventSort.soonest, upcomingOnly: true);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child: Column(children: [
          const SizedBox(height: 12),
          const _Handle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pilih Event untuk Diajak',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Cari kegiatan...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: softOf(context),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Kegiatan tidak ditemukan'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return ListTile(
                        leading: EventImage(e, width: 48, height: 48, radius: 8),
                        title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${fmtDate(e.date)} • ${e.category}', style: const TextStyle(fontSize: 11)),
                        onTap: () => Navigator.pop(context, e),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// DETAIL PENGUMUMAN
// ============================================================
void showAnnouncementDetail(BuildContext context, Announcement a) {
  final s = context.read<AppState>();
  final ev = a.eventId == null ? null : s.eventById(a.eventId!);

  Widget chip(String text, Color c) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: commA(c, .14), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700)),
      );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: _sheetShape,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const _Handle(),
          const SizedBox(height: 16),
          Row(children: [
            chip('Pengumuman', AppColors.primary),
            if (a.important) chip('Penting', const Color(0xFFEA580C)),
          ]),
          const SizedBox(height: 10),
          Text(a.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 6),
          Text('${a.authorName} • ${fmtDateTime(a.createdAt)}',
              style: TextStyle(fontSize: 11.5, color: muted(context))),
          const SizedBox(height: 14),
          Text(a.body, style: const TextStyle(fontSize: 14, height: 1.55)),
          if (ev != null) ...[
            const SizedBox(height: 16),
            EventInviteCard(ev),
          ],
          if (s.isCommAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheet);
                  final ok = await confirmDialog(context,
                      title: 'Hapus pengumuman?',
                      message: 'Pengumuman resmi ini akan dihapus untuk semua anggota.',
                      yes: 'Hapus',
                      danger: true);
                  if (!ok || !context.mounted) return;
                  final err = s.deleteAnnouncement(a.id);
                  commSnack(context, err ?? 'Pengumuman dihapus');
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: const Text('Hapus Pengumuman (Admin)', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
              ),
            ),
          ],
        ]),
      ),
    ),
  );
}

// ============================================================
// PROFIL SINGKAT ANGGOTA (tanpa email / nomor telepon demi privasi)
// ============================================================
class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: muted(context))),
        ]),
      );
}

void showMemberProfile(BuildContext context, String userId) {
  final s = context.read<AppState>();
  final u = s.userById(userId);
  if (u == null) return;
  final pts = s.pointsOf(u.id);
  final events = s.eventsOf(u.id);
  final isMe = s.user?.id == u.id;
  final blocked = s.isBlockedByMe(u.id);
  final earned = kAchBadges.where((b) => s.achEarned(u.id, b)).toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: _sheetShape,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Handle(),
          const SizedBox(height: 16),
          CommAvatar(u.name, size: 76),
          const SizedBox(height: 10),
          Text(isMe ? '${u.name} (Kamu)' : u.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          CommLevelChip(pts),
          const SizedBox(height: 14),
          Text(u.bio.trim().isEmpty ? 'Belum ada bio.' : u.bio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: muted(context), height: 1.4)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: softOf(context), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              _MiniStat(fmtNum(pts), 'Poin'),
              _MiniStat('$events', 'Event Diikuti'),
              _MiniStat('${earned.length}', 'Badge'),
            ]),
          ),
          if (earned.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final b in earned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: commA(b.color, .14), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(b.icon, size: 13, color: b.color),
                    const SizedBox(width: 4),
                    Text(b.name, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: b.color)),
                  ]),
                ),
            ]),
          ],
          const SizedBox(height: 14),
          Text('Demi privasi, email dan nomor telepon anggota tidak ditampilkan.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: muted(context))),
          if (!isMe) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheet);
                  if (blocked) {
                    s.unblockUser(u.id);
                    commSnack(context, '${u.name} dibuka blokirnya');
                  } else {
                    await confirmBlock(context, u.id, u.name);
                  }
                },
                icon: Icon(blocked ? Icons.lock_open : Icons.block, color: AppColors.danger),
                label: Text(blocked ? 'Buka Blokir' : 'Blokir Pengguna',
                    style: const TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
              ),
            ),
          ],
        ]),
      ),
    ),
  );
}
