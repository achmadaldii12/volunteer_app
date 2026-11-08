import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';
import 'my_activities_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    const pages = <Widget>[
      HomeScreen(),
      SearchScreen(),
      MyActivitiesScreen(),
      NotificationsScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: s.tab, children: pages)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark(context) ? const Color(0xFF1F1B30) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(children: [
              _item(context, s, 0, Icons.home_rounded, 'Beranda'),
              _item(context, s, 1, Icons.search, 'Cari'),
              _item(context, s, 2, Icons.add, 'Daftar', center: true),
              _item(context, s, 3, Icons.notifications_none, 'Notifikasi', badge: s.unreadCount),
              _item(context, s, 4, Icons.person_outline, 'Profil'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, AppState s, int i, IconData icon, String label,
      {bool center = false, int badge = 0}) {
    final sel = s.tab == i;
    final color = sel ? Theme.of(context).colorScheme.primary : Colors.grey;
    Widget ic = center
        ? CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(icon, color: Colors.white, size: 20))
        : Icon(icon, color: color, size: 24);
    if (badge > 0) {
      ic = Stack(clipBehavior: Clip.none, children: [
        ic,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
            child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ),
      ]);
    }
    return Expanded(
      child: InkWell(
        onTap: () => s.setTab(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ic,
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}
