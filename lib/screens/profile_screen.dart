import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../providers/app_state.dart';
import '../providers/profile_store.dart';
import 'achievement_screen.dart';
import 'certificate_screen.dart';
import 'impact_screen.dart';
import 'profile_extra_pages.dart';
import 'profile_pages.dart';
import 'settings_screen.dart';

/// Halaman Profil Saya (tab Profil pada navigasi bawah).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _quickPhoto(AppState s, ProfileStore st) async {
    final u = s.user;
    if (u == null) return;
    final r = await choosePhoto(context, hasPhoto: st.avatarOf(u.id) != null);
    if (r == null || !mounted) return;
    st.setAvatar(u.id, r.remove ? null : r.bytes);
    pSnack(context, txr(context, 'Foto profil diperbarui', 'Profile photo updated'));
  }

  // ------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = context.watch<ProfileStore>();
    final u = s.user;

    // Notifikasi target pribadi (sekali per bulan)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkGoalNotifications(s, st);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(tx(context, 'Profil Saya', 'My Profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: tx(context, 'Pengaturan', 'Settings'),
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      body: u == null
          ? Center(child: Text(tx(context, 'Silakan login terlebih dahulu', 'Please log in first')))
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 860;
              Widget two(Widget a, Widget b) {
                if (!wide) {
                  return Column(children: [a, const SizedBox(height: 14), b]);
                }
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: a),
                  const SizedBox(width: 14),
                  Expanded(child: b),
                ]);
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 8, wide ? 24 : 14, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(children: [
                        _header(context, s, st, wide),
                        const SizedBox(height: 14),
                        two(_achievementsCard(context, s), _levelCard(context, s)),
                        const SizedBox(height: 14),
                        two(_statsCard(context, s), _vomCard(context, s)),
                        const SizedBox(height: 14),
                        two(_activityMenu(context, s), _settingsMenu(context, s, st)),
                        const SizedBox(height: 14),
                        two(_recapCard(context, s), _goalsCard(context, s, st)),
                        const SizedBox(height: 14),
                        two(_helpCard(context), _journeyCard(context, s, st)),
                        const SizedBox(height: 14),
                        _footer(context, s, st),
                      ]),
                    ),
                  ),
                ],
              );
            }),
    );
  }

  // ----------------------------------------------------------- header
  Widget _header(BuildContext context, AppState s, ProfileStore st, bool wide) {
    final u = s.user!;
    final pts = s.totalPoints;
    final lv = levelOf(pts);
    final verified = st.emailVerified(u.id, u.email);

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

    final editButton = OutlinedButton.icon(
      onPressed: () => _open(const EditProfileScreen()),
      icon: const Icon(Icons.edit_outlined, size: 17),
      label: Text(tx(context, 'Edit Profil', 'Edit Profile')),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    final bio = u.bio.trim().isEmpty
        ? tx(context, 'Bersama untuk aksi nyata yang lebih baik ✨', 'Together for real action and a better world ✨')
        : u.bio;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(18)),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF7C3AED).withAlpha(60)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  PAvatar(u.id, u.name, size: wide ? 96 : 80, ring: true),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () => _quickPhoto(s, st),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.photo_camera, color: AppColors.primary, size: 17),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                      ),
                      if (verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.verified, color: Color(0xFF93C5FD), size: 20),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.email_outlined, color: Colors.white70, size: 15),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(u.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(14)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(lv.icon, size: 14, color: const Color(0xFF78350F)),
                          const SizedBox(width: 4),
                          Text(lv.name,
                              style: const TextStyle(
                                  color: Color(0xFF78350F), fontWeight: FontWeight.w800, fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Text('Level ${levelIndexOf(pts) + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Text(bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic)),
                  ]),
                ),
                if (wide) ...[const SizedBox(width: 12), editButton],
              ]),
              if (!wide) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: editButton),
              ],
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 14),
              Row(children: [
                stat(Icons.star_rounded, const Color(0xFFFBBF24), fmtNum(pts), tx(context, 'Total Poin', 'Total Points')),
                Container(width: 1, height: 34, color: Colors.white24),
                stat(Icons.event_available, Colors.white, fmtNum(s.totalEvents), tx(context, 'Event Diikuti', 'Events Joined')),
                Container(width: 1, height: 34, color: Colors.white24),
                stat(Icons.schedule, Colors.white, '${fmtNum(s.totalHours)} ${tx(context, 'Jam', 'Hrs')}',
                    tx(context, 'Kontribusi', 'Contribution')),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------------------------------------------------- pencapaian saya
  Widget _achievementsCard(BuildContext context, AppState s) {
    final u = s.user!;
    const ids = ['first', 'eco', 'active', 'super', 'expert'];
    final badges = kAchBadges.where((b) => ids.contains(b.id)).toList();
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.emoji_events, tx(context, 'Pencapaian Saya', 'My Achievements'),
            action: tx(context, 'Lihat Semua', 'See All'), onAction: () => _open(const BadgesScreen())),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final b in badges)
              Builder(builder: (_) {
                final earned = s.achEarned(u.id, b);
                return InkWell(
                  onTap: () => showBadgeDetail(context, b),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 82,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: earned ? b.color.withAlpha(24) : AppColors.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(children: [
                      ProfileBadgeIcon(b, earned, size: 50),
                      const SizedBox(height: 8),
                      Text(b.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: earned ? null : muted(context))),
                    ]),
                  ),
                );
              }),
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------ progress level
  Widget _levelCard(BuildContext context, AppState s) {
    final pts = s.totalPoints;
    final lp = levelProgress(pts);
    final idx = levelIndexOf(pts);
    final pct = (lp.progress * 100).round();
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.bar_chart_rounded, tx(context, 'Progress Level', 'Level Progress')),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [lp.level.color, const Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: lp.level.color.withAlpha(90), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Level ${idx + 1}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: lp.level.color.withAlpha(34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(lp.level.name,
                      style: TextStyle(color: lp.level.color, fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.workspace_premium, size: 14, color: lp.level.color),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: lp.progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 9,
                        backgroundColor: AppColors.primary.withAlpha(28),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(lp.next == null ? 'MAX' : '$pct%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          lp.next == null
              ? tx(context, 'Kamu sudah mencapai level tertinggi 🎉', 'You have reached the highest level 🎉')
              : '${fmtNum(lp.remaining)} ${tx(context, 'poin lagi untuk mencapai', 'points to reach')} Level ${idx + 2} (${lp.next!.name})',
          style: TextStyle(fontSize: 11.5, color: muted(context)),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------ statistik
  Widget _statsCard(BuildContext context, AppState s) {
    Widget tile(IconData icon, Color color, String value, String label) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: 10, color: muted(context), height: 1.15)),
            ]),
          ),
        );

    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.bar_chart_rounded, tx(context, 'Statistik Aktivitas', 'Activity Statistics'),
            action: tx(context, 'Lihat Detail', 'Details'), onAction: () => _open(const StatisticsScreen())),
        const SizedBox(height: 14),
        Row(children: [
          tile(Icons.event_available, const Color(0xFFDC2626), '${s.totalEvents}', tx(context, 'Event', 'Events')),
          tile(Icons.schedule, const Color(0xFF7C3AED), '${s.totalHours}', tx(context, 'Jam', 'Hours')),
          tile(Icons.groups, const Color(0xFF2563EB), fmtNum(s.totalImpact), tx(context, 'Penerima Manfaat', 'Beneficiaries')),
          tile(Icons.star_rounded, const Color(0xFFF59E0B), fmtNum(s.totalPoints), tx(context, 'Total Poin', 'Total Points')),
        ]),
      ]),
    );
  }

  // ----------------------------------------------------- volunteer of month
  Widget _vomCard(BuildContext context, AppState s) {
    final board = s.monthlyBoard();
    final w = board.winner;
    final en = context.read<ProfileStore>().isEnglish;
    final label = DateFormat('MMMM yyyy', en ? 'en_US' : 'id_ID').format(board.month);

    return PCard(
      color: isDark(context) ? const Color(0xFF2E2713) : const Color(0xFFFFF8E1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Volunteer of The Month',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withAlpha(40), borderRadius: BorderRadius.circular(10)),
            child: Text('${tx(context, 'Edisi', 'Edition')} $label',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
          ),
        ]),
        const SizedBox(height: 14),
        if (w == null)
          Text(tx(context, 'Belum ada aktivitas pada bulan ini.', 'No activity this month yet.'),
              style: TextStyle(color: muted(context), fontSize: 13))
        else
          Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              PAvatar(w.user.id, w.user.name, size: 62, ring: true),
              const Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(child: Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 22)),
              ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w.isMe ? '${w.user.name} (${tx(context, 'Kamu', 'You')})' : w.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(tx(context, 'Top Volunteer Bulan Ini! 🎉', 'Top Volunteer of the Month! 🎉'),
                    style: TextStyle(fontSize: 11, color: muted(context))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text('${fmtNum(w.points)} ${tx(context, 'Poin', 'Pts')}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.event_available, size: 15, color: muted(context)),
                const SizedBox(width: 4),
                Text('${w.events} Event', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ]),
      ]),
    );
  }

  // --------------------------------------------------------- aktivitas saya
  Widget _activityMenu(BuildContext context, AppState s) {
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.person_outline, tx(context, 'Aktivitas Saya', 'My Activities')),
        const SizedBox(height: 8),
        PMenuTile(
          icon: Icons.emoji_events,
          color: const Color(0xFFF59E0B),
          title: 'Achievement & Ranking',
          subtitle: tx(context, 'Lihat pencapaian dan peringkat', 'See your achievements and ranking'),
          onTap: () => _open(const AchievementScreen()),
        ),
        PMenuTile(
          icon: Icons.monetization_on_outlined,
          color: const Color(0xFFD97706),
          title: tx(context, 'Riwayat Poin', 'Point History'),
          subtitle: tx(context, 'Lihat seluruh perolehan poin', 'See all points earned'),
          onTap: () => _open(const PointLedgerScreen()),
        ),
        PMenuTile(
          icon: Icons.favorite,
          color: AppColors.primary,
          title: tx(context, 'Dampak Sosial', 'Social Impact'),
          subtitle: tx(context, 'Lihat kontribusi kamu', 'See your contribution'),
          onTap: () => _open(const ImpactScreen()),
        ),
        PMenuTile(
          icon: Icons.event_note,
          color: const Color(0xFF2563EB),
          title: tx(context, 'Riwayat Kegiatan', 'Activity History'),
          subtitle: tx(context, 'Riwayat event yang pernah diikuti', 'Events you have joined'),
          onTap: () => _open(const ActivityHistoryScreen()),
        ),
        PMenuTile(
          icon: Icons.workspace_premium_outlined,
          color: const Color(0xFF15803D),
          title: tx(context, 'Sertifikat Saya', 'My Certificates'),
          subtitle: tx(context, 'Unduh sertifikat kegiatan', 'Download activity certificates'),
          onTap: () => _open(const CertificateScreen()),
        ),
      ]),
    );
  }

  // ------------------------------------------------------ pengaturan akun
  Widget _themeSelector(BuildContext context, AppState s) {
    Widget item(ThemeMode m, IconData icon) {
      final selected = s.themeMode == m;
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => s.setThemeMode(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: selected ? Colors.white : muted(context)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        item(ThemeMode.light, Icons.light_mode),
        item(ThemeMode.dark, Icons.dark_mode),
        item(ThemeMode.system, Icons.desktop_windows_outlined),
      ]),
    );
  }

  Widget _settingsMenu(BuildContext context, AppState s, ProfileStore st) {
    final unread = s.unreadCount;
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.settings, tx(context, 'Pengaturan Akun', 'Account Settings')),
        const SizedBox(height: 8),
        PMenuTile(
          icon: Icons.shield_outlined,
          color: const Color(0xFF7C3AED),
          title: tx(context, 'Keamanan & Privasi', 'Security & Privacy'),
          subtitle: tx(context, 'Ubah password dan kelola akun', 'Change password and manage account'),
          onTap: () => _open(const SecurityScreen()),
        ),
        PMenuTile(
          icon: Icons.notifications_none,
          color: AppColors.primary,
          title: tx(context, 'Pengaturan Notifikasi', 'Notification Settings'),
          subtitle: tx(context, 'Pilih notifikasi yang ingin diterima', 'Choose which notifications you receive'),
          trailing: unread > 0
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: Text('$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                )
              : null,
          onTap: () => _open(const NotificationSettingsScreen()),
        ),
        PMenuTile(
          icon: Icons.language,
          color: const Color(0xFF2563EB),
          title: tx(context, 'Bahasa', 'Language'),
          subtitle: st.isEnglish ? 'English' : 'Indonesia',
          onTap: () => _open(const LanguageScreen()),
        ),
        PMenuTile(
          icon: Icons.accessibility_new,
          color: const Color(0xFF0D9488),
          title: tx(context, 'Aksesibilitas', 'Accessibility'),
          subtitle: tx(context, 'Atur ukuran teks dan kontras', 'Adjust text size and contrast'),
          onTap: () => _open(const AccessibilityScreen()),
        ),
        PMenuTile(
          icon: Icons.dark_mode_outlined,
          color: const Color(0xFF4F46E5),
          title: tx(context, 'Tampilan Aplikasi', 'App Appearance'),
          subtitle: 'Light • Dark • ${tx(context, 'Sistem', 'System')}',
          trailing: _themeSelector(context, s),
          onTap: () {
            final next = s.themeMode == ThemeMode.light
                ? ThemeMode.dark
                : (s.themeMode == ThemeMode.dark ? ThemeMode.system : ThemeMode.light);
            s.setThemeMode(next);
          },
        ),
      ]),
    );
  }

  // ------------------------------------------------------------ monthly recap
  Widget _recapCard(BuildContext context, AppState s) {
    final u = s.user!;
    final ms = s.monthStat(u.id, DateTime.now());

    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Column(children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(fontSize: 10.5, color: muted(context))),
          ]),
        );

    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.calendar_month, 'Monthly Recap',
            action: tx(context, 'Lihat Detail', 'Details'), onAction: () => _open(const MonthlyRecapScreen())),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tx(context, 'Ringkasan kontribusi kamu bulan ini!', 'Your contribution summary this month!'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              stat(Icons.event_available, '${ms.events}', 'Event'),
              stat(Icons.schedule, '${ms.hours}', tx(context, 'Jam', 'Hours')),
              stat(Icons.star_rounded, fmtNum(ms.points), tx(context, 'Poin', 'Points')),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _open(const MonthlyRecapScreen()),
                icon: const Icon(Icons.share, size: 18),
                label: Text(tx(context, 'Bagikan Recap', 'Share Recap')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ----------------------------------------------------------- target pribadi
  Widget _goalsCard(BuildContext context, AppState s, ProfileStore st) {
    final u = s.user!;
    final ms = s.monthStat(u.id, DateTime.now());
    final ge = st.goalEvents(u.id);
    final gh = st.goalHours(u.id);

    Widget bar(String label, int cur, int goal) {
      final p = goal <= 0 ? 0.0 : (cur / goal).clamp(0.0, 1.0).toDouble();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
            Text('$cur / $goal', style: TextStyle(fontSize: 12, color: muted(context))),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 9,
              backgroundColor: AppColors.primary.withAlpha(28),
              valueColor: AlwaysStoppedAnimation<Color>(p >= 1 ? AppColors.success : AppColors.primary),
            ),
          ),
        ]),
      );
    }

    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.flag_outlined, tx(context, 'Target Pribadi', 'Personal Goals'),
            action: tx(context, 'Ubah', 'Edit'), onAction: () => _open(const GoalsScreen())),
        const SizedBox(height: 14),
        bar(tx(context, 'Target event bulan ini', 'Event goal this month'), ms.events, ge),
        bar(tx(context, 'Target jam kontribusi', 'Contribution hours goal'), ms.hours, gh),
        Text(
          tx(context, 'Kamu akan diberi tahu saat target tercapai.', 'You will be notified when a goal is reached.'),
          style: TextStyle(fontSize: 11, color: muted(context)),
        ),
      ]),
    );
  }

  // ------------------------------------------------------- bantuan & lainnya
  Widget _helpCard(BuildContext context) {
    return PCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.help_outline, tx(context, 'Bantuan & Lainnya', 'Help & More')),
        const SizedBox(height: 8),
        PMenuTile(
          icon: Icons.help_center_outlined,
          color: const Color(0xFF2563EB),
          title: tx(context, 'Pusat Bantuan', 'Help Center'),
          subtitle: tx(context, 'FAQ, panduan, dan hubungi admin', 'FAQ, guide and contact admin'),
          onTap: () => _open(const HelpCenterScreen()),
        ),
        PMenuTile(
          icon: Icons.report_problem_outlined,
          color: const Color(0xFFEA580C),
          title: tx(context, 'Laporkan Masalah', 'Report a Problem'),
          subtitle: tx(context, 'Beri tahu kami jika ada kendala', 'Tell us if something goes wrong'),
          onTap: () => _open(const FeedbackFormScreen('report')),
        ),
        PMenuTile(
          icon: Icons.lightbulb_outline,
          color: const Color(0xFF7C3AED),
          title: tx(context, 'Kirim Saran & Masukan', 'Send Suggestions & Feedback'),
          subtitle: tx(context, 'Bantu kami menjadi lebih baik', 'Help us get better'),
          onTap: () => _open(const FeedbackFormScreen('suggestion')),
        ),
        PMenuTile(
          icon: Icons.logout,
          color: AppColors.danger,
          title: tx(context, 'Keluar', 'Log out'),
          danger: true,
          trailing: const SizedBox.shrink(),
          onTap: () => confirmLogout(context),
        ),
      ]),
    );
  }

  // ------------------------------------------------------ perjalanan volunteer
  Widget _journeyCard(BuildContext context, AppState s, ProfileStore st) {
    final u = s.user!;
    final joined = st.joinedAt(u.id, evidence: s.earliestActivity(u.id));
    final earned = kAchBadges.where((b) => s.achEarned(u.id, b)).length;

    return PCard(
      onTap: () => _open(const JourneyScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PSectionHeader(Icons.timeline, tx(context, 'Perjalanan Volunteer', 'Volunteer Journey'),
            action: tx(context, 'Lihat', 'View'), onAction: () => _open(const JourneyScreen())),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), shape: BoxShape.circle),
            child: const Icon(Icons.route, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${tx(context, 'Bergabung sejak', 'Member since')} ${fmtLongDate(joined)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 3),
              Text(
                '$earned ${tx(context, 'badge', 'badges')} • Level ${levelOf(s.totalPoints).name} • ${s.totalEvents} ${tx(context, 'kegiatan', 'activities')}',
                style: TextStyle(fontSize: 11.5, color: muted(context)),
              ),
            ]),
          ),
          Icon(Icons.chevron_right, color: muted(context)),
        ]),
      ]),
    );
  }

  // ------------------------------------------------------------------ footer
  Widget _footer(BuildContext context, AppState s, ProfileStore st) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${tx(context, 'Terakhir aktif: Hari ini', 'Last active: Today')}, ${DateFormat('HH.mm').format(st.sessionStart)}',
            style: TextStyle(fontSize: 12, color: muted(context)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: AppColors.success.withAlpha(30), borderRadius: BorderRadius.circular(12)),
          child: const Text('Online',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
        ),
        const SizedBox(width: 14),
        Icon(Icons.dark_mode, size: 16, color: muted(context)),
        const SizedBox(width: 4),
        Text(tx(context, 'Mode Gelap', 'Dark Mode'), style: const TextStyle(fontSize: 11.5)),
        Switch(
          value: dark,
          activeColor: AppColors.primary,
          onChanged: (v) => s.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
        ),
      ]),
    );
  }
}