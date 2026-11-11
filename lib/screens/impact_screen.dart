import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

const _redPrimary = Color(0xFFD32F2F); // Warna merah utama
const _redLight = Color(0xFFEF5350);  // Warna merah muda / gradasi

// ============================================================ helper format
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _n(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return (v < 0 ? '-' : '') + b.toString();
}

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;

    // Hitung total jam kontribusi dan orang terbantu dari event yang diikuti
    int totalHours = s.totalHours;
    int totalImpact = s.totalImpact;
    int totalEvents = s.totalEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: _redPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Dampak Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. KARTU STATISTIK RINGKASAN DAMPAK ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.verified_user_outlined,
                    value: '$totalEvents',
                    label: 'Kegiatan',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timer_outlined,
                    value: '$totalHours Jam',
                    label: 'Kontribusi',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.diversity_3_outlined,
                    value: _n(totalImpact),
                    label: 'Orang Terbantu',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- 2. DAFTAR RIWAYAT EVENT & POIN ---
            const Text(
              'Riwayat Event & Poin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildEventHistoryList(s, u),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _redLight.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _redPrimary, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventHistoryList(AppState s, AppUser? u) {
    final rows = <Widget>[];

    // Masukkan event yang pernah dihadiri dari data registrasi
    for (final r in s.attendedRegs) {
      final e = s.eventById(r.eventId);
      if (e == null) continue;
      rows.add(_HistoryEventRow(
        title: e.title,
        date: _date(e.date),
        category: e.category,
        points: e.points,
      ));
    }

    // Masukkan riwayat poin lama jika ada
    if (u != null && u.pastPoints > 0) {
      rows.add(_HistoryEventRow(
        title: 'Poin dari Riwayat Sebelumnya',
        date: '${u.pastEvents} Kegiatan',
        category: 'Umum',
        points: u.pastPoints,
      ));
    }

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Belum ada riwayat event.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ayo ikuti kegiatan sosial pertamamu dan kumpulkan poinnya!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const Divider(height: 20),
          ]
        ],
      ),
    );
  }
}

class _HistoryEventRow extends StatelessWidget {
  final String title;
  final String date;
  final String category;
  final int points;

  const _HistoryEventRow({
    required this.title,
    required this.date,
    required this.category,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _redPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.volunteer_activism, color: _redPrimary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            '+$points Poin',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
          ),
        ),
      ],
    );
  }
}