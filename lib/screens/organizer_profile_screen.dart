import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../penyelenggara/organizer_store.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';

// ============================================================================
// FILE BARU: halaman "Profil Penyelenggara" + lembar "Kontak Organisasi".
// Dipakai dari tombol "Lihat Profil" dan "Kontak Organisasi" di detail event.
// Tidak mengubah backend / store lama. Data diambil dari event yang sudah ada
// dan (jika ada) profil yang diisi penyelenggara lewat OrgStore.
// ============================================================================

const Color _red = AppColors.primary;

Color _pinkOf(BuildContext c) => isDark(c) ? const Color(0xFF2A1B1B) : const Color(0xFFFFF1F1);
Color _borderOf(BuildContext c) => isDark(c) ? Colors.white12 : const Color(0xFFF3E3E3);

void _snack(BuildContext c, String m) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
}

// ----------------------------------------------------------------------------
// DATA PENYELENGGARA (gabungan event + profil)
// ----------------------------------------------------------------------------
class OrganizerInfo {
  final String name, desc, category, address, email, phone, social, pj, pic;
  final bool hasProfile;
  final List<EventModel> events;
  const OrganizerInfo({
    required this.name,
    required this.desc,
    required this.category,
    required this.address,
    required this.email,
    required this.phone,
    required this.social,
    required this.pj,
    required this.pic,
    required this.hasProfile,
    required this.events,
  });

  bool get hasContact => email.isNotEmpty || phone.isNotEmpty || social.isNotEmpty;
}

OrganizerInfo resolveOrganizer(AppState s, String name) {
  final key = name.trim().toLowerCase();
  final store = OrgStore.instance;

  OrgProfile? p;
  for (final x in store.profiles.values) {
    if (x.name.trim().toLowerCase() == key) {
      p = x;
      break;
    }
  }

  final map = <String, EventModel>{};
  for (final e in s.events) {
    if (e.organizer.trim().toLowerCase() == key) map[e.id] = e;
  }
  for (final e in store.custom.values) {
    if (e.organizer.trim().toLowerCase() == key) map[e.id] = e;
  }
  for (final id in store.deleted) {
    map.remove(id);
  }
  final list = map.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  // kategori yang paling sering muncul
  final count = <String, int>{};
  for (final e in list) {
    count[e.category] = (count[e.category] ?? 0) + 1;
  }
  String cat = 'Sosial';
  int best = 0;
  count.forEach((k, v) {
    if (v > best) {
      best = v;
      cat = k;
    }
  });
  if (p != null && p.category.trim().isNotEmpty && list.isEmpty) cat = p.category;

  final pDesc = (p?.desc ?? '').trim();
  final desc = pDesc.isNotEmpty
      ? pDesc
      : '$name adalah penyelenggara kegiatan kerelawanan di bidang ${cat.toLowerCase()}. '
          'Saat ini ${list.length} kegiatan mereka terdaftar di aplikasi Volunteer. '
          'Ikuti kegiatannya dan jadilah bagian dari perubahan.';

  return OrganizerInfo(
    name: name,
    desc: desc,
    category: cat,
    address: (p?.address ?? '').trim(),
    email: (p?.email ?? '').trim(),
    phone: (p?.phone ?? '').trim(),
    social: (p?.social ?? '').trim(),
    pj: (p?.pj ?? '').trim(),
    pic: (p?.pic ?? '').trim(),
    hasProfile: p != null,
    events: list,
  );
}

