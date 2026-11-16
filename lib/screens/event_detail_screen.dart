import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'registration_success_screen.dart';
import 'registration_screens.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel e;
  const EventDetailScreen(this.e, {super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Status pengingat (tampilan saja, belum tersambung ke notifikasi sistem)
  bool _reminderOn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _register(BuildContext context) {
    // Buka halaman biodata dulu. Jika berbayar, setelah biodata lanjut ke pembayaran.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistrationFormScreen(widget.e)),
    );
  }

  // ---------------------------------------------------------------- helpers
  static const Color _red = AppColors.primary;

  Color _surface(BuildContext context) => isDark(context) ? const Color(0xFF1E1E1E) : Colors.white;
  Color _pink(BuildContext context) => isDark(context) ? const Color(0xFF2A1B1B) : const Color(0xFFFFF1F1);
  Color _border(BuildContext context) => isDark(context) ? Colors.white12 : const Color(0xFFF3E3E3);

  BoxDecoration _cardDecoration(BuildContext context, {Color? color, double radius = 20}) {
    return BoxDecoration(
      color: color ?? _surface(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border(context)),
      boxShadow: [
        BoxShadow(
          color: _red.withOpacity(isDark(context) ? 0 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _shareText() =>
      '${widget.e.title} - ${fmtLongDate(widget.e.date)}, ${widget.e.location}. Ayo ikut di aplikasi Volunteer!';

  void _copyShare(String message) {
    Clipboard.setData(ClipboardData(text: _shareText()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openImageViewer() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 420,
                  child: EventImage(widget.e, width: double.infinity, height: 420, radius: 16),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: _pink(context), shape: BoxShape.circle),
          child: Icon(icon, color: _red, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _checkItem(BuildContext context, String text, {IconData icon = Icons.check_circle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final reg = s.regOf(widget.e.id);
    final n = s.participants(widget.e);
    final c = categoryInfo(widget.e.category);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;
    final isMedium = width > 700;
    final isDesktopPadding = width > 900;

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
      btnText = 'Daftar Relawan';
      onTap = () => _register(context);
    }

    return Scaffold(
      backgroundColor: isDark(context) ? const Color(0xFF181212) : const Color(0xFFFFFBFB),
      body: Column(
        children: [
          // Header / Top Navigation Bar
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 12, right: 12),
            decoration: BoxDecoration(
              color: _surface(context),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: _pink(context), shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
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
                  onPressed: () => _copyShare('Info kegiatan disalin ke clipboard'),
                ),
              ],
            ),
          ),

          // Konten Utama Detail Event
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isDesktopPadding ? 48 : 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BAGIAN ATAS: GAMBAR | INFO EVENT | PENYELENGGARA ---
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildImageBlock(context, c, 380)),
                            const SizedBox(width: 24),
                            Expanded(flex: 5, child: _buildInfoBlock(context, c, n, reg, btnText, onTap, isMedium)),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildOrganizerCard(context)),
                          ],
                        )
                      else if (isMedium)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _buildImageBlock(context, c, 340)),
                                const SizedBox(width: 20),
                                Expanded(flex: 5, child: _buildInfoBlock(context, c, n, reg, btnText, onTap, isMedium)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildOrganizerCard(context),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageBlock(context, c, 220),
                            const SizedBox(height: 20),
                            _buildInfoBlock(context, c, n, reg, btnText, onTap, isMedium),
                            const SizedBox(height: 20),
                            _buildOrganizerCard(context),
                          ],
                        ),

                      const SizedBox(height: 28),

                      // --- TAB NAVIGASI ---
                      _buildTabBar(context),
                      const SizedBox(height: 20),

                      // --- ISI TAB + KARTU SAMPING ---
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildTabContent(context, isMedium)),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildSideCards(context)),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabContent(context, isMedium),
                            const SizedBox(height: 20),
                            _buildSideCards(context),
                          ],
                        ),
                      const SizedBox(height: 24),
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

  // ------------------------------------------------------------ gambar utama
  Widget _buildImageBlock(BuildContext context, CategoryInfo c, double height) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: EventImage(widget.e, width: double.infinity, height: height, radius: 24),
          ),
        ),
        // Badge kategori
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Event ${widget.e.category}',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ),
        // Penghitung foto
        Positioned(
          bottom: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('1 / 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- info event
  Widget _buildInfoBlock(
    BuildContext context,
    CategoryInfo c,
    int n,
    Registration? reg,
    String btnText,
    VoidCallback? onTap,
    bool isMedium,
  ) {
    final quota = widget.e.quota;
    final double progress = quota <= 0 ? 0.0 : (n / quota).clamp(0.0, 1.0).toDouble();
    final int percent = (progress * 100).round();

    final dateCard = _miniInfoCard(
      context,
      icon: Icons.calendar_month_outlined,
      title: fmtLongDate(widget.e.date),
      subtitle: 'Pukul ${widget.e.time}',
    );
    final locationCard = _miniInfoCard(
      context,
      icon: Icons.location_on,
      title: widget.e.location,
      subtitle: null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.e.title,
          style: TextStyle(
            fontSize: isMedium ? 30 : 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.e.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14.5, height: 1.5, color: muted(context)),
        ),
        const SizedBox(height: 16),

        // Tanggal & lokasi (lokasi hanya teks + ikon, tanpa peta)
        if (isMedium)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dateCard),
              const SizedBox(width: 10),
              Expanded(child: locationCard),
            ],
          )
        else ...[
          dateCard,
          const SizedBox(height: 10),
          locationCard,
        ],
        const SizedBox(height: 14),

        // Chip kategori, biaya, dan status pendaftaran
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(c.icon, widget.e.category, c.color, c.color.withOpacity(0.12)),
            _chip(Icons.sell_outlined, widget.e.priceText, _red, _pink(context)),
            if (reg != null)
              _chip(
                reg.status == RegStatus.attended ? Icons.verified_outlined : Icons.check_circle_outline,
                reg.status == RegStatus.attended ? 'Sudah Hadir' : 'Sudah Terdaftar',
                AppColors.success,
                AppColors.success.withOpacity(0.12),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Progress pendaftaran (data asli dari AppState)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pink(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_2_outlined, color: _red, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('$n / $quota Relawan',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(isDark(context) ? 0.1 : 0.8),
                  valueColor: const AlwaysStoppedAnimation<Color>(_red),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Batas registrasi
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Batas Registrasi: ${fmtDate(widget.e.date)}',
                style: TextStyle(fontSize: 12, color: muted(context), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tombol Daftar Relawan (CTA utama) + tombol share
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: reg != null ? Colors.grey : _red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 2,
                  ),
                  onPressed: onTap,
                  icon: Icon(reg != null ? Icons.confirmation_number_outlined : Icons.person_add_alt_1, size: 20),
                  label: Text(
                    btnText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  side: BorderSide(color: _border(context), width: 1.5),
                ),
                onPressed: () => _copyShare('Info kegiatan disalin ke clipboard'),
                child: Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.onSurface, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tombol Kontak Organisasi
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              side: BorderSide(color: _red.withOpacity(0.35)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menghubungkan ke penyelenggara event...')),
              );
            },
            icon: const Icon(Icons.support_agent, color: _red, size: 20),
            label: const Text('Kontak Organisasi',
                style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _miniInfoCard(BuildContext context,
      {required IconData icon, required String title, required String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _pink(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _red, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: muted(context))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- penyelenggara
  Widget _buildOrganizerCard(BuildContext context) {
    final org = widget.e.organizer;
    final initial = org.trim().isEmpty ? '?' : org.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Penyelenggara', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _pink(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: _border(context), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(initial, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _red)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(org,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Penyelenggara kegiatan', style: TextStyle(fontSize: 12, color: muted(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _pink(context),
                foregroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Halaman profil organisasi belum tersedia')),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lihat Profil', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: _border(context), height: 1),
          const SizedBox(height: 16),
          const Text('Informasi Tambahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _infoRow(context, Icons.groups_2_outlined, 'Kuota Peserta', '${widget.e.quota} Relawan'),
          _infoRow(context, Icons.schedule, 'Durasi Kegiatan', '${widget.e.hours} Jam'),
          _infoRow(context, Icons.card_giftcard, 'Fasilitas', 'Sertifikat, ${widget.e.points} Poin'),
          _infoRow(context, Icons.sell_outlined, 'Biaya', widget.e.priceText),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(label, style: TextStyle(fontSize: 13, color: muted(context))),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ tab bar
  Widget _buildTabBar(BuildContext context) {
    Widget tab(IconData icon, String label) => Tab(
          height: 46,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border(context), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelColor: _red,
        unselectedLabelColor: muted(context),
        indicatorColor: _red,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          tab(Icons.description_outlined, 'Deskripsi'),
          tab(Icons.event_note_outlined, 'Detail Aktivitas'),
          tab(Icons.groups_outlined, 'Divisi'),
          tab(Icons.photo_library_outlined, 'Galeri'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ isi tab
  Widget _buildTabContent(BuildContext context, bool isMedium) {
    switch (_tabController.index) {
      case 0:
        return _tabDeskripsi(context, isMedium);
      case 1:
        return _tabDetailAktivitas(context);
      case 2:
        return _tabDivisi(context);
      default:
        return _tabGaleri(context);
    }
  }

  Widget _tabDeskripsi(BuildContext context, bool isMedium) {
    final requirements = Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.fact_check_outlined, 'Persyaratan'),
          const SizedBox(height: 16),
          _checkItem(context, 'Membawa semangat dan niat baik'),
          _checkItem(context, 'Mengenakan pakaian yang nyaman'),
          _checkItem(context, 'Membawa botol minum sendiri'),
        ],
      ),
    );

    final benefits = Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.star_rounded, 'Yang Didapat'),
          const SizedBox(height: 16),
          _checkItem(context, 'Sertifikat dan ${widget.e.points} poin relawan'),
          _checkItem(context, 'Pengalaman berharga'),
          _checkItem(context, 'Relasi baru'),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, Icons.campaign_outlined, 'Deskripsi'),
              const SizedBox(height: 14),
              Text(
                widget.e.description,
                style: TextStyle(fontSize: 14, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
              ),
              const SizedBox(height: 22),
              const Text('Tugas Relawan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...widget.e.tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: _red, size: 18),
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
        const SizedBox(height: 16),
        if (isMedium)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: requirements),
              const SizedBox(width: 16),
              Expanded(child: benefits),
            ],
          )
        else ...[
          requirements,
          const SizedBox(height: 16),
          benefits,
        ],
      ],
    );
  }

  Widget _tabDetailAktivitas(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.event_note_outlined, 'Detail Aktivitas'),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule, color: _red, size: 18),
              const SizedBox(width: 8),
              Text('${fmtLongDate(widget.e.date)} • ${widget.e.time}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('• Metode briefing: Google Meet, WhatsApp dan Google Workspace', style: TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 8),
          const Text('• Koordinasi tim dilakukan secara berkala melalui grup koordinasi resmi.', style: TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _tabDivisi(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.groups_outlined, 'Pekerjaan / Divisi Relawan'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pink(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event Organizer & Lapangan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Dibutuhkan relawan untuk koordinasi teknis di lokasi kegiatan.',
                    style: TextStyle(fontSize: 13, color: muted(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabGaleri(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.photo_library_outlined, 'Galeri Dokumentasi'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openImageViewer,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: EventImage(widget.e, width: double.infinity, height: 220, radius: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Ketuk foto untuk melihat lebih besar', style: TextStyle(fontSize: 12, color: muted(context))),
        ],
      ),
    );
  }

  // --------------------------------------------------- kartu samping (bawah)
  Widget _buildSideCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pengingat event
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context, color: _pink(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications, color: _red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Pengingat Event', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Jangan lupa untuk hadir di kegiatan ini!', style: TextStyle(fontSize: 12.5, color: muted(context))),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _reminderOn ? _red : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    side: const BorderSide(color: _red),
                  ),
                  onPressed: () {
                    setState(() => _reminderOn = !_reminderOn);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_reminderOn
                            ? 'Pengingat ditandai. Notifikasi otomatis belum tersedia.'
                            : 'Pengingat dimatikan'),
                      ),
                    );
                  },
                  icon: Icon(
                    _reminderOn ? Icons.notifications_active : Icons.notifications_none,
                    color: _reminderOn ? Colors.white : _red,
                    size: 20,
                  ),
                  label: Text(
                    _reminderOn ? 'Pengingat Aktif' : 'Atur Pengingat',
                    style: TextStyle(color: _reminderOn ? Colors.white : _red, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bagikan event
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context, color: _pink(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.share, color: _red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Bagikan Event', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Ajak teman-temu untuk ikut serta!', style: TextStyle(fontSize: 12.5, color: muted(context))),
              const SizedBox(height: 14),
              Row(
                children: [
                  _shareCircle(Icons.chat, const Color(0xFF25D366), 'Info kegiatan disalin, tempel di WhatsApp'),
                  const SizedBox(width: 12),
                  _shareCircle(Icons.send, const Color(0xFF2AABEE), 'Info kegiatan disalin, tempel di Telegram'),
                  const SizedBox(width: 12),
                  _shareCircle(Icons.camera_alt, const Color(0xFFE1306C), 'Info kegiatan disalin, tempel di Instagram'),
                  const SizedBox(width: 12),
                  _shareCircle(Icons.more_horiz, Colors.black54, 'Info kegiatan disalin ke clipboard', light: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shareCircle(IconData icon, Color color, String message, {bool light = false}) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _copyShare(message),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: light ? Colors.white : color, shape: BoxShape.circle),
        child: Icon(icon, color: light ? color : Colors.white, size: 22),
      ),
    );
  }
}