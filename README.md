# Volunteer (Flutter)

Aplikasi kerelawanan "Bersama, Kita Memberi Dampak" - dibuat sesuai wireframe 12 layar.
Versi ini **tidak membutuhkan backend**: data contoh dan data pengguna disimpan lokal
(shared_preferences). Seluruh logika ada di `lib/providers/app_state.dart`.

## Menjalankan
```
flutter create .        # sekali saja, membuat folder android/ios/web (lib & pubspec tidak tertimpa)
flutter pub get
flutter run -d chrome   # atau pilih emulator/HP
flutter test
```
Akun demo: `aldi@email.com` / `123456` (ada tombol "Isi akun demo" di halaman Login).

## 12 layar sesuai wireframe
1 Splash - 2 Login - 3 Register - 4 Beranda - 5 Cari Event - 6 Detail Event -
7 Pendaftaran & QR - 8 Aktivitas Saya - 9 Achievement - 10 Dampak Sosial -
11 Sertifikat & Feedback - 12 Profil

Tambahan: Notifikasi, Semua Badge, Riwayat Kegiatan, Edit Profil, Pengaturan
(mode gelap, ubah password, reset data), Bantuan & FAQ.

## Struktur
- `core/` tema, kategori, utilitas format & validasi
- `models/` model data + JSON, definisi badge
- `data/seed_data.dart` data contoh (12 kegiatan, akun demo)
- `providers/app_state.dart` auth, pencarian, pendaftaran, poin, badge, peringkat, notifikasi
- `widgets/common.dart` komponen UI bersama
- `screens/` seluruh halaman
- `assets/image/` foto kegiatan
- `test/` unit test logika

## Alur fitur
Login/Daftar (validasi) -> cari & filter kegiatan -> detail -> daftar (kuota dicek) ->
tiket QR -> "Simulasikan Hadir (demo)" di Aktivitas Saya -> poin, jam, dampak, badge,
peringkat, sertifikat, dan notifikasi ikut bertambah -> kirim feedback.
