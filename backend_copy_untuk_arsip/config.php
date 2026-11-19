<?php
/**
 * KONFIGURASI BACKEND VOLUNTEER
 * Default Laragon: user "root", password kosong. Ubah hanya jika berbeda.
 */
return [
    'db_host' => '127.0.0.1',
    'db_port' => 3306,
    'db_name' => 'volunteer_db',
    'db_user' => 'root',
    'db_pass' => '',

    // Batas ukuran gambar yang diunggah (byte). 5 MB.
    'max_image_bytes' => 5 * 1024 * 1024,

    // Masa berlaku token login (hari)
    'token_days' => 90,

    // true  = relawan boleh memverifikasi kehadirannya sendiri lewat menu "Verifikasi Kehadiran" (mode demo bawaan aplikasi).
    // false = HANYA penyelenggara yang dapat memverifikasi kehadiran (disarankan untuk penggunaan nyata).
    'allow_self_verify' => true,

    // true = tampilkan pesan error detail (untuk belajar/debug). Ubah ke false saat produksi.
    'debug' => true,
];