// ----------------------------------------------------------------------------
// PENYIMPANAN LOKAL: pesan ke penyelenggara + daftar yang diikuti
// (disimpan di perangkat lewat SharedPreferences, tidak menyentuh backend)
// ----------------------------------------------------------------------------
class OrgContactMsg {
  final String id, userId, org, subject, body, eventTitle;
  final DateTime createdAt;
  bool read; // sudah dibuka penyelenggara
  String reply; // balasan penyelenggara (kosong = belum dibalas)
  DateTime? repliedAt;
  OrgContactMsg(
    this.id,
    this.userId,
    this.org,
    this.subject,
    this.body,
    this.eventTitle,
    this.createdAt, {
    this.read = false,
    this.reply = '',
    this.repliedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'org': org,
        'subject': subject,
        'body': body,
        'eventTitle': eventTitle,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'reply': reply,
        'repliedAt': repliedAt?.toIso8601String(),
      };

  factory OrgContactMsg.fromJson(Map<String, dynamic> j) => OrgContactMsg(
        (j['id'] ?? '') as String,
        (j['userId'] ?? '') as String,
        (j['org'] ?? '') as String,
        (j['subject'] ?? '') as String,
        (j['body'] ?? '') as String,
        (j['eventTitle'] ?? '') as String,
        DateTime.tryParse((j['createdAt'] ?? '') as String) ?? DateTime.now(),
        read: (j['read'] ?? false) as bool,
        reply: (j['reply'] ?? '') as String,
        repliedAt: DateTime.tryParse((j['repliedAt'] ?? '') as String),
      );
}

class OrganizerInbox extends ChangeNotifier {
  OrganizerInbox._();
  static final OrganizerInbox instance = OrganizerInbox._();

  final List<OrgContactMsg> items = [];
  final Set<String> follows = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('vol_org_contact_v1');
      if (raw != null && raw.isNotEmpty) {
        for (final m in jsonDecode(raw) as List) {
          items.add(OrgContactMsg.fromJson(Map<String, dynamic>.from(m as Map)));
        }
      }
      follows.addAll(p.getStringList('vol_org_follow_v1') ?? const <String>[]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('vol_org_contact_v1', jsonEncode(items.map((e) => e.toJson()).toList()));
      await p.setStringList('vol_org_follow_v1', follows.toList());
    } catch (_) {}
  }

  List<OrgContactMsg> forUser(String uid, String org) {
    final key = org.trim().toLowerCase();
    return items.where((m) => m.userId == uid && m.org.trim().toLowerCase() == key).toList();
  }

  // ---- sisi penyelenggara ----
  /// Pesan masuk untuk penyelenggara yang namanya ada di [names] (huruf kecil).
  List<OrgContactMsg> forOrganizer(Set<String> names) =>
      items.where((m) => names.contains(m.org.trim().toLowerCase())).toList();

  Future<void> markRead(String id) async {
    for (final m in items) {
      if (m.id == id && !m.read) {
        m.read = true;
        notifyListeners();
        await _save();
        return;
      }
    }
  }

  Future<void> reply(String id, String text) async {
    for (final m in items) {
      if (m.id == id) {
        m.reply = text;
        m.repliedAt = DateTime.now();
        m.read = true;
        notifyListeners();
        await _save();
        return;
      }
    }
  }

  Future<void> add(String uid, String org, String subject, String body, String eventTitle) async {
    items.insert(
      0,
      OrgContactMsg('om_${DateTime.now().microsecondsSinceEpoch}', uid, org, subject, body, eventTitle, DateTime.now()),
    );
    notifyListeners();
    await _save();
  }

  String _fk(String uid, String org) => '$uid|${org.trim().toLowerCase()}';
  bool isFollowing(String uid, String org) => follows.contains(_fk(uid, org));

  Future<void> toggleFollow(String uid, String org) async {
    final k = _fk(uid, org);
    if (!follows.remove(k)) follows.add(k);
    notifyListeners();
    await _save();
  }
}

// ----------------------------------------------------------------------------
// HELPER BUKA TAUTAN / WHATSAPP / EMAIL
// ----------------------------------------------------------------------------
String _waNumber(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (d.startsWith('+')) d = d.substring(1);
  if (d.startsWith('0')) d = '62${d.substring(1)}';
  return d;
}

bool _isMobile(String raw) => _waNumber(raw).startsWith('628');

