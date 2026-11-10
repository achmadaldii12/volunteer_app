import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'impact_screen.dart';
import 'achievement_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'my_activities_screen.dart';
import 'community_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const MyActivitiesScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
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

// Model Sederhana untuk Artikel Blog Volunteer
class ArticleModel {
  final String title;
  final String excerpt;
  final String content;
  final String imageUrl;
  final String date;
  final List<String> additionalImages;

  const ArticleModel({
    required this.title,
    required this.excerpt,
    required this.content,
    required this.imageUrl,
    required this.date,
    required this.additionalImages,
  });
}

// Data Lengkap 10 Artikel
const List<ArticleModel> kBlogArticles = [
  ArticleModel(
    title: 'Di Balik Rel Kereta: Cerita Relawan dari Komunitas Edan Sepur',
    excerpt: 'Apa yang pertama kali terbayangkan olehmu ketika mendengar kereta api? Sebagian dari kita mungkin berpikir...',
    date: '15 Oktober 2026',
    imageUrl: 'assets/image/artikel_1.jpg',
    content: '''Apa yang pertama kali terbayangkan olehmu ketika mendengar kereta api? Sebagian dari kita mungkin berpikir tentang perjalanan jauh, ketepatan waktu, atau stasiun yang sibuk. Namun, di balik beroperasinya ribuan perjalanan kereta setiap harinya, ada cerita-cerita luar biasa dari para relawan yang mendedikasikan waktu mereka untuk keselamatan dan edukasi perlintasan sebidang.

Komunitas Edan Sepur adalah salah satu contoh nyata bagaimana kecintaan pada transportasi massal dapat diubah menjadi aksi sosial yang berdampak langsung bagi masyarakat. Para relawan secara rutin turun ke lapangan memberikan edukasi kepada pengendara jalan agar lebih disiplin dan mengutamakan keselamatan di perlintasan kereta api.''',
    additionalImages: ['assets/image/artikel_2.jpg', 'assets/image/artikel_3.jpg'],
  ),
  ArticleModel(
    title: 'Inspirasiku Jadi Relawan adalah Basarnas',
    excerpt: 'Apa yang pertama kali terpikirkan olehmu ketika melihat Basarnas di TV? Keberanian dan jiwa kemanusiaan...',
    date: '10 Oktober 2026',
    imageUrl: 'assets/image/artikel_2.jpg',
    content: '''Apa yang pertama kali terpikirkan olehmu ketika melihat Basarnas (Badan Nasional Pencarian dan Pertolongan) di TV? Keberanian, ketangguhan, dan jiwa kemanusiaan tanpa pamrih adalah hal utama yang melekat pada para pahlawan kemanusiaan ini.

Banyak relawan muda yang terinspirasi terjun ke dunia sosial dan kebencanaan setelah menyaksikan dedikasi Basarnas dalam mengevakuasi korban bencana alam maupun kecelakaan di berbagai pelosok nusantara.''',
    additionalImages: ['assets/image/artikel_4.jpg', 'assets/image/artikel_5.jpg'],
  ),
  ArticleModel(
    title: 'Sekolah Kehidupan Bernama Komunitas dan Relawan',
    excerpt: 'Setiap Oktober, kita kembali mengingat Sumpah Pemuda sebagai salah satu tonggak penting...',
    date: '02 Oktober 2026',
    imageUrl: 'assets/image/artikel_3.jpg',
    content: '''Setiap Oktober, kita kembali mengingat Sumpah Pemuda sebagai salah satu tonggak penting dalam perjalanan bangsa. Di era modern ini, semangat persatuan tersebut bertransformasi ke dalam berbagai bentuk aksi nyata melalui komunitas sosial dan gerakan kerelawanan.

Bergabung dengan komunitas relawan seringkali disebut sebagai "sekolah kehidupan yang sesungguhnya". Di sinilah tempat di mana kita belajar kepemimpinan dan kerja sama.''',
    additionalImages: ['assets/image/artikel_6.jpg', 'assets/image/artikel_7.jpg'],
  ),
  ArticleModel(
    title: 'Aksi Nyata Pemuda Membersihkan Lingkungan Pantai',
    excerpt: 'Kepedulian terhadap sampah plastik di pesisir pantai kini menjadi fokus utama gerakan relawan muda...',
    date: '28 September 2026',
    imageUrl: 'assets/image/artikel_4.jpg',
    content: '''Kepedulian terhadap sampah plastik di pesisir pantai kini menjadi fokus utama gerakan relawan muda di berbagai daerah pesisir nusantara demi menjaga ekosistem laut tetap lestari dan bersih dari limbah anorganik.
    
Aksi bersih-bersih pantai ini melibatkan ratusan pemuda dari berbagai latar belakang organisasi sosial.''',
    additionalImages: ['assets/image/artikel_8.jpg', 'assets/image/artikel_9.jpg'],
  ),
  ArticleModel(
    title: 'Mengajar di Pelosok Negeri: Senyum Anak-Anak Perbatasan',
    excerpt: 'Menjadi relawan pengajar memberikan pengalaman batin yang luar biasa saat melihat antusiasme anak-anak...',
    date: '20 September 2026',
    imageUrl: 'assets/image/artikel_5.jpg',
    content: '''Menjadi relawan pengajar memberikan pengalaman batin yang luar biasa saat melihat antusiasme anak-anak di daerah perbatasan dalam menuntut ilmu meskipun dengan fasilitas yang sangat terbatas.
    
Semangat mereka membakar motivasi kita untuk terus berbagi pengetahuan dan inspirasi.''',
    additionalImages: ['assets/image/artikel_10.jpg', 'assets/image/artikel_1.jpg'],
  ),
  ArticleModel(
    title: 'Peran Teknologi dalam Gerakan Kemanusiaan Modern',
    excerpt: 'Bagaimana platform digital dan aplikasi membantu mempercepat penyaluran bantuan saat bencana alam...',
    date: '15 September 2026',
    imageUrl: 'assets/image/artikel_6.jpg',
    content: '''Bagaimana platform digital dan aplikasi membantu mempercepat penyaluran bantuan saat bencana alam terjadi, menghubungkan donatur secara langsung dengan para relawan di posko darurat.
    
Inovasi teknologi kini menjadi pilar penting efisiensi logistik kemanusiaan di Indonesia.''',
    additionalImages: ['assets/image/artikel_2.jpg', 'assets/image/artikel_3.jpg'],
  ),
  ArticleModel(
    title: 'Kisah Inspiratif Dokter Muda yang Melayani Kesehatan Gratis',
    excerpt: 'Perjalanan tenaga medis keliling desa terpencil untuk memberikan layanan kesehatan bagi warga kurang mampu...',
    date: '08 September 2026',
    imageUrl: 'assets/image/artikel_7.jpg',
    content: '''Perjalanan tenaga medis keliling desa terpencil untuk memberikan layanan kesehatan bagi warga kurang mampu yang sulit menjangkau fasilitas rumah sakit umum.
    
Dedikasi tanpa pamrih ini memberikan secercah harapan kesehatan bagi masyarakat pelosok.''',
    additionalImages: ['assets/image/artikel_4.jpg', 'assets/image/artikel_5.jpg'],
  ),
  ArticleModel(
    title: 'Membangun Ketahanan Pangan Melalui Urban Farming Komunitas',
    excerpt: 'Memanfaatkan lahan kosong di perkotaan padat penduduk untuk menanam sayuran organik bersama warga...',
    date: '01 September 2026',
    imageUrl: 'assets/image/artikel_8.jpg',
    content: '''Memanfaatkan lahan kosong di perkotaan padat penduduk untuk menanam sayuran organik bersama warga demi menciptakan kemandirian pangan skala mikro.
    
Gerakan hijau ini juga mempererat kebersamaan antarwarga perkotaan.''',
    additionalImages: ['assets/image/artikel_6.jpg', 'assets/image/artikel_7.jpg'],
  ),
  ArticleModel(
    title: 'Seni dan Kreativitas untuk Pemulihan Trauma Anak Korban Bencana',
    excerpt: 'Metode trauma healing menggunakan pendekatan seni menggambar dan bermain bersama anak-anak...',
    date: '25 Agustus 2026',
    imageUrl: 'assets/image/artikel_9.jpg',
    content: '''Metode trauma healing menggunakan pendekatan seni menggambar, mendongeng, dan bermain bersama untuk mengembalikan senyum ceria anak-anak pasca bencana alam.
    
Pendekatan psikososial terbukti ampuh memulihkan mental anak-anak.''',
    additionalImages: ['assets/image/artikel_8.jpg', 'assets/image/artikel_10.jpg'],
  ),
  ArticleModel(
    title: 'Menyebarkan Semangat Literasi Lewat Taman Baca Keliling',
    excerpt: 'Motor Pustaka dan sepeda hias berisi buku cerita keliling kampung demi menumbuhkan minat baca anak...',
    date: '18 Agustus 2026',
    imageUrl: 'assets/image/artikel_10.jpg',
    content: '''Motor Pustaka dan sepeda hias berisi ratusan buku cerita keliling kampung demi menumbuhkan minat baca anak-anak sejak usia dini di pelosok daerah.
    
Literasi adalah jendela dunia yang harus dapat diakses oleh seluruh anak bangsa.''',
    additionalImages: ['assets/image/artikel_1.jpg', 'assets/image/artikel_2.jpg'],
  ),
];

// Halaman Detail Artikel
class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen(this.article, {super.key});
  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 12, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('Detail Artikel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: muted(context)),
                      const SizedBox(width: 6),
                      Text(article.date, style: TextStyle(fontSize: 12, color: muted(context))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: Image.asset(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    article.content,
                    style: TextStyle(fontSize: 15, height: 1.7, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 36),
                  const Text('Galeri Dokumentasi Kegiatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: article.additionalImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 240,
                            height: 180,
                            child: Image.asset(
                              article.additionalImages[index],
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Halaman Daftar Semua Artikel
class AllArticlesScreen extends StatelessWidget {
  const AllArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 12, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('Semua Artikel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: kBlogArticles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final article = kBlogArticles[index];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article))),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          child: Image.asset(
                            article.imageUrl,
                            width: 120,
                            height: 110,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                ),
                                const SizedBox(height: 6),
                                Text(article.date, style: TextStyle(fontSize: 11, color: muted(context))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final latest = s.query(upcomingOnly: true).take(10).toList();
    final popular = s.query(upcomingOnly: true, sort: EventSort.popular).take(5).toList();

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        // --- 1. Bagian Header Sapaan & Logo ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/image/logo_volunteer.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Halo, ${s.user?.firstName ?? 'Relawan'}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Text('Mari berkontribusi untuk Indonesia bersama-sama', style: TextStyle(color: muted(context), fontSize: 11.5)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                      tooltip: 'Achievement & Ranking',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AchievementScreen()));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.red, size: 22),
                      tooltip: 'Notifikasi',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        
        // --- 2. Hero Banner Full Lebar ---
        GestureDetector(
          onTap: () => s.openSearch('Semua'),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            child: SizedBox(
              height: 380,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 380,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/image/volunteer_banner.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Ambil peran jadi volunteer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              shadows: [Shadow(offset: Offset(0, 3), blurRadius: 10.0, color: Colors.black87)],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: const Text(
                              'Bergabunglah dengan ribuan volunteer lainnya untuk menciptakan perubahan nyata di sekitar kita.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                shadows: [Shadow(offset: Offset(0, 2), blurRadius: 6.0, color: Colors.black87)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))],
                            ),
                            child: const Text('Cari Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Konten di Bawah Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 3. Kategori ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark(context) ? Colors.grey.withOpacity(0.3) : Colors.grey.shade300,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: kCategories
                            .map((c) => InkWell(
                                  onTap: () => s.openSearch(c.name),
                                  child: SizedBox(
                                    width: 70,
                                    child: Column(children: [
                                      CircleAvatar(radius: 24, backgroundColor: primary, child: Icon(c.icon, color: Colors.white, size: 22)),
                                      const SizedBox(height: 6),
                                      Text(
                                        c.name,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ]),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 4. Bagian Event Terbaru ---
              const Text('Event Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...latest.map((e) => _LatestEventCard(e)),
              const SizedBox(height: 12),
              
              Center(
                child: SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 2,
                    ),
                    onPressed: () => s.openSearch('Semua'),
                    child: const Text('Lihat Semua >', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // --- 5. Bagian Paling Diminati ---
              const SectionHeader('Paling Diminati'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: popular.map((item) {
                      double itemWidth = (constraints.maxWidth - (4 * 14)) / 5;
                      if (itemWidth < 140) itemWidth = (constraints.maxWidth - 14) / 2;
                      return SizedBox(
                        width: itemWidth,
                        child: _PopularCard(item, cardWidth: itemWidth),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              // --- 6. Bagian Statistik ---
              Row(children: [
                Expanded(child: _CustomStatTile(Icons.stars_outlined, fmtNum(s.totalPoints), 'Poin')),
                const SizedBox(width: 12),
                Expanded(child: _CustomStatTile(Icons.verified_user_outlined, '${s.totalEvents}', 'Kegiatan')),
                const SizedBox(width: 12),
                Expanded(child: _CustomStatTile(Icons.timer_outlined, '${s.totalHours} Jam', 'Kontribusi')),
              ]),
              const SizedBox(height: 12),
              
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactScreen())),
                    child: const Text('Lihat dampak saya >', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // --- 7. Blog Volunteer ---
              const Center(
                child: Text('Blog Volunteer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = (constraints.maxWidth - 32) / 3;
                  if (cardWidth < 220) cardWidth = constraints.maxWidth;

                  return constraints.maxWidth > 700
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: kBlogArticles
                              .take(3)
                              .map((article) => SizedBox(
                                    width: cardWidth,
                                    child: _GridArticleCard(article),
                                  ))
                              .toList(),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => _GridArticleCard(kBlogArticles[index]),
                        );
                },
              ),
              const SizedBox(height: 24),

              Center(
                child: SizedBox(
                  width: 210,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 3,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllArticlesScreen()),
                      );
                    },
                    child: const Text(
                      'Baca artikel lainnya',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget Kartu Artikel Grid
class _GridArticleCard extends StatelessWidget {
  const _GridArticleCard(this.article);
  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark(context) ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.asset(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted(context), height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Baca lebih lanjut', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Kotak Statistik
class _CustomStatTile extends StatelessWidget {
  const _CustomStatTile(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: muted(context))),
        ],
      ),
    );
  }
}

class _LatestEventCard extends StatelessWidget {
  const _LatestEventCard(this.e);
  final EventModel e;

  @override
  Widget build(BuildContext context) {
    final catInfo = categoryInfo(e.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark(context) ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 140,
                    height: 120,
                    child: EventImage(e, width: 140, height: 120, radius: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(fmtDate(e.date), style: TextStyle(fontSize: 12, color: muted(context))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: softOf(context), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(catInfo.icon, size: 11, color: catInfo.color),
                            const SizedBox(width: 4),
                            Text(e.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catInfo.color)),
                          ],
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
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard(this.e, {required this.cardWidth});
  final EventModel e;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(e))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: EventImage(e, width: cardWidth, height: 180, radius: 12),
          ),
          const SizedBox(height: 10),
          Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          InfoRow(Icons.calendar_today_outlined, fmtDate(e.date), size: 11),
          InfoRow(Icons.group_outlined, '${s.participants(e)} peserta', size: 11),
        ],
      ),
    );
  }
}