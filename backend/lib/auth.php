<?php
// ============================================================================
// AUTENTIKASI: register, login, profil, ganti password, hapus akun
// ============================================================================

function route_auth_register() {
    $b = body();
    $name = trim((string) arr_get($b, 'name'));
    $email = strtolower(trim((string) arr_get($b, 'email')));
    $pass = (string) arr_get($b, 'password');
    if ($name === '') fail('Nama wajib diisi');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Format email tidak valid');
    if (strlen($pass) < 6) fail('Password minimal 6 karakter');
    if (one('SELECT id FROM users WHERE email = ?', array($email))) fail('Email sudah terdaftar, silakan login', 409);

    $id = new_id('u');
    // Pendaftaran lewat aplikasi SELALU menjadi relawan. Akun penyelenggara dibuat admin (lihat PANDUAN).
    q('INSERT INTO users (id, name, email, password_hash, role) VALUES (?,?,?,?,?)',
        array($id, $name, $email, password_hash($pass, PASSWORD_BCRYPT), 'volunteer'));
    $row = one('SELECT * FROM users WHERE id = ?', array($id));
    json_out(array('ok' => true, 'token' => issue_token($id), 'user' => user_json($row, true)));
}

function route_auth_login() {
    $b = body();
    $email = strtolower(trim((string) arr_get($b, 'email')));
    $pass = (string) arr_get($b, 'password');
    $row = one('SELECT * FROM users WHERE email = ?', array($email));
    if (!$row) fail('Akun dengan email tersebut tidak ditemukan', 404);
    if (!password_verify($pass, $row['password_hash'])) fail('Password salah', 401);
    json_out(array('ok' => true, 'token' => issue_token($row['id']), 'user' => user_json($row, true)));
}

function route_auth_me() {
    $u = current_user();
    json_out(array('ok' => true, 'user' => user_json($u, true)));
}

function route_auth_logout() {
    $t = bearer_token();
    if ($t !== '') q('DELETE FROM api_tokens WHERE token_hash = ?', array(hash('sha256', $t)));
    json_out(array('ok' => true));
}

/** Ganti password. Dipanggil otomatis oleh aplikasi setelah relawan mengganti password. */
function route_auth_password() {
    $u = current_user();
    $b = body();
    $new = (string) arr_get($b, 'newPassword');
    if (strlen($new) < 6) fail('Password baru minimal 6 karakter');
    q('UPDATE users SET password_hash = ? WHERE id = ?', array(password_hash($new, PASSWORD_BCRYPT), $u['id']));
    json_out(array('ok' => true));
}

/** Hapus akun beserta seluruh datanya. */
function route_auth_delete() {
    $u = current_user();
    $id = $u['id'];
    if ($u['role'] === 'organizer') fail('Akun penyelenggara tidak dapat dihapus dari aplikasi', 403);
    if ($u['avatar_url'] !== '') delete_upload($u['avatar_url']);
    q('DELETE FROM registrations WHERE user_id = ?', array($id));
    q('DELETE FROM notifications WHERE user_id = ?', array($id));
    q('DELETE FROM point_entries WHERE user_id = ?', array($id));
    q('DELETE FROM certificates WHERE user_id = ?', array($id));
    q('DELETE FROM feedbacks WHERE user_id = ?', array($id));
    q('DELETE FROM user_kv WHERE user_id = ?', array($id));
    q('UPDATE comm_messages SET is_deleted = 1 WHERE sender_id = ?', array($id));
    q('DELETE FROM api_tokens WHERE user_id = ?', array($id));
    q('DELETE FROM users WHERE id = ?', array($id));
    json_out(array('ok' => true));
}

/** Unggah gambar langsung (multipart "file" atau JSON {kind, data}). Mengembalikan URL. */
function route_upload() {
    $u = current_user();
    $kind = isset($_POST['kind']) ? (string) $_POST['kind'] : (string) arr_get(body(), 'kind', 'chat');
    if (!in_array($kind, array('events', 'avatars', 'org', 'chat'), true)) $kind = 'chat';
    $data = '';
    if (!empty($_FILES['file']['tmp_name']) && is_uploaded_file($_FILES['file']['tmp_name'])) {
        $data = base64_encode(file_get_contents($_FILES['file']['tmp_name']));
    } else {
        $data = (string) arr_get(body(), 'data');
    }
    if ($data === '') fail('Tidak ada gambar yang dikirim');
    $rel = save_image_data($data, $kind, $u['id']);
    if ($rel === null) fail('Gambar tidak valid (hanya JPG/PNG/WEBP/GIF, maks 5 MB)');
    json_out(array('ok' => true, 'path' => $rel, 'url' => url_out($rel)));
}
