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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Navigasi melayang tidak mepet layar
        decoration: BoxDecoration(
          color: isDark(context) ? const Color(0xFF1F1B30) : Colors.white,
          borderRadius: BorderRadius.circular(24), // Pojok background utama tumpul
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(children: [
              _item(context, s, 0, Icons.home_rounded, 'Beranda'),
              _item(context, s, 1, Icons.search_rounded, 'Cari'),
              _item(context, s, 2, Icons.add, 'Daftar', center: true),
              _item(context, s, 3, Icons.notifications_none_rounded, 'Notifikasi', badge: s.unreadCount),
              _item(context, s, 4, Icons.person_outline_rounded, 'Profil'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, AppState s, int i, IconData icon, String label,
      {bool center = false, int badge = 0}) {
    final sel = s.tab == i;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final color = sel ? primaryColor : Colors.grey.shade600;

    Widget ic;
    if (center) {
      // Tombol Tengah (+) Khusus Menu Daftar
      ic = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      );
    } else {
      // Latar belakang kapsul tumpul dengan warna soft pink dan garis pinggir (border) berwarna merah tipis
      ic = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFEBEE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16), // Pojok tumpul rapi
          border: Border.all(
            color: sel ? primaryColor.withOpacity(0.4) : Colors.transparent, // Garis pinggir merah tipis saat aktif
            width: 1.0,
          ),
        ),
        child: Icon(icon, color: color, size: 22),
      );
    }

    if (badge > 0) {
      ic = Stack(clipBehavior: Clip.none, children: [
        ic,
        Positioned(
          right: -4,
          top: -2,
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
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ic,
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}