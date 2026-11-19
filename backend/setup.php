<?php
// ============================================================================
// SETUP SEKALI JALAN  ->  buka  http://localhost/volunteer_backend/setup.php
// Membuat database, semua tabel, dan akun penyelenggara contoh.
// Hanya dapat dibuka dari komputer ini (localhost). Hapus file ini saat produksi.
// ============================================================================
error_reporting(E_ALL);
ini_set('display_errors', '1');

$ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
if (!in_array($ip, array('127.0.0.1', '::1'), true) && php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit('setup.php hanya dapat dibuka dari localhost.');
}

$cfg = require __DIR__ . '/config.php';
$log = array();
$errors = array();

function h($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); }

try {
    $pdo = new PDO('mysql:host=' . $cfg['db_host'] . ';port=' . $cfg['db_port'] . ';charset=utf8mb4',
        $cfg['db_user'], $cfg['db_pass'], array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION));
    $pdo->exec('CREATE DATABASE IF NOT EXISTS `' . $cfg['db_name'] . '` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    $pdo->exec('USE `' . $cfg['db_name'] . '`');
    $log[] = 'Database "' . $cfg['db_name'] . '" siap.';

    $sql = file_get_contents(__DIR__ . '/database.sql');
    $sql = preg_replace('/^\s*--.*$/m', '', $sql);
    $n = 0;
    foreach (explode(';', $sql) as $stmt) {
        $stmt = trim($stmt);
        if ($stmt === '') continue;
        $pdo->exec($stmt);
        $n++;
    }
    $log[] = $n . ' tabel/perintah SQL berhasil dijalankan.';

    // Akun penyelenggara contoh (id harus sama dengan di aplikasi: u_org_demo)
    $exists = $pdo->prepare('SELECT id FROM users WHERE id = ?');
    $exists->execute(array('u_org_demo'));
    if (!$exists->fetch()) {
        $ins = $pdo->prepare('INSERT INTO users (id, name, email, password_hash, phone, city, bio, role) VALUES (?,?,?,?,?,?,?,?)');
        $ins->execute(array('u_org_demo', 'Volunteer Indonesia', 'organizer@volunteer.id',
            password_hash('organizer123', PASSWORD_BCRYPT), '031-5551234', 'Surabaya', 'Akun penyelenggara contoh.', 'organizer'));
        $log[] = 'Akun penyelenggara contoh dibuat: organizer@volunteer.id / organizer123';
    } else {
        $log[] = 'Akun penyelenggara contoh sudah ada.';
    }

    // Tambah akun penyelenggara baru lewat form di bawah
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $nm = trim(isset($_POST['name']) ? $_POST['name'] : '');
        $em = strtolower(trim(isset($_POST['email']) ? $_POST['email'] : ''));
        $pw = isset($_POST['password']) ? $_POST['password'] : '';
        if ($nm === '' || !filter_var($em, FILTER_VALIDATE_EMAIL) || strlen($pw) < 6) {
            $errors[] = 'Isi nama, email yang valid, dan password minimal 6 karakter.';
        } else {
            $c = $pdo->prepare('SELECT id FROM users WHERE email = ?');
            $c->execute(array($em));
            if ($c->fetch()) {
                $errors[] = 'Email sudah terdaftar.';
            } else {
                $id = 'u_org_' . bin2hex(random_bytes(6));
                $pdo->prepare('INSERT INTO users (id, name, email, password_hash, role) VALUES (?,?,?,?,?)')
                    ->execute(array($id, $nm, $em, password_hash($pw, PASSWORD_BCRYPT), 'organizer'));
                $log[] = 'Akun penyelenggara baru dibuat: ' . $em;
            }
        }
    }
    $cnt = $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
    $log[] = 'Jumlah akun saat ini: ' . $cnt;
} catch (Exception $e) {
    $errors[] = $e->getMessage();
}

$uploadsOk = is_writable(__DIR__ . '/uploads/events') && is_writable(__DIR__ . '/uploads/avatars');
?>
<!doctype html>
<html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Setup Volunteer Backend</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;max-width:680px;margin:30px auto;padding:0 16px;color:#222}
h1{color:#C62828}.ok{background:#e8f5e9;border-left:4px solid #2e7d32;padding:8px 12px;margin:6px 0}
.err{background:#ffebee;border-left:4px solid #c62828;padding:8px 12px;margin:6px 0}
input{padding:8px;margin:4px 0;width:100%;box-sizing:border-box}button{background:#C62828;color:#fff;border:0;padding:10px 18px;border-radius:6px;cursor:pointer}
code{background:#f3f3f3;padding:2px 6px;border-radius:4px}
</style></head><body>
<h1>Setup Volunteer Backend</h1>
<?php foreach ($log as $l): ?><div class="ok"><?= h($l) ?></div><?php endforeach; ?>
<?php foreach ($errors as $e): ?><div class="err"><?= h($e) ?></div><?php endforeach; ?>
<?php if (!$uploadsOk): ?><div class="err">Folder <code>uploads</code> belum bisa ditulis. Pastikan folder uploads tidak read-only.</div>
<?php else: ?><div class="ok">Folder uploads dapat ditulis.</div><?php endif; ?>
<?php if (!$errors): ?>
<p>Selesai. Cek API: <a href="api.php?r=health">api.php?r=health</a> (harus menampilkan <code>"database":true</code>).</p>
<h3>Tambah akun penyelenggara baru</h3>
<form method="post">
<input name="name" placeholder="Nama organisasi"><input name="email" placeholder="Email"><input name="password" type="password" placeholder="Password (min. 6 karakter)">
<button type="submit">Buat akun penyelenggara</button></form>
<p style="color:#777;font-size:13px">Setelah selesai, hapus <code>setup.php</code> bila server akan dibuka ke internet.</p>
<?php endif; ?>
</body></html>