Uri? _socialUri(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http')) return Uri.tryParse(t);
  if (t.contains('.') && !t.startsWith('@') && !t.contains(' ')) return Uri.tryParse('https://$t');
  final h = t.replaceAll('@', '').replaceAll(' ', '');
  if (h.isEmpty) return null;
  return Uri.tryParse('https://www.instagram.com/$h');
}

Future<void> _openUri(BuildContext context, Uri? uri, {String? copyText, String? failMsg}) async {
  if (uri == null) {
    _snack(context, failMsg ?? 'Tautan tidak valid');
    return;
  }
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!context.mounted) return;
  if (!ok) {
    if (copyText != null) {
      Clipboard.setData(ClipboardData(text: copyText));
      _snack(context, 'Tidak bisa membuka aplikasinya, "$copyText" disalin ke clipboard');
    } else {
      _snack(context, failMsg ?? 'Tidak bisa membuka tautan');
    }
  }
}

String _timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return fmtDate(d);
}

Widget _avatar(OrganizerInfo info, double size, {bool onRed = false}) {
  ImageProvider? img;
  if (info.pic.startsWith('data:')) {
    try {
      img = MemoryImage(base64Decode(info.pic.substring(info.pic.indexOf(',') + 1)));
    } catch (_) {
      img = null;
    }
  }
  final initial = info.name.trim().isEmpty ? '?' : info.name.trim()[0].toUpperCase();
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: onRed ? Colors.white.withAlpha(200) : const Color(0xFFFEE2E2), width: 3),
      image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
    ),
    alignment: Alignment.center,
    child: img == null
        ? Text(initial, style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: _red))
        : null,
  );
}

// ============================================================================
// LEMBAR "KONTAK ORGANISASI"
// ============================================================================
Future<void> showOrganizerContactSheet(BuildContext context, String organizer, {EventModel? event}) async {
  final s = context.read<AppState>();
  final info = resolveOrganizer(s, organizer);
  final uid = s.user?.id;
  await OrganizerInbox.instance.load();
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => _ContactSheet(info: info, event: event, userId: uid),
  );
}

