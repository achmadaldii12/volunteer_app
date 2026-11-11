import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/gamification.dart';
import '../providers/app_state.dart';
import 'achievement_screen.dart';
import 'certificate_screen.dart'; // Diimpor agar tombol Sertifikat & Feedback berfungsi penuh

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Achmad Aldi Saputra';
  String _email = 'aldii@gmail.com';
  String _selectedAvatarEmoji = '👨‍💻';
  bool _isDarkMode = false; // Mode gelap mandiri yang langsung berfungsi

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil & Avatar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih Avatar Emoji:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _avatarOption('👨‍💻'),
                    _avatarOption('🦸‍♂️'),
                    _avatarOption('🌟'),
                    _avatarOption('🦁'),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _name = nameController.text;
                  _email = emailController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui!')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _avatarOption(String emoji) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAvatarEmoji = emoji;
        });
        Navigator.pop(context);
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.indigo.shade50,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Ubah Tema',
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.indigo,
                    child: Text(_selectedAvatarEmoji, style: const TextStyle(fontSize: 45)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.amber,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 14, color: Colors.black),
                        onPressed: _showEditProfileDialog,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profil'),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.stars_outlined, color: Colors.amber),
                title: const Text('Poin Saya'),
                trailing: Text(
                  '${fmtNum(appState.totalPoints)} Poin',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
                title: const Text('Achievement & Ranking'),
                subtitle: Text(
                  'Level: ${levelOf(appState.totalPoints).name} • Peringkat #${appState.rank}',
                ),
                trailing: const Text('Lihat', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.red),
                title: const Text('Dampak Sosial'),
                onTap: () {
                  _showInfoDialog(
                    'Dampak Sosial',
                    'Total kontribusi dan dampak nyata yang telah kamu berikan kepada masyarakat melalui kegiatan relawan.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.indigo),
                title: const Text('Riwayat Kegiatan'),
                onTap: () {
                  _showInfoDialog(
                    'Riwayat Kegiatan',
                    'Daftar lengkap seluruh kegiatan sosial dan relawan yang pernah kamu ikuti dan hadiri.',
                  );
                },
              ),
              
              // === TOMBOL SERTIFIKAT & FEEDBACK YANG DIHUBUNGKAN SEPENUHNYA ===
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined, color: Colors.green),
                title: const Text('Sertifikat & Feedback'),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CertificateScreen()),
                  );
                },
              ),

              SwitchListTile(
                secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.indigo),
                title: const Text('Mode Gelap (Dark Mode)'),
                value: _isDarkMode,
                onChanged: (val) {
                  setState(() {
                    _isDarkMode = val;
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.blue),
                title: const Text('Bantuan & FAQ'),
                onTap: () {
                  _showInfoDialog(
                    'Bantuan & FAQ',
                    'Butuh bantuan seputar aplikasi relawan? Hubungi tim support kami melalui email di support@volunteer.local',
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi Keluar'),
                      content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Berhasil keluar dari akun.')),
                            );
                          },
                          child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}