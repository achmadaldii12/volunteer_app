<?php
// ============================================================================
// PINTU MASUK API VOLUNTEER
// Semua permintaan: http://<alamat>/volunteer_backend/api.php?r=<rute>
// ============================================================================
error_reporting(E_ALL);
ini_set('display_errors', '0'); // error ditangkap di bawah dan dikirim sebagai JSON

require __DIR__ . '/lib/core.php';
require __DIR__ . '/lib/auth.php';
require __DIR__ . '/lib/sync.php';

cors();
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

set_exception_handler(function ($e) {
    $msg = cfg('debug') ? $e->getMessage() : 'Terjadi kesalahan pada server';
    json_out(array('ok' => false, 'error' => $msg), 500);
});

$route = isset($_GET['r']) ? trim($_GET['r'], '/') : '';
$method = isset($_SERVER['REQUEST_METHOD']) ? $_SERVER['REQUEST_METHOD'] : 'GET';

switch ($route) {
    case '':
    case 'health':
        $dbOk = false;
        try { db()->query('SELECT 1'); $dbOk = true; } catch (Exception $e) { $dbOk = false; }
        json_out(array('ok' => true, 'app' => 'Volunteer API', 'database' => $dbOk, 'time' => gmdate('c'),
            'baseUrl' => base_url()));
        break;
    case 'auth/register': route_auth_register(); break;
    case 'auth/login':    route_auth_login(); break;
    case 'auth/me':       route_auth_me(); break;
    case 'auth/logout':   route_auth_logout(); break;
    case 'auth/password': route_auth_password(); break;
    case 'auth/delete':   route_auth_delete(); break;
    case 'upload':        route_upload(); break;
    case 'sync/pull':     route_sync_pull(); break;
    case 'sync/push':     route_sync_push(); break;
    default:
        fail('Rute tidak ditemukan: ' . $route, 404);
}
