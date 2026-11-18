import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import '../screens/auth_screens.dart';
import '../screens/main_shell.dart';
import 'org_widgets.dart';
import 'organizer_store.dart';
import 'pages/attendance_page.dart';
import 'pages/communication_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/events_page.dart';
import 'pages/org_profile_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/volunteers_page.dart';

/// Pintu masuk setelah login: role akun menentukan halaman tujuan.
/// Satu halaman login untuk semua pengguna (tanpa pilihan role).
class RoleHome extends StatelessWidget {
  const RoleHome({super.key});
  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().user;
    if (u == null) return const LoginScreen();
    return u.role == kOrgRole ? const OrganizerShell() : const MainShell();
  }
}

/// Navigasi internal dashboard penyelenggara.
class OrgNav {
  static final index = ValueNotifier<int>(0);
  static final createRequest = ValueNotifier<int>(0);
  static final query = ValueNotifier<String>('');
  static void go(int i) => index.value = i;
  static bool pendingCreate = false;
  static void create() {
    pendingCreate = true;
    index.value = 1;
    createRequest.value++;
  }
}

const _menu = <(String, IconData)>[
  ('Dashboard', Icons.home_rounded),
  ('Kelola Event', Icons.calendar_month_rounded),
  ('Relawan', Icons.groups_rounded),
  ('Presensi & Sertifikat', Icons.qr_code_scanner_rounded),
  ('Komunikasi', Icons.chat_bubble_rounded),
  ('Laporan', Icons.bar_chart_rounded),
  ('Profil Organisasi', Icons.apartment_rounded),
  ('Pengaturan', Icons.settings_rounded),
];

class OrganizerShell extends StatefulWidget {
  const OrganizerShell({super.key});
  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    OrgNav.index.value = 0;
    OrgNav.index.addListener(_refresh);
  }

  @override
  void dispose() {
    OrgNav.index.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Widget _page(int i) {
    switch (i) {
      case 1:
        return const EventsPage();
      case 2:
        return const VolunteersPage();
      case 3:
        return const AttendancePage();
      case 4:
        return const CommunicationPage();
      case 5:
        return const ReportsPage();
      case 6:
        return const OrgProfilePage();
      case 7:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final org = context.watch<OrgStore>();
    final u = s.user;

    // ---- Penjaga akses: hanya akun ber-role organizer yang boleh di sini.
    if (u == null || u.role != kOrgRole) {
      if (!_leaving) {
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final wide = MediaQuery.of(context).size.width >= 960;
    final prof = org.profileOf(u);
    final pending = org.regsFor(s, org.myEvents(s, u.id).map((e) => e.id)).where((r) => org.regState(s, r) == 'pending').length;
    final idx = OrgNav.index.value;

    final side = _Sidebar(
      name: prof.name,
      pending: pending,
      onPick: (i) {
        OrgNav.go(i);
        if (!wide) Navigator.of(context).maybePop();
      },
      onLogout: () => s.logout(),
    );

    final bar = _TopBar(
      wide: wide,
      search: _search,
      pending: pending,
      name: prof.name,
      pic: prof.pic,
      onMenu: () => _scaffold.currentState?.openDrawer(),
      onSearch: (q) {
        OrgNav.query.value = q;
        OrgNav.go(1);
      },
      onLogout: () => s.logout(),
    );

    final body = Column(children: [
      bar,
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 14, 6, wide ? 28 : 14, 28),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: KeyedSubtree(key: ValueKey(idx), child: _page(idx)))),
        ),
      ),
    ]);

    return Scaffold(
      key: _scaffold,
      backgroundColor: kOrgBg,
      drawer: wide ? null : Drawer(width: 290, child: SafeArea(child: side)),
      body: SafeArea(child: wide ? Row(children: [SizedBox(width: 264, child: side), Expanded(child: body)]) : body),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String name;
  final int pending;
  final void Function(int) onPick;
  final VoidCallback onLogout;
  const _Sidebar({required this.name, required this.pending, required this.onPick, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final cur = OrgNav.index.value;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: kOrgLine))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(children: [
            Image.asset('assets/image/logo_volunteer.png', height: 62, errorBuilder: (_, __, ___) => const Icon(Icons.volunteer_activism, size: 52, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            const Text('Penyelenggara • Berbagi, Berdampak', style: TextStyle(fontSize: 10.5, color: AppColors.primary)),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
            for (var i = 0; i < _menu.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Material(
                  color: cur == i ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onPick(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Icon(_menu[i].$2, size: 21, color: cur == i ? Colors.white : Colors.black45),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_menu[i].$1, style: TextStyle(fontSize: 13.5, fontWeight: cur == i ? FontWeight.w700 : FontWeight.w500, color: cur == i ? Colors.white : Colors.black87))),
                        if (i == 2 && pending > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: cur == i ? Colors.white : AppColors.primary, borderRadius: BorderRadius.circular(99)),
                            child: Text('$pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cur == i ? AppColors.primary : Colors.white)),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 30),
                const SizedBox(height: 6),
                const Text('Bersama kita wujudkan kegiatan sosial yang lebih bermakna!', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.35)),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton(style: redBtn(small: true), onPressed: () { OrgNav.create(); if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context); }, child: const Text('Mulai Event Baru'))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryDark, side: const BorderSide(color: kOrgLine), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool wide;
  final TextEditingController search;
  final int pending;
  final String name, pic;
  final VoidCallback onMenu, onLogout;
  final void Function(String) onSearch;
  const _TopBar({required this.wide, required this.search, required this.pending, required this.name, required this.pic, required this.onMenu, required this.onSearch, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 8, 14, wide ? 28 : 8, 10),
      child: Row(children: [
        if (!wide) IconButton(onPressed: onMenu, icon: const Icon(Icons.menu_rounded)),
        Expanded(
          child: TextField(
            controller: search,
            onSubmitted: onSearch,
            textInputAction: TextInputAction.search,
            decoration: fieldDeco(null, hint: 'Cari event, relawan, atau laporan...', icon: Icons.search_rounded).copyWith(fillColor: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(onPressed: () => OrgNav.go(2), icon: const Icon(Icons.notifications_none_rounded, size: 26)),
          if (pending > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
        PopupMenuButton<String>(
          onSelected: (v) => v == 'out' ? onLogout() : OrgNav.go(6),
          itemBuilder: (_) => const [PopupMenuItem(value: 'p', child: Text('Profil Organisasi')), PopupMenuItem(value: 'out', child: Text('Keluar'))],
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Avatar(initialsOf(name), size: 38, pic: pic),
            if (wide) ...[
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 140), child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                const Text('Penyelenggara', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ]),
        ),
      ]),
    );
  }
}
