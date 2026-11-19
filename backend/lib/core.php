<?php
// ============================================================================
// CORE: koneksi database, helper JSON, CORS, token, upload gambar
// ============================================================================

$GLOBALS['VOL_CFG'] = require __DIR__ . '/../config.php';

function cfg($key, $default = null) {
    return isset($GLOBALS['VOL_CFG'][$key]) ? $GLOBALS['VOL_CFG'][$key] : $default;
}

function db() {
    static $pdo = null;
    if ($pdo !== null) return $pdo;
    $dsn = 'mysql:host=' . cfg('db_host') . ';port=' . cfg('db_port') . ';dbname=' . cfg('db_name') . ';charset=utf8mb4';
    $pdo = new PDO($dsn, cfg('db_user'), cfg('db_pass'), array(
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ));
    return $pdo;
}

function q($sql, $params = array()) {
    $st = db()->prepare($sql);
    $st->execute($params);
    return $st;
}
function one($sql, $params = array()) {
    $r = q($sql, $params)->fetch();
    return $r === false ? null : $r;
}
function all($sql, $params = array()) {
    return q($sql, $params)->fetchAll();
}

/** INSERT ... ON DUPLICATE KEY UPDATE dari array kolom => nilai. */
function upsert($table, $row, $ignoreOnly = false) {
    $cols = array_keys($row);
    $ph = implode(',', array_fill(0, count($cols), '?'));
    $names = '`' . implode('`,`', $cols) . '`';
    if ($ignoreOnly) {
        $sql = "INSERT IGNORE INTO `$table` ($names) VALUES ($ph)";
    } else {
        $upd = array();
        foreach ($cols as $c) {
            if ($c === 'id' || $c === 'user_id' && $table === 'org_profiles') continue;
            $upd[] = "`$c`=VALUES(`$c`)";
        }
        $sql = "INSERT INTO `$table` ($names) VALUES ($ph) ON DUPLICATE KEY UPDATE " . implode(',', $upd);
    }
    q($sql, array_values($row));
}

// ------------------------------------------------------------------ respons
function cors() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Auth-Token');
    header('Access-Control-Max-Age: 86400');
}

function json_out($data, $code = 200) {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

function fail($message, $code = 400, $extra = array()) {
    json_out(array_merge(array('ok' => false, 'error' => $message), $extra), $code);
}

function body() {
    static $b = null;
    if ($b !== null) return $b;
    $raw = file_get_contents('php://input');
    $b = array();
    if ($raw !== false && $raw !== '') {
        $d = json_decode($raw, true);
        if (is_array($d)) $b = $d;
    }
    return $b;
}

function arr_get($a, $k, $d = '') {
    return (is_array($a) && isset($a[$k]) && $a[$k] !== null) ? $a[$k] : $d;
}

// ----------------------------------------------------------------- tanggal
function sqldt($iso) {
    if (!is_string($iso) || $iso === '') return null;
    try {
        $d = new DateTime($iso);
        return $d->format('Y-m-d H:i:s');
    } catch (Exception $e) {
        return null;
    }
}

function new_id($prefix) {
    return $prefix . '_' . bin2hex(random_bytes(8));
}

// -------------------------------------------------------------------- URL
function base_url() {
    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443);
    $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
    $dir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
    return ($https ? 'https://' : 'http://') . $host . $dir;
}

/** Path relatif "uploads/..." -> URL absolut sesuai alamat yang dipakai klien. */
function url_out($v) {
    if (is_string($v) && strpos($v, 'uploads/') === 0) return base_url() . '/' . $v;
    return $v;
}

// ------------------------------------------------------------------ token
function bearer_token() {
    $h = '';
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) $h = $_SERVER['HTTP_AUTHORIZATION'];
    elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) $h = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    elseif (function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strtolower($k) === 'authorization') $h = $v;
        }
    }
    if ($h !== '' && preg_match('/Bearer\s+(\S+)/i', $h, $m)) return $m[1];
    if (!empty($_SERVER['HTTP_X_AUTH_TOKEN'])) return $_SERVER['HTTP_X_AUTH_TOKEN'];
    if (!empty($_GET['token'])) return $_GET['token'];
    return '';
}

function issue_token($userId) {
    $plain = bin2hex(random_bytes(32));
    $days = (int) cfg('token_days', 90);
    q('INSERT INTO api_tokens (token_hash, user_id, expires_at) VALUES (?,?,DATE_ADD(NOW(), INTERVAL ' . $days . ' DAY))',
        array(hash('sha256', $plain), $userId));
    return $plain;
}

