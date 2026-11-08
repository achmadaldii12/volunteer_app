import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'registration_success_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel e;
  const EventDetailScreen(this.e, {super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _register(BuildContext context) async {
    final s = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Daftar kegiatan ini?'),
        content: Text('${widget.e.title}\n${fmtLongDate(widget.e.date)} - ${widget.e.time}\n${widget.e.location}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Daftar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = s.registerEvent(widget.e);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationSuccessScreen(s.regOf(widget.e.id)!, fresh: true, fromDetail: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final reg = s.regOf(widget.e.id);
    final n = s.participants(widget.e);
    final c = categoryInfo(widget.e.category);
    final isWide = MediaQuery.of(context).size.width > 900;

    String btnText;
    VoidCallback? onTap;
    if (reg != null) {
      btnText = 'Lihat Tiket';
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegistrationSuccessScreen(reg, fromDetail: true)),
          );
    } else if (widget.e.isFinished) {
      btnText = 'Kegiatan Telah Selesai';
    } else if (s.remaining(widget.e) <= 0) {
      btnText = 'Kuota Penuh';
    } else {
      btnText = 'Jadi Relawan';
      onTap = () => _register(context);
    }

    return Scaffold(
      body: Column(
        children: [
          // Header / Top Navigation Bar sederhana
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 16, right: 16),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.e.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(s.isBookmarked(widget.e.id) ? Icons.bookmark : Icons.bookmark_border, color: primary),
                  onPressed: () => s.toggleBookmark(widget.e.id),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: '${widget.e.title} - ${fmtLongDate(widget.e.date)}, ${widget.e.location}. Ayo ikut di aplikasi Volunteer!'));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Info kegiatan disalin ke clipboard')));
                  },
                ),
              ],
            ),
          ),

          // Konten Utama Detail Event
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 16, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BAGIAN UTAMA: KIRI (GAMBAR BESAR) & KANAN (CARD PENDAFTARAN) ---
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kiri: Gambar Banner Besar HD
                            Expanded(
                              flex: 7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 480,
                                  width: double.infinity,
                                  child: EventImage(widget.e, width: double.infinity, height: 480, radius: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Kanan: Card Pendaftaran ala Referensi
                            Expanded(
                              flex: 4,
                              child: RegistrationCard(
                                event: widget.e,
                                catInfo: c,
                                isRegistered: reg != null,
                                btnText: btnText,
                                onTap: onTap,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 280,
                                width: double.infinity,
                                child: EventImage(widget.e, width: double.infinity, height: 280, radius: 16),
                              ),
                            ),
                            const SizedBox(height: 24),
                            RegistrationCard(
                              event: widget.e,
                              catInfo: c,
                              isRegistered: reg != null,
                              btnText: btnText,
                              onTap: onTap,
                            ),
                          ],
                        ),

                      const SizedBox(height: 36),

                      // --- BAGIAN ORGANISASI & JUMLAH RELAWAN ---
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.favorite, color: Color(0xFFE53935), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bersama', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.e.organizer,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text('$n Relawan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle),
                                  child: Text(
                                    '$n',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // --- TAB NAVIGASI ---
                      Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: const Color(0xFFE53935),
                          unselectedLabelColor: muted(context),
                          indicatorColor: const Color(0xFFE53935),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Deskripsi'),
                            Tab(text: 'Detail Aktivitas'),
                            Tab(text: 'Divisi'),
                            Tab(text: 'Galeri'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- ISI TAB ---
                      SizedBox(
                        height: 420,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Deskripsi
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Deskripsi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.e.description,
                                      style: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text('Tugas Relawan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    ...widget.e.tasks.map((task) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.check_circle_outline, color: Color(0xFFE53935), size: 18),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(task, style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface)),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),

                            // Tab 2: Detail Aktivitas
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Detail Aktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    const Text('• Metode briefing: Google Meet, WhatsApp dan Google Workspace', style: TextStyle(fontSize: 14, height: 1.5)),
                                    const SizedBox(height: 8),
                                    const Text('• Koordinasi tim dilakukan secara berkala melalui grup koordinasi resmi.', style: TextStyle(fontSize: 14, height: 1.5)),
                                  ],
                                ),
                              ),
                            ),

                            // Tab 3: Divisi
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pekerjaan / Divisi Relawan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Event Organizer & Lapangan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          Text('Dibutuhkan relawan untuk koordinasi teknis di lokasi kegiatan.', style: TextStyle(fontSize: 13, color: muted(context))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Tab 4: Galeri
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Galeri Dokumentasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        height: 220,
                                        width: double.infinity,
                                        child: EventImage(widget.e, width: double.infinity, height: 220, radius: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Terpisah untuk Card Pendaftaran di Sebelah Kanan
class RegistrationCard extends StatelessWidget {
  final EventModel event;
  final CategoryInfo catInfo;
  final bool isRegistered;
  final String btnText;
  final VoidCallback? onTap;

  const RegistrationCard({
    super.key,
    required this.event,
    required this.catInfo,
    required this.isRegistered,
    required this.btnText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: catInfo.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catInfo.icon, size: 12, color: catInfo.color),
                    const SizedBox(width: 4),
                    Text(event.category, style: TextStyle(color: catInfo.color, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, height: 1.3),
          ),
          const SizedBox(height: 16),
          
          // Kotak Informasi Tanggal & Lokasi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFE53935)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jadwal Event', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(fmtLongDate(event.date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('Pukul ${event.time}', style: TextStyle(fontSize: 12, color: muted(context))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFE53935)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lokasi', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(event.location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Batas Registrasi: ${fmtDate(event.date)}', style: TextStyle(fontSize: 12, color: muted(context), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),

          // Tombol Pendaftaran Utama
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered ? Colors.grey : const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: onTap,
              child: Text(
                btnText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Kontak Organisasi
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menghubungkan ke penyelenggara event...')),
                );
              },
              child: Text('Kontak Organisasi', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}