class _ContactSheet extends StatefulWidget {
  final OrganizerInfo info;
  final EventModel? event;
  final String? userId;
  const _ContactSheet({required this.info, required this.event, required this.userId});

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  static const _subjects = ['Pertanyaan umum', 'Pendaftaran', 'Jadwal & lokasi', 'Kerja sama'];
  String _subject = _subjects[0];
  final _msg = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  String get _prefill {
    final e = widget.event;
    final ev = e == null ? '' : ' terkait kegiatan "${e.title}"';
    return 'Halo ${widget.info.name}, saya relawan dari aplikasi Volunteer$ev. ';
  }

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (widget.userId == null) {
      _snack(context, 'Silakan login terlebih dahulu');
      return;
    }
    if (text.length < 10) {
      _snack(context, 'Tulis pesan minimal 10 karakter');
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await OrganizerInbox.instance
        .add(widget.userId!, widget.info.name, _subject, text, widget.event?.title ?? '');
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text('Pesan terkirim ke ${widget.info.name}')));
  }

  Widget _channel(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _pinkOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderOf(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: muted(context))),
                ]),
              ),
              Icon(Icons.chevron_right, color: muted(context)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final prev = widget.userId == null
        ? <OrgContactMsg>[]
        : OrganizerInbox.instance.forUser(widget.userId!, info.name);

    final channels = <Widget>[];
    if (info.phone.isNotEmpty && _isMobile(info.phone)) {
      channels.add(_channel(Icons.chat, const Color(0xFF16A34A), 'WhatsApp', info.phone, () {
        _openUri(context, Uri.parse('https://wa.me/${_waNumber(info.phone)}?text=${Uri.encodeComponent(_prefill)}'),
            copyText: info.phone);
      }));
    }
    if (info.phone.isNotEmpty) {
      channels.add(_channel(Icons.call, const Color(0xFF2563EB), 'Telepon', info.phone, () {
        _openUri(context, Uri(scheme: 'tel', path: info.phone.replaceAll(' ', '')), copyText: info.phone);
      }));
    }
    if (info.email.isNotEmpty) {
      channels.add(_channel(Icons.mail_outline, _red, 'Email', info.email, () {
        _openUri(
          context,
          Uri(
            scheme: 'mailto',
            path: info.email,
            query: 'subject=${Uri.encodeComponent('Pertanyaan: ${widget.event?.title ?? info.name}')}'
                '&body=${Uri.encodeComponent(_prefill)}',
          ),
          copyText: info.email,
        );
      }));
    }
    if (info.social.isNotEmpty) {
      channels.add(_channel(Icons.public, const Color(0xFFDB2777), 'Media Sosial', info.social, () {
        _openUri(context, _socialUri(info.social), copyText: info.social);
      }));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(110), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                _avatar(info, 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Hubungi Penyelenggara', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(info.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ]),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 14),
              if (channels.isNotEmpty) ...[
                const Text('Hubungi langsung', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...channels,
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _pinkOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderOf(context)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: _red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Penyelenggara ini belum mencantumkan kontak langsung. Kirim pesan lewat form di bawah.',
                        style: TextStyle(fontSize: 12, color: muted(context), height: 1.35),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 14),
              const Text('Kirim pesan lewat aplikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final sbj in _subjects)
                  ChoiceChip(
                    label: Text(sbj, style: TextStyle(fontSize: 12, color: _subject == sbj ? Colors.white : null)),
                    selected: _subject == sbj,
                    selectedColor: _red,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _subject = sbj),
                  ),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _msg,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.event == null
                      ? 'Tulis pertanyaan atau pesanmu...'
                      : 'Tulis pertanyaan tentang "${widget.event!.title}"...',
                  filled: true,
                  fillColor: _pinkOf(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Kirim Pesan', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              if (prev.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Pesan yang pernah kamu kirim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final m in prev.take(3)) _msgTile(context, m),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

Widget _msgTile(BuildContext context, OrgContactMsg m) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _pinkOf(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderOf(context)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(m.subject, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
        ),
        Text(_timeAgo(m.createdAt), style: TextStyle(fontSize: 11, color: muted(context))),
      ]),
      if (m.eventTitle.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(m.eventTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: _red.withAlpha(220), fontWeight: FontWeight.w600)),
        ),
      const SizedBox(height: 4),
      Text(m.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.35)),
      const SizedBox(height: 6),
      Row(children: [
        Icon(m.reply.isNotEmpty ? Icons.reply_rounded : (m.read ? Icons.done_all : Icons.check_circle),
            size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Text(m.reply.isNotEmpty ? 'Dibalas penyelenggara' : (m.read ? 'Sudah dibaca penyelenggara' : 'Terkirim'),
            style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
      ]),
      if (m.reply.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _red.withAlpha(60)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Balasan${m.repliedAt == null ? '' : ' • ${_timeAgo(m.repliedAt!)}'}',
                style: const TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(m.reply, style: const TextStyle(fontSize: 12.5, height: 1.35)),
          ]),
        ),
    ]),
  );
}

// ============================================================================
// HALAMAN "PROFIL PENYELENGGARA"
// ============================================================================
class OrganizerProfileScreen extends StatefulWidget {
  final String organizer;
  final EventModel? fromEvent;
  const OrganizerProfileScreen(this.organizer, {super.key, this.fromEvent});

  @override
  State<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends State<OrganizerProfileScreen> {
  @override
  void initState() {
    super.initState();
    OrganizerInbox.instance.load();
  }

  BoxDecoration _card(BuildContext c) => BoxDecoration(
        color: Theme.of(c).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderOf(c)),
        boxShadow: isDark(c) ? null : [BoxShadow(color: _red.withAlpha(16), blurRadius: 14, offset: const Offset(0, 5))],
      );

  Widget _title(IconData icon, String text) => Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _pinkOf(context), shape: BoxShape.circle),
          child: Icon(icon, color: _red, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
      ]);

  // ------------------------------------------------------------- header
  Widget _header(OrganizerInfo info, AppState s, bool wide) {
    final uid = s.user?.id;
    final following = uid != null && OrganizerInbox.instance.isFollowing(uid, info.name);

    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(
          child: Text(info.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.verified, color: Colors.white, size: 20),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 6, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14)),
          child: Text(info.category,
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ),
        if (info.address.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_outlined, color: Colors.white70, size: 15),
            const SizedBox(width: 3),
            Text(info.address, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
      ]),
    ]);

    final buttons = Wrap(spacing: 10, runSpacing: 10, children: [
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _red,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        icon: const Icon(Icons.support_agent, size: 18),
        label: const Text('Hubungi', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => showOrganizerContactSheet(context, info.name, event: widget.fromEvent),
      ),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: following ? Colors.white.withAlpha(36) : null,
          side: const BorderSide(color: Colors.white, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        icon: Icon(following ? Icons.check : Icons.add, size: 18),
        label: Text(following ? 'Mengikuti' : 'Ikuti', style: const TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () async {
          if (uid == null) {
            _snack(context, 'Silakan login terlebih dahulu');
            return;
          }
          await OrganizerInbox.instance.toggleFollow(uid, info.name);
          if (!mounted) return;
          _snack(context, following ? 'Berhenti mengikuti ${info.name}' : 'Kamu mengikuti ${info.name}');
        },
      ),
    ]);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF03A3A), _red, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _red.withAlpha(70), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: wide
                ? Row(children: [
                    _avatar(info, 92, onRed: true),
                    const SizedBox(width: 18),
                    Expanded(child: text),
                    const SizedBox(width: 16),
                    buttons,
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      _avatar(info, 68, onRed: true),
                      const SizedBox(width: 14),
                      Expanded(child: text),
                    ]),
                    const SizedBox(height: 16),
                    buttons,
                  ]),
          ),
        ]),
      ),
    );
  }

  // -------------------------------------------------------------- statistik
  Widget _stats(OrganizerInfo info, AppState s) {
    final upcoming = info.events.where((e) => !e.isFinished).length;
    var people = 0;
    for (final e in info.events) {
      people += s.participants(e);
    }

    Widget tile(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: _card(context),
            child: Column(children: [
              Icon(icon, color: _red, size: 22),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: muted(context))),
            ]),
          ),
        );

    return Row(children: [
      tile(Icons.event_available, fmtNum(info.events.length), 'Kegiatan'),
      const SizedBox(width: 10),
      tile(Icons.upcoming_outlined, fmtNum(upcoming), 'Mendatang'),
      const SizedBox(width: 10),
      tile(Icons.groups_2_outlined, fmtNum(people), 'Relawan'),
    ]);
  }

  // ----------------------------------------------------------------- tentang
  Widget _about(OrganizerInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _card(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(Icons.info_outline, 'Tentang Penyelenggara'),
        const SizedBox(height: 12),
        Text(info.desc, style: TextStyle(fontSize: 13.5, height: 1.5, color: muted(context))),
        if (info.pj.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.person_outline, color: _red, size: 18),
            const SizedBox(width: 8),
            Text('Penanggung jawab: ', style: TextStyle(fontSize: 12.5, color: muted(context))),
            Flexible(
              child: Text(info.pj, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
      ]),
    );
  }

  // ------------------------------------------------------------------ kontak
  Widget _contactRow(IconData icon, String label, String value, VoidCallback? onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(children: [
          Icon(icon, color: _red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 11, color: muted(context))),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: muted(context), size: 20),
        ]),
      ),
    );
  }

  Widget _contactCard(OrganizerInfo info) {
    final rows = <Widget>[];
    if (info.address.isNotEmpty) rows.add(_contactRow(Icons.location_on_outlined, 'Alamat', info.address, null));
    if (info.email.isNotEmpty) {
      rows.add(_contactRow(Icons.mail_outline, 'Email', info.email,
          () => _openUri(context, Uri(scheme: 'mailto', path: info.email), copyText: info.email)));
    }
    if (info.phone.isNotEmpty) {
      rows.add(_contactRow(Icons.call_outlined, 'Telepon / WhatsApp', info.phone,
          () => _openUri(context, Uri(scheme: 'tel', path: info.phone.replaceAll(' ', '')), copyText: info.phone)));
    }
    if (info.social.isNotEmpty) {
      rows.add(_contactRow(Icons.public, 'Media sosial', info.social,
          () => _openUri(context, _socialUri(info.social), copyText: info.social)));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _card(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(Icons.contact_phone_outlined, 'Kontak & Lokasi'),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Penyelenggara belum mencantumkan kontak langsung. Kamu tetap bisa mengirim pesan lewat aplikasi.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: muted(context))),
          )
        else
          ...rows,
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: BorderSide(color: _red.withAlpha(90)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.send_rounded, size: 17),
            label: const Text('Kirim Pesan', style: TextStyle(fontWeight: FontWeight.w800)),
            onPressed: () => showOrganizerContactSheet(context, info.name, event: widget.fromEvent),
          ),
        ),
      ]),
    );
  }

  // ----------------------------------------------------------------- kegiatan
  Widget _eventTile(EventModel e, AppState s) {
    final ci = categoryInfo(e.category);

    Widget chip(String t, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(12)),
          child: Text(t, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700)),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _pinkOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderOf(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              EventImage(e, width: 86, height: 86, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.event, size: 14, color: muted(context)),
                    const SizedBox(width: 4),
                    Text(fmtDate(e.date), style: TextStyle(fontSize: 11.5, color: muted(context))),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 14, color: muted(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(e.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: muted(context))),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    chip(e.category, ci.color),
                    chip(e.priceText, _red),
                    if (e.isFinished) chip('Selesai', Colors.grey) else chip('+${e.points} poin', AppColors.success),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right, color: _red),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _events(OrganizerInfo info, AppState s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _card(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(Icons.event_note_outlined, 'Kegiatan oleh ${info.name}'),
        const SizedBox(height: 12),
        if (info.events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Belum ada kegiatan yang terdaftar.', style: TextStyle(color: muted(context))),
          )
        else
          for (final e in info.events) _eventTile(e, s),
      ]),
    );
  }

  Widget _sentMessages(String uid, OrganizerInfo info) {
    final prev = OrganizerInbox.instance.forUser(uid, info.name);
    if (prev.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: _card(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title(Icons.mark_email_read_outlined, 'Pesan yang Kamu Kirim'),
        const SizedBox(height: 12),
        for (final m in prev.take(5)) _msgTile(context, m),
      ]),
    );
  }

  // -------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dark = isDark(context);

    return Scaffold(
      backgroundColor: dark ? null : const Color(0xFFFFF7F7),
      appBar: AppBar(title: const Text('Profil Penyelenggara')),
      body: AnimatedBuilder(
        animation: OrganizerInbox.instance,
        builder: (context, _) {
          final info = resolveOrganizer(s, widget.organizer);
          final uid = s.user?.id;

          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            return ListView(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 10, wide ? 24 : 14, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _header(info, s, wide),
                      const SizedBox(height: 14),
                      _stats(info, s),
                      const SizedBox(height: 14),
                      if (wide)
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            flex: 3,
                            child: Column(children: [
                              _about(info),
                              const SizedBox(height: 14),
                              _events(info, s),
                            ]),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Column(children: [
                              _contactCard(info),
                              if (uid != null) _sentMessages(uid, info),
                            ]),
                          ),
                        ])
                      else ...[
                        _about(info),
                        const SizedBox(height: 14),
                        _contactCard(info),
                        const SizedBox(height: 14),
                        _events(info, s),
                        if (uid != null) _sentMessages(uid, info),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}