function current_user($required = true) {
    $t = bearer_token();
    if ($t === '') {
        if ($required) fail('Belum login', 401);
        return null;
    }
    $row = one('SELECT u.* FROM api_tokens t JOIN users u ON u.id = t.user_id WHERE t.token_hash = ? AND t.expires_at > NOW()',
        array(hash('sha256', $t)));
    if (!$row) {
        if ($required) fail('Sesi berakhir, silakan login ulang', 401);
        return null;
    }
    return $row;
}

function user_json($row, $full) {
    return array(
        'id' => $row['id'],
        'name' => $row['name'],
        'email' => $full ? $row['email'] : '',
        'phone' => $full ? $row['phone'] : '',
        'city' => $row['city'],
        'bio' => (string) $row['bio'],
        'role' => $row['role'],
        'pastEvents' => (int) $row['past_events'],
        'pastHours' => (int) $row['past_hours'],
        'pastPoints' => (int) $row['past_points'],
        'pastImpact' => (int) $row['past_impact'],
        'avatarUrl' => url_out($row['avatar_url']),
    );
}

// ----------------------------------------------------------------- gambar
function image_ext_from_bytes($bytes) {
    if (strlen($bytes) < 12) return null;
    if (substr($bytes, 0, 3) === "\xFF\xD8\xFF") return array('jpg', 'image/jpeg');
    if (substr($bytes, 0, 8) === "\x89PNG\r\n\x1A\n") return array('png', 'image/png');
    if (substr($bytes, 0, 4) === 'RIFF' && substr($bytes, 8, 4) === 'WEBP') return array('webp', 'image/webp');
    if (substr($bytes, 0, 3) === 'GIF') return array('gif', 'image/gif');
    return null;
}

/**
 * Simpan data URI / base64 menjadi file di uploads/<folder>/.
 * Mengembalikan path relatif (mis. "uploads/events/ev_xxx.jpg") atau null bila tidak valid.
 */
function save_image_data($dataUri, $folder, $userId) {
    if (!is_string($dataUri) || $dataUri === '') return null;
    $b64 = $dataUri;
    if (strpos($dataUri, 'data:') === 0) {
        $pos = strpos($dataUri, ',');
        if ($pos === false) return null;
        $b64 = substr($dataUri, $pos + 1);
    }
    $bytes = base64_decode($b64, true);
    if ($bytes === false || $bytes === '') return null;
    if (strlen($bytes) > (int) cfg('max_image_bytes')) return null;
    $info = image_ext_from_bytes($bytes);
    if ($info === null) return null;
    $allowed = array('events', 'avatars', 'org', 'chat');
    if (!in_array($folder, $allowed, true)) $folder = 'chat';
    $dir = __DIR__ . '/../uploads/' . $folder;
    if (!is_dir($dir)) @mkdir($dir, 0775, true);
    $name = substr(preg_replace('/[^A-Za-z0-9]/', '', $userId), 0, 12) . '_' . bin2hex(random_bytes(6)) . '.' . $info[0];
    if (file_put_contents($dir . '/' . $name, $bytes) === false) return null;
    $rel = 'uploads/' . $folder . '/' . $name;
    try {
        q('INSERT INTO uploads (user_id, kind, path, mime, size_bytes) VALUES (?,?,?,?,?)',
            array($userId, $folder, $rel, $info[1], strlen($bytes)));
    } catch (Exception $e) { /* log saja, tidak fatal */ }
    return $rel;
}

function delete_upload($rel) {
    if (!is_string($rel) || strpos($rel, 'uploads/') !== 0 || strpos($rel, '..') !== false) return;
    $p = __DIR__ . '/../' . $rel;
    if (is_file($p)) @unlink($p);
}

/** Masukan gambar dari klien -> nilai yang disimpan di DB. */
function img_in($v, $folder, $userId) {
    if (!is_string($v) || $v === '') return '';
    if (strpos($v, 'data:') === 0) {
        $rel = save_image_data($v, $folder, $userId);
        return $rel === null ? '' : $rel;
    }
    // URL absolut milik server ini -> simpan sebagai path relatif
    if (preg_match('~^https?://[^/]+/.*?(uploads/(?:events|avatars|org|chat)/[A-Za-z0-9_.\-]+)$~', $v, $m)) return $m[1];
    return $v; // mis. "assets/image/event_3.jpg"
}
