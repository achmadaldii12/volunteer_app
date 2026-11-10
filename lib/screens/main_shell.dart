import 'package:flutter/material.dart';
import 'community_screen.dart';
import 'achievement_screen.dart';
import 'notifications_screen.dart';

import 'home_screen.dart';
import 'search_screen.dart';       // Halaman Event
import 'my_activities_screen.dart';// Halaman Riwayat
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0; 

  // Daftar halaman utama aplikasi
  final List<Widget> _pages = const [
    HomeScreen(),         // 0. Beranda
    SearchScreen(),       // 1. Event
    MyActivitiesScreen(), // 2. Riwayat
    CommunityScreen(),    // 3. Komunitas
    ProfileScreen(),      // 4. Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), 
        backgroundColor: Colors.transparent, // Transparan agar latar belakang card naik ke atas
        elevation: 0,
        actions: [
          // 1. Tombol Ranking (Piala) ditaruh di sebelah kiri ikon notifikasi
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            tooltip: 'Achievement & Ranking',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AchievementScreen()),
              );
            },
          ),
          // 2. Tombol Notifikasi Merah di sebelah kanannya
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.red),
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // Menggunakan IndexedStack agar perpindahan antar tab instan tanpa lag/lemot
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Event'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Komunitas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}