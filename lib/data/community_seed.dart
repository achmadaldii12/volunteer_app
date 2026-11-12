import '../models/models.dart';
import '../models/community.dart';

/// Id admin komunitas bawaan (akun demo). Admin dapat membuat / menghapus
/// pengumuman dan meninjau laporan. Di aplikasi dengan backend, peran ini
/// berasal dari server.
const String kDefaultAdminId = 'u_demo';

class CommunitySeed {
  final List<CommMessage> messages;
  final List<Announcement> announcements;
  final List<CommPoll> polls;
  CommunitySeed(this.messages, this.announcements, this.polls);
}

const List<String> _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _tgl(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Nama relawan awal (cocok dengan leaderboard_seed.dart).
const Map<String, String> _names = {
  'u_seed_1': 'Achmad Aldi',
  'u_seed_2': 'Siti Rahmawati',
  'u_seed_3': 'Budi Santoso',
  'u_seed_4': 'Dewi Lestari',
  'u_seed_5': 'Deni Pratama',
  'u_seed_6': 'Rina Wijaya',
  'u_seed_7': 'Fajar Nugroho',
  'u_seed_8': 'Maya Putri',
  'u_seed_9': 'Rizky Ramadhan',
  'u_seed_10': 'Nadia Safitri',
  'u_seed_11': 'Agus Salim',
  'u_seed_12': 'Linda Kusuma',
};

CommunitySeed buildCommunitySeed(List<EventModel> events) {
  final now = DateTime.now();

  EventModel pick(String cat, [int skip = 0]) {
    final l = events.where((e) => e.category == cat).toList();
    if (l.isEmpty) return events.first;
    return l[skip % l.length];
  }

  final eco = pick('Lingkungan');
  final edu = pick('Edukasi');
  final soc = pick('Sosial');
  EventModel tree = eco;
  for (final e in events) {
    if (e.title.contains('1000')) tree = e;
  }

  CommMessage m(String id, String room, String sender, String text, int minutesAgo,
      {String? eventId, String? replyTo, Map<String, List<String>>? reactions}) {
    return CommMessage(
      id: id,
      roomId: room,
      senderId: sender,
      senderName: _names[sender] ?? 'Relawan',
      text: text,
      type: eventId == null ? 'text' : 'invite',
      eventId: eventId,
      replyToId: replyTo,
      createdAt: now.subtract(Duration(minutes: minutesAgo)),
      reactions: reactions,
    );
  }

  final messages = <CommMessage>[
    // ---------------- Umum
    m('cm_seed_1', 'umum', 'u_seed_2', 'Halo relawan! Ada yang mau ikut aksi tanam mangrove minggu ini?', 95,
        reactions: {
          '❤️': ['u_seed_3', 'u_seed_4', 'u_seed_6', 'u_seed_8', 'u_seed_10'],
          '👍': ['u_seed_5', 'u_seed_7'],
        }),
    m('cm_seed_2', 'umum', 'u_seed_3', 'Ayo ajak relawan ke event ${eco.title}! 🎉', 80,
        eventId: eco.id,
        reactions: {
          '❤️': ['u_seed_2', 'u_seed_4', 'u_seed_5', 'u_seed_9', 'u_seed_11', 'u_seed_12', 'u_seed_6', 'u_seed_8'],
          '🔥': ['u_seed_10'],
        }),
    m('cm_seed_3', 'umum', 'u_seed_4', 'Sudah daftar! Sampai ketemu di lokasi 🙌', 70,
        replyTo: 'cm_seed_2',
        reactions: {
          '👍': ['u_seed_3', 'u_seed_2'],
        }),
    m('cm_seed_4', 'umum', 'u_seed_6', 'Terima kasih admin atas info terbarunya, semangat semua!', 40),
    // ---------------- Lingkungan
    m('cm_seed_5', 'lingkungan', 'u_seed_6',
        'Tips buat yang baru pertama ikut bersih pantai: bawa topi, tabir surya, dan botol minum sendiri ya.', 300,
        reactions: {
          '👍': ['u_seed_3', 'u_seed_5', 'u_seed_8'],
          '🙏': ['u_seed_2'],
        }),
    m('cm_seed_6', 'lingkungan', 'u_seed_5', 'Kalau ada yang punya sarung tangan kerja bekas, boleh dibawa ya 🧤', 260),
    m('cm_seed_7', 'lingkungan', 'u_seed_2', 'Open recruitment penanaman pohon sudah dibuka, yuk gabung!', 200,
        eventId: tree.id,
        reactions: {
          '❤️': ['u_seed_4', 'u_seed_6'],
        }),
    // ---------------- Pendidikan
    m('cm_seed_8', 'pendidikan', 'u_seed_8', 'Kami butuh relawan pengajar untuk kelas literasi digital akhir pekan ini.', 420,
        eventId: edu.id,
        reactions: {
          '👏': ['u_seed_2', 'u_seed_7', 'u_seed_9'],
        }),
    m('cm_seed_9', 'pendidikan', 'u_seed_7', 'Ada yang bisa bantu menyiapkan modul belajar untuk anak SD?', 380),
    // ---------------- Sosial
    m('cm_seed_10', 'sosial', 'u_seed_10', 'Donasi buku dan pakaian layak pakai untuk panti asuhan sedang dibuka.', 600,
        eventId: soc.id,
        reactions: {
          '❤️': ['u_seed_2', 'u_seed_3', 'u_seed_4', 'u_seed_11'],
        }),
    m('cm_seed_11', 'sosial', 'u_seed_11', 'Terima kasih semua yang sudah berdonasi minggu lalu 🙏', 560),
  ];

  const adminName = 'Admin Volunteer';
  final announcements = <Announcement>[
    Announcement(
      id: 'an_seed_1',
      title: tree.title,
      body: 'Halo relawan! Jangan lupa persiapkan diri untuk kegiatan ${tree.title} '
          'pada ${_tgl(tree.date)}. Hadir 15 menit lebih awal, kenakan pakaian yang nyaman, '
          'dan bawa botol minum sendiri. Sampai jumpa di lokasi!',
      authorId: kDefaultAdminId,
      authorName: adminName,
      important: true,
      eventId: tree.id,
      createdAt: now.subtract(const Duration(hours: 20)),
    ),
    Announcement(
      id: 'an_seed_2',
      title: 'Pembaruan Pedoman Komunitas',
      body: 'Mohon jaga kesantunan dalam berdiskusi. Dilarang menyebarkan data pribadi anggota, '
          'spam, dan ujaran kebencian. Gunakan fitur Laporkan atau Blokir bila menemukan pelanggaran. '
          'Pelanggaran berulang dapat dikenakan sanksi.',
      authorId: kDefaultAdminId,
      authorName: adminName,
      important: true,
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    Announcement(
      id: 'an_seed_3',
      title: 'Selamat Datang Relawan Baru',
      body: 'Selamat bergabung di Komunitas Relawan! Kenali sesama relawan di menu Anggota, '
          'ikuti ruang diskusi sesuai minatmu, dan ajak teman ke kegiatan favoritmu.',
      authorId: kDefaultAdminId,
      authorName: adminName,
      createdAt: now.subtract(const Duration(days: 6)),
    ),
  ];

  final polls = <CommPoll>[
    CommPoll(
      id: 'poll_seed_1',
      question: 'Kegiatan volunteer berikutnya ingin mengadakan apa?',
      options: ['Aksi Bersih Pantai', 'Penanaman Pohon', 'Mengajar Anak-anak'],
      creatorId: kDefaultAdminId,
      creatorName: adminName,
      createdAt: now.subtract(const Duration(days: 1)),
      endsAt: now.add(const Duration(days: 2, hours: 5)),
      votes: {
        'u_seed_2': 0, 'u_seed_3': 0, 'u_seed_5': 0, 'u_seed_6': 0, 'u_seed_10': 0, 'u_seed_12': 0,
        'u_seed_4': 1, 'u_seed_7': 1, 'u_seed_11': 1,
        'u_seed_9': 2,
      },
    ),
    CommPoll(
      id: 'poll_seed_2',
      question: 'Waktu kegiatan yang paling nyaman buat kamu?',
      options: ['Pagi (07.00 - 11.00)', 'Siang (12.00 - 15.00)', 'Sore (15.00 - 18.00)'],
      creatorId: kDefaultAdminId,
      creatorName: adminName,
      createdAt: now.subtract(const Duration(days: 9)),
      endsAt: now.subtract(const Duration(days: 2)),
      votes: {
        'u_seed_2': 0, 'u_seed_3': 0, 'u_seed_4': 0, 'u_seed_5': 0, 'u_seed_6': 0, 'u_seed_8': 0,
        'u_seed_7': 2, 'u_seed_9': 2,
        'u_seed_10': 1,
      },
    ),
  ];

  return CommunitySeed(messages, announcements, polls);
}
