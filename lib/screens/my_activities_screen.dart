import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../models/models.dart';
import '../providers/activity_store.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'activity_extra_pages.dart';
import 'activity_pages.dart';
import 'event_detail_screen.dart';
import 'profile_extra_pages.dart';
import 'profile_pages.dart';
import 'registration_success_screen.dart';

/// Dipertahankan untuk kompatibilitas dengan halaman lain (tidak melakukan apa pun).
Future<void> showPendingCelebrations(BuildContext context) async {}

/// Halaman Aktivitas Saya (tab Riwayat).
class MyActivitiesScreen extends StatefulWidget {
  final VoidCallback? onNavigateToEvent;
  const MyActivitiesScreen({super.key, this.onNavigateToEvent});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _Feature {
  final IconData icon;
  final String title, subtitle;
  final Widget Function() page;
  final int badge;
  const _Feature(this.icon, this.title, this.subtitle, this.page, {this.badge = 0});
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  int _tab = 0; // 0 = Mengikuti, 1 = Selesai
  bool _showCancelled = false;

  void _open(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MENU AKSI (fitur lama dipertahankan + aksi baru)
  // ============================================================
  void _actions(BuildContext context, Registration r, EventModel e) {
    final s = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Lihat Detail Event'),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e)));
              },
            ),
            if (r.status != RegStatus.cancelled)
              ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Lihat Tiket'),
                onTap: () {
                  Navigator.pop(sheet);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationSuccessScreen(r)));
                },
              ),
            if (r.status == RegStatus.registered) ...[
              ListTile(
                leading: const Icon(Icons.how_to_reg_outlined),
                title: const Text('Verifikasi Kehadiran (demo panitia)'),
                subtitle: Text('Poin +$kPointsPerEvent diberikan setelah kehadiran diverifikasi'),
                onTap: () async {
                  Navigator.pop(sheet);
                  await verifyAttendance(context, r);
                  if (!context.mounted) return;
                  await showPendingCelebrations(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Atur Pengingat'),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(const RemindersScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                title: const Text('Batalkan Pendaftaran', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(sheet);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Batalkan pendaftaran?'),
                      content: Text('Pendaftaran untuk ${e.title} akan dibatalkan.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, batalkan')),
                      ],
                    ),
                  );
                  if (ok == true) s.cancelReg(r.id);
                },
              ),
            ],
            if (r.status == RegStatus.attended) ...[
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Jadikan Koordinator (demo panitia)'),
                subtitle: Text('+$kPointsCoordinator poin tambahan'),
                onTap: () async {
                  Navigator.pop(sheet);
                  final err = s.awardCoordinator(r.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err ?? 'Poin koordinator +$kPointsCoordinator diberikan')));
                  if (err == null && context.mounted) await showPendingCelebrations(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.thumb_up_alt_outlined),
                title: const Text('Beri Apresiasi (demo panitia)'),
                subtitle: Text('+$kPointsAppreciation poin tambahan'),
                onTap: () async {
                  Navigator.pop(sheet);
                  final err = s.awardAppreciation(r.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err ?? 'Poin apresiasi +$kPointsAppreciation diberikan')));
                  if (err == null && context.mounted) await showPendingCelebrations(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('Evaluasi Kegiatan'),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(EvaluationFormScreen(e));
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Catatan Pengalaman'),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(NoteFormScreen(eventId: e.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Bagikan Pengalaman'),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(ShareExperienceScreen(eventId: e.id));
                },
              ),
              ListTile(
                leading: const Icon(Icons.how_to_reg_outlined),
                title: const Text('Riwayat Kehadiran'),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(const AttendanceHistoryScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Laporkan Kendala'),
                onTap: () {
                  Navigator.pop(sheet);
                  _open(const ComplaintsScreen());
                },
              ),
            ],
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ActivityStore>();
    final u = s.user;
    final dark = isDark(context);

    // Pengingat H-3 / H-1 / jam mulai (setiap pengingat hanya dikirim sekali)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runReminders(s, st);
    });

    final registered = s.myRegs.where((r) => r.status == RegStatus.registered).toList();
    registered.sort((a, b) {
      final ea = s.eventById(a.eventId);
      final eb = s.eventById(b.eventId);
      if (ea == null || eb == null) return 0;
      return s.eventWindow(ea).start.compareTo(s.eventWindow(eb).start);
    });
    final cancelled = s.myRegs.where((r) => r.status == RegStatus.cancelled).toList();
    final done = s.attendedRegs;

    return Scaffold(
      backgroundColor: dark ? null : const Color(0xFFFFF7F7),
      appBar: AppBar(
        title: const Text('Aktivitas Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Pengingat kegiatan',
            onPressed: () => _open(const RemindersScreen()),
          ),
        ],
      ),
      body: u == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 860;
              final list = _tab == 0 ? registered : done;

              return ListView(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 6, wide ? 24 : 14, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _banner(s, wide),
                        const SizedBox(height: 14),
                        _tabs(registered.length, done.length),
                        const SizedBox(height: 16),
                        _sectionHeader(),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                          child: Column(
                            key: ValueKey('tab$_tab'),
                            children: [
                              if (list.isEmpty)
                                SizedBox(
                                  height: 340,
                                  child: EmptyState(
                                    Icons.event_busy,
                                    _tab == 0 ? 'Belum ada kegiatan' : 'Belum ada kegiatan selesai',
                                    _tab == 0
                                        ? 'Daftar kegiatan pertamamu dan mulai berkontribusi.'
                                        : 'Kegiatan yang sudah kamu hadiri akan muncul di sini.',
                                    actionText: 'Cari Kegiatan',
                                    onAction: () {
                                      s.openSearch('Semua');
                                      widget.onNavigateToEvent?.call();
                                    },
                                  ),
                                ),
                              for (final r in list) _regCard(context, s, st, r, wide),
                              if (_tab == 0 && cancelled.isNotEmpty) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => setState(() => _showCancelled = !_showCancelled),
                                    icon: Icon(_showCancelled ? Icons.expand_less : Icons.expand_more, color: kActRed),
                                    label: Text('Dibatalkan (${cancelled.length})',
                                        style: const TextStyle(color: kActRed, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                if (_showCancelled) for (final r in cancelled) _regCard(context, s, st, r, wide),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _features(context, s, st, c.maxWidth),
                      ]),
                    ),
                  ),
                ],
              );
            }),
    );
  }

  // ------------------------------------------------------------ banner
  Widget _banner(AppState s, bool wide) {
    Widget stat(IconData icon, Color color, String value, String label) => Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          ]),
        );

    final titleBlock = Row(children: [
      Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(color: Colors.white.withAlpha(235), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.event_available, color: kActRed, size: 34),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Aktivitas Volunteer Kamu',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text('Terus berkontribusi untuk Indonesia yang lebih baik! ✨',
              style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3)),
        ]),
      ),
    ]);

    final stats = Row(children: [
      stat(Icons.star_rounded, const Color(0xFFFBBF24), fmtNum(s.totalPoints), 'Total Poin'),
      Container(width: 1, height: 34, color: Colors.white30),
      stat(Icons.event_available, Colors.white, fmtNum(s.totalEvents), 'Event Diikuti'),
      Container(width: 1, height: 34, color: Colors.white30),
      stat(Icons.schedule, Colors.white, '${fmtNum(s.totalHours)} Jam', 'Kontribusi'),
    ]);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF03A3A), kActRed, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: kActRed.withAlpha(70), blurRadius: 18, offset: const Offset(0, 8))],
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
          Positioned(
            right: 60,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: wide
                ? Row(children: [
                    Expanded(flex: 5, child: titleBlock),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: stats),
                  ])
                : Column(children: [
                    titleBlock,
                    const SizedBox(height: 14),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 12),
                    stats,
                  ]),
          ),
        ]),
      ),
    );
  }

  // -------------------------------------------------------------- tab
  Widget _tabs(int a, int b) {
    Widget item(String label, int count, IconData icon, int idx) {
      final sel = _tab == idx;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => setState(() => _tab = idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: sel ? kActRed : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: sel ? [BoxShadow(color: kActRed.withAlpha(70), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 20, color: sel ? Colors.white : muted(context)),
              const SizedBox(width: 8),
              Text('$label ($count)',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: sel ? Colors.white : muted(context))),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark(context) ? Colors.white.withAlpha(14) : kActPink,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: kActRed.withAlpha(30)),
      ),
      child: Row(children: [
        item('Mengikuti', a, Icons.event_available, 0),
        item('Selesai', b, Icons.check, 1),
      ]),
    );
  }

  Widget _sectionHeader() {
    return Row(children: [
      Container(width: 12, height: 12, decoration: const BoxDecoration(color: kActRed, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_tab == 0 ? 'Event yang Sedang Kamu Ikuti' : 'Event yang Sudah Kamu Selesaikan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(
            _tab == 0
                ? 'Pantau perkembangan event yang kamu ikuti di sini!'
                : 'Kelola evaluasi, catatan, dan pengalamanmu di sini!',
            style: TextStyle(fontSize: 11.5, color: muted(context)),
          ),
        ]),
      ),
      OutlinedButton(
        style: actOutlineStyle(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
        onPressed: () => _open(const ActivityHistoryScreen()),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Text('Lihat Semua'),
          Icon(Icons.chevron_right, size: 18),
        ]),
      ),
    ]);
  }

  // ------------------------------------------------------- kartu kegiatan
  Widget _regCard(BuildContext context, AppState s, ActivityStore st, Registration r, bool wide) {
    final u = s.user;
    final e = s.eventById(r.eventId);
    if (u == null || e == null) return const SizedBox.shrink();

    final registered = r.status == RegStatus.registered;
    final attended = r.status == RegStatus.attended;
    final cancelled = r.status == RegStatus.cancelled;
    final ongoing = registered && s.eventOngoing(e);
    final isCoord = st.isCoordinator(u.id, e.id);
    final evaluated = st.evalOf(u.id, e.id) != null;
    final pts = s.pointsFromEvent(u.id, e.id);
    final remind = st.remindEvent(u.id, r.id);

    // chip status di atas gambar
    Color chipColor;
    String chipText;
    if (ongoing) {
      chipColor = kActRed;
      chipText = 'Sedang Berlangsung';
    } else if (registered) {
      chipColor = const Color(0xFF64748B);
      chipText = 'Terdaftar';
    } else if (attended) {
      chipColor = AppColors.success;
      chipText = 'Selesai';
    } else {
      chipColor = Colors.grey;
      chipText = 'Dibatalkan';
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: wide ? 150 : 118,
        height: wide ? 124 : 104,
        child: Stack(children: [
          Positioned.fill(child: EventImage(e, width: wide ? 150 : 118, height: wide ? 124 : 104, radius: 0)),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: chipColor.withAlpha(235), borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (ongoing) ...[
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                ],
                Text(chipText, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ),
    );

    Widget infoRow(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(icon, size: 15, color: kActRed),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted(context))),
            ),
          ]),
        );

    final pct = (s.eventProgress(e) * 100).round();

    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(e.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.25)),
      infoRow(Icons.location_on_outlined, e.location),
      infoRow(Icons.event, '${fmtDate(e.date)} • ${e.time}'),
      const SizedBox(height: 8),
      if (ongoing) ...[
        Row(children: [
          const Text('Progress Kehadiran', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.eventProgress(e),
                minHeight: 8,
                backgroundColor: kActRed.withAlpha(28),
                valueColor: const AlwaysStoppedAnimation<Color>(kActRed),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        StatusPill(s.remainingText(e), kActRed, icon: Icons.schedule),
      ] else if (registered)
        StatusPill(s.startsInText(e), kActRed, icon: Icons.schedule)
      else if (attended)
        Wrap(spacing: 6, runSpacing: 6, children: [
          StatusPill('+$pts poin', AppColors.success, icon: Icons.star_rounded),
          StatusPill('${e.hours} jam', const Color(0xFF7C3AED), icon: Icons.schedule),
          StatusPill(evaluated ? 'Sudah Dievaluasi' : 'Belum Dievaluasi',
              evaluated ? AppColors.success : AppColors.warning, icon: Icons.rate_review_outlined),
          if (isCoord) const StatusPill('Koordinator', kActRed, icon: Icons.verified),
        ])
      else
        const StatusPill('Pendaftaran dibatalkan', Colors.grey, icon: Icons.cancel_outlined),
      if (registered && isCoord) ...[
        const SizedBox(height: 6),
        const StatusPill('Koordinator', kActRed, icon: Icons.verified),
      ],
    ]);

    void go(Widget p) => _open(p);
    final compactPad = const EdgeInsets.symmetric(horizontal: 14, vertical: 9);

    Widget actions;
    if (ongoing) {
      actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: kActPink, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Text('Poin yang Didapatkan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 4),
              Text('+$kPointsPerEvent Poin', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: actFilledStyle(),
          icon: const Icon(Icons.qr_code_scanner, size: 20),
          label: const Text('Scan QR'),
          onPressed: () => go(CheckInQrScreen(r)),
        ),
      ]);
    } else if (registered) {
      actions = Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
        OutlinedButton.icon(
          style: actOutlineStyle(padding: compactPad),
          icon: Icon(remind ? Icons.notifications_active : Icons.notifications_off_outlined, size: 17),
          label: const Text('Pengingat'),
          onPressed: () {
            st.setRemindEvent(u.id, r.id, !remind);
            pSnack(context, remind ? 'Pengingat dimatikan' : 'Pengingat diaktifkan');
          },
        ),
        OutlinedButton.icon(
          style: actOutlineStyle(padding: compactPad),
          icon: const Icon(Icons.qr_code_scanner, size: 17),
          label: const Text('Scan QR'),
          onPressed: () => go(CheckInQrScreen(r)),
        ),
        ElevatedButton(
          style: actFilledStyle(padding: compactPad),
          onPressed: () => go(EventDetailScreen(e)),
          child: const Text('Lihat Detail'),
        ),
      ]);
    } else if (attended) {
      actions = Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
        ElevatedButton.icon(
          style: actFilledStyle(padding: compactPad),
          icon: const Icon(Icons.rate_review_outlined, size: 17),
          label: Text(evaluated ? 'Ubah Evaluasi' : 'Evaluasi'),
          onPressed: () => go(EvaluationFormScreen(e)),
        ),
        OutlinedButton.icon(
          style: actOutlineStyle(padding: compactPad),
          icon: const Icon(Icons.menu_book_outlined, size: 17),
          label: const Text('Catatan'),
          onPressed: () => go(NoteFormScreen(eventId: e.id)),
        ),
        OutlinedButton.icon(
          style: actOutlineStyle(padding: compactPad),
          icon: const Icon(Icons.share_outlined, size: 17),
          label: const Text('Bagikan'),
          onPressed: () => go(ShareExperienceScreen(eventId: e.id)),
        ),
        OutlinedButton(
          style: actOutlineStyle(padding: compactPad),
          onPressed: () => go(EventDetailScreen(e)),
          child: const Text('Lihat Detail'),
        ),
      ]);
    } else {
      actions = Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          style: actOutlineStyle(padding: compactPad),
          onPressed: () => go(EventDetailScreen(e)),
          child: const Text('Lihat Detail'),
        ),
      );
    }

    final body = wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            image,
            const SizedBox(width: 16),
            Expanded(child: info),
            const SizedBox(width: 14),
            Container(width: 1, height: 100, color: kActRed.withAlpha(40)),
            const SizedBox(width: 14),
            SizedBox(width: ongoing ? 240 : 270, child: actions),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: kActRed),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              image,
              const SizedBox(width: 12),
              Expanded(child: info),
            ]),
            const SizedBox(height: 12),
            actions,
          ]);

    return PCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      onTap: () => _actions(context, r, e),
      child: body,
    );
  }

  // ------------------------------------------------------- fitur tambahan
  Widget _features(BuildContext context, AppState s, ActivityStore st, double maxWidth) {
    final u = s.user!;
    final unevaluated = s.attendedRegs.where((r) => st.evalOf(u.id, r.eventId) == null).length;
    final favs = s.events.where((e) => s.isBookmarked(e.id)).length;

    final items = <_Feature>[
      _Feature(Icons.emoji_events, 'Riwayat Kegiatan', 'Lihat semua event yang pernah kamu ikuti',
          () => const ActivityHistoryScreen()),
      _Feature(Icons.bar_chart_rounded, 'Statistik Aktivitas', 'Lihat perkembangan kontribusi kamu',
          () => const ActivityStatsScreen()),
      _Feature(Icons.share, 'Bagikan Aktivitas', 'Bagikan pencapaian kamu ke media sosial',
          () => const ShareExperienceScreen()),
      _Feature(Icons.feedback_outlined, 'Beri Feedback', 'Sampaikan saran untuk aplikasi kami',
          () => const FeedbackFormScreen('suggestion')),
      _Feature(Icons.groups, 'Ajukan Koordinator', 'Ajukan diri memimpin kegiatan',
          () => const CoordinatorRequestScreen()),
      _Feature(Icons.stars_rounded, 'Riwayat Poin', 'Lihat semua perolehan poin',
          () => const PointsHistoryScreen()),
      _Feature(Icons.rate_review_outlined, 'Evaluasi Kegiatan', 'Nilai event yang sudah selesai',
          () => const EvaluationListScreen(),
          badge: unevaluated),
      _Feature(Icons.menu_book_outlined, 'Catatan Pengalaman', 'Simpan cerita dan pelajaranmu',
          () => const ExperienceNotesScreen()),
      _Feature(Icons.notifications_active_outlined, 'Pengingat Kegiatan', 'Jadwal terdekat dan pengingat',
          () => const RemindersScreen()),
      _Feature(Icons.favorite_border, 'Event Favorit', 'Event yang kamu simpan ($favs)',
          () => const FavoritesScreen()),
      _Feature(Icons.how_to_reg_outlined, 'Riwayat Kehadiran', 'Check-in, check-out, dan durasi',
          () => const AttendanceHistoryScreen()),
      _Feature(Icons.support_agent, 'Pengaduan & Kendala', 'Laporkan masalah saat kegiatan',
          () => const ComplaintsScreen()),
      _Feature(Icons.volunteer_activism, 'Apresiasi Relawan', 'Beri dan lihat apresiasi',
          () => const AppreciationScreen(),
          badge: st.received(u.id).length),
    ];

    final inner = maxWidth - 48;
    final cols = inner >= 1000 ? 4 : (inner >= 640 ? 3 : 2);
    const gap = 10.0;
    final double avail = maxWidth >= 860 ? (inner > 1100 ? 1100.0 : inner) : inner;
    final double w = (avail - 32 - gap * (cols - 1)) / cols;

    return PCard(
      color: isDark(context) ? null : kActPink.withAlpha(150),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.auto_awesome, color: kActRed, size: 20),
          SizedBox(width: 8),
          Text('Fitur Tambahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: gap, runSpacing: gap, children: [
          for (final f in items)
            SizedBox(
              width: w > 120 ? w : 140,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _open(f.page()),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Icon(f.icon, color: kActRed, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2)),
                          const SizedBox(height: 2),
                          Text(f.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: muted(context), height: 1.25)),
                        ]),
                      ),
                      const SizedBox(width: 6),
                      f.badge > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: kActRed, shape: BoxShape.circle),
                              child: Text('${f.badge}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            )
                          : Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: kActPink, shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right, size: 16, color: kActRed),
                            ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}