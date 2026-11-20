<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Backend untuk aplikasi Flutter "Volunteer".
 * Protokolnya mengikuti lib/services/sync_service.dart:
 *   POST auth/login | auth/register | auth/logout | auth/password | auth/delete
 *   POST sync/push  (kirim perubahan)    GET sync/pull (ambil data terbaru)
 */
class SyncController extends Controller
{
    private const ORDER = [
        'user', 'avatar', 'event', 'reg', 'notif', 'point', 'cert', 'orgmsg',
        'feedback', 'cmsg', 'announce', 'poll', 'report', 'orgprofile', 'kv',
    ];

    // ------------------------------------------------------------ helpers
    private function fail(string $msg, int $code = 400): JsonResponse
    {
        return response()->json(['ok' => false, 'error' => $msg], $code);
    }

    /** Baca body JSON mentah (menghindari middleware yang mengubah "" menjadi null). */
    private function body(Request $r): array
    {
        $d = json_decode($r->getContent(), true);
        return is_array($d) ? $d : [];
    }

    private function s($v, int $max = 255): string
    {
        return mb_substr((string) ($v ?? ''), 0, $max);
    }

    private function dt($v): ?string
    {
        if (!$v) {
            return null;
        }
        try {
            return Carbon::parse($v)->utc()->format('Y-m-d H:i:s');
        } catch (\Throwable $e) {
            return null;
        }
    }

    private function json($v): string
    {
        return json_encode($v, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    private function dec(?string $s): array
    {
        $d = $s ? json_decode($s, true) : null;
        return is_array($d) ? $d : [];
    }

    private function abs(?string $path, string $host): string
    {
        $path = (string) $path;
        if ($path === '') {
            return '';
        }
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        return $this->mediaUrl($path, $host);
    }

    /**
     * "uploads/events/x.jpg" -> "http://host/api/media/events/x.jpg".
     * Lewat /api supaya header CORS ikut terkirim (wajib agar gambar tampil di Flutter Web/Chrome).
     */
    private function mediaUrl(string $path, string $host): string
    {
        $path = ltrim($path, '/');
        if (str_starts_with($path, 'uploads/')) {
            $path = substr($path, strlen('uploads/'));
        }
        return $host . '/api/media/' . $path;
    }

    /** Ubah nilai "uploads/..." di level atas menjadi URL lengkap sesuai host permintaan. */
    private function absolutize(array $j, string $host): array
    {
        foreach ($j as $k => $v) {
            if (is_string($v) && str_starts_with($v, 'uploads/')) {
                $j[$k] = $this->mediaUrl($v, $host);
            }
        }
        return $j;
    }

    /** Simpan gambar data-URI ke public/uploads/<folder>/ . Mengembalikan [path, mime, size] atau null. */
    private function saveDataUri(string $uri, string $folder, string $name): ?array
    {
        if (!str_starts_with($uri, 'data:image/')) {
            return null;
        }
        $p = strpos($uri, ';base64,');
        if ($p === false) {
            return null;
        }
        $mime = substr($uri, 5, $p - 5);
        $bin = base64_decode(substr($uri, $p + 8), true);
        if ($bin === false || $bin === '' || strlen($bin) > 8 * 1024 * 1024) {
            return null;
        }
        $ext = match ($mime) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            'image/gif' => 'gif',
            default => 'jpg',
        };
        $name = preg_replace('/[^A-Za-z0-9_-]/', '_', $name);
        $dir = public_path('uploads/' . $folder);
        File::ensureDirectoryExists($dir);
        foreach (glob($dir . '/' . $name . '-*') ?: [] as $old) {
            @unlink($old);
        }
        $rel = 'uploads/' . $folder . '/' . $name . '-' . substr(md5($bin), 0, 10) . '.' . $ext;
        file_put_contents(public_path($rel), $bin);
        return [$rel, $mime, strlen($bin)];
    }

    private function logUpload(string $userId, string $kind, array $saved): void
    {
        DB::table('uploads')->insert([
            'user_id' => $userId,
            'kind' => $kind,
            'path' => $saved[0],
            'mime' => $saved[1],
            'size_bytes' => $saved[2],
        ]);
    }

    /** Gambar data-URI di level atas payload -> file; nilainya diganti path relatif. */
    private function externalize(array $j, string $folder, string $id, string $userId): array
    {
        foreach ($j as $k => $v) {
            if (is_string($v) && str_starts_with($v, 'data:image/')) {
                $saved = $this->saveDataUri($v, $folder, $id . '_' . $k);
                if ($saved) {
                    $this->logUpload($userId, $folder, $saved);
                    $j[$k] = $saved[0];
                } else {
                    $j[$k] = '';
                }
            }
        }
        return $j;
    }

    private function userJson(User $u, string $host, bool $private): array
    {
        return [
            'id' => $u->id,
            'name' => $u->name,
            'email' => $private ? $u->email : '',
            'phone' => $private ? ($u->phone ?? '') : '',
            'city' => $u->city ?? '',
            'bio' => $u->bio ?? '',
            'role' => $u->role,
            'pastEvents' => (int) $u->past_events,
            'pastHours' => (int) $u->past_hours,
            'pastPoints' => (int) $u->past_points,
            'pastImpact' => (int) $u->past_impact,
            'avatarUrl' => $this->abs($u->avatar_url, $host),
        ];
    }

    // -------------------------------------------------------------- media
    /** Menyajikan gambar dari public/uploads lewat /api/media/{folder}/{file} (dengan header CORS). */
    public function media(string $folder, string $file)
    {
        if (!in_array($folder, ['events', 'avatars', 'orgs'], true) || !preg_match('/^[A-Za-z0-9_.-]+$/', $file) || str_contains($file, '..')) {
            abort(404);
        }
        $path = public_path('uploads/' . $folder . '/' . $file);
        if (!is_file($path)) {
            abort(404);
        }
        return response()->file($path, ['Cache-Control' => 'public, max-age=86400']);
    }

    // --------------------------------------------------------------- auth
    public function login(Request $r): JsonResponse
    {
        $b = $this->body($r);
        $email = strtolower(trim((string) ($b['email'] ?? '')));
        $password = (string) ($b['password'] ?? '');
        if ($email === '' || $password === '') {
            return $this->fail('Email dan password wajib diisi.', 422);
        }
        $u = User::whereRaw('LOWER(email) = ?', [$email])->first();
        if (!$u) {
            // 404 = akun tidak ada di server -> aplikasi memakai login lokal
            return $this->fail('Akun tidak ditemukan di server.', 404);
        }
        if (!Hash::check($password, $u->password_hash)) {
            return $this->fail('Email atau password salah.', 401);
        }
        $token = $u->createToken('flutter-app')->plainTextToken;
        return response()->json([
            'ok' => true,
            'token' => $token,
            'user' => $this->userJson($u, $r->getSchemeAndHttpHost(), true),
        ]);
    }

    public function register(Request $r): JsonResponse
    {
        $b = $this->body($r);
        $name = trim((string) ($b['name'] ?? ''));
        $email = strtolower(trim((string) ($b['email'] ?? '')));
        $password = (string) ($b['password'] ?? '');
        if ($name === '') {
            return $this->fail('Nama wajib diisi.', 422);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->fail('Format email tidak valid.', 422);
        }
        if (strlen($password) < 6) {
            return $this->fail('Password minimal 6 karakter.', 422);
        }
        if (User::whereRaw('LOWER(email) = ?', [$email])->exists()) {
            return $this->fail('Email sudah terdaftar.', 409);
        }
        $u = User::create([
            'id' => (string) Str::uuid(),
            'name' => $this->s($name, 150),
            'email' => $this->s($email, 190),
            'password_hash' => Hash::make($password),
            'phone' => '',
            'city' => '',
            'role' => 'volunteer', // akun penyelenggara hanya dibuat admin
        ]);
        $u->refresh();
        $token = $u->createToken('flutter-app')->plainTextToken;
        return response()->json([
            'ok' => true,
            'token' => $token,
            'user' => $this->userJson($u, $r->getSchemeAndHttpHost(), true),
        ], 201);
    }

    public function logout(Request $r): JsonResponse
    {
        $r->user()->currentAccessToken()?->delete();
        return response()->json(['ok' => true]);
    }

    public function password(Request $r): JsonResponse
    {
        $new = (string) ($this->body($r)['newPassword'] ?? '');
        if (strlen($new) < 6) {
            return $this->fail('Password minimal 6 karakter.', 422);
        }
        $me = $r->user();
        $me->password_hash = Hash::make($new);
        $me->save();
        return response()->json(['ok' => true]);
    }

    public function delete(Request $r): JsonResponse
    {
        $me = $r->user();
        if ($me->role === 'organizer') {
            return $this->fail('Akun penyelenggara tidak dapat dihapus.', 403);
        }
        DB::transaction(function () use ($me) {
            DB::table('registrations')->where('user_id', $me->id)->delete();
            DB::table('notifications')->where('user_id', $me->id)->delete();
            DB::table('point_entries')->where('user_id', $me->id)->delete();
            DB::table('feedbacks')->where('user_id', $me->id)->delete();
            DB::table('user_kv')->where('user_id', $me->id)->delete();
            $me->tokens()->delete();
            $me->delete();
        });
        return response()->json(['ok' => true]);
    }

    // --------------------------------------------------------------- push
    public function push(Request $r): JsonResponse
    {
        $me = $r->user();
        $b = $this->body($r);
        $changes = is_array($b['changes'] ?? null) ? $b['changes'] : [];
        $deleted = is_array($b['deleted'] ?? null) ? $b['deleted'] : [];
        $host = $r->getSchemeAndHttpHost();
        $rejected = [];
        $avatarUrls = [];

        foreach (self::ORDER as $type) {
            $list = $changes[$type] ?? null;
            if (!is_array($list)) {
                continue;
            }
            foreach ($list as $item) {
                if (!is_array($item)) {
                    continue;
                }
                $id = (string) ($item['id'] ?? $item['userId'] ?? '');
                try {
                    $reason = $this->store($type, $item, $me, $avatarUrls, $host);
                    if ($reason !== null) {
                        $rejected[] = ['type' => $type, 'id' => $id, 'reason' => $reason];
                    }
                } catch (\Throwable $e) {
                    $rejected[] = ['type' => $type, 'id' => $id, 'reason' => 'Error server: ' . $e->getMessage()];
                }
            }
        }

        $isOrg = $me->role === 'organizer';
        $delMap = [
            'cmsg' => ['comm_messages', 'sender_id'],
            'announce' => ['comm_announcements', 'author_id'],
            'poll' => ['comm_polls', 'creator_id'],
            'report' => ['comm_reports', 'reporter_id'],
        ];
        foreach ($delMap as $type => [$table, $col]) {
            $ids = $deleted[$type] ?? null;
            if (!is_array($ids) || !$ids) {
                continue;
            }
            $q = DB::table($table)->whereIn('id', array_map('strval', $ids));
            if (!$isOrg) {
                $q->where($col, $me->id);
            }
            $q->delete();
        }

        return response()->json(['ok' => true, 'avatarUrls' => (object) $avatarUrls, 'rejected' => $rejected]);
    }

    /** Menyimpan satu entri. Mengembalikan null bila sukses, atau teks alasan penolakan. */
    private function store(string $type, array $j, User $me, array &$avatarUrls, string $host): ?string
    {
        $isOrg = $me->role === 'organizer';
        $id = $this->s($j['id'] ?? '', 64);
        $now = now()->utc()->format('Y-m-d H:i:s');

        switch ($type) {
            case 'user':
                if ($id !== $me->id) {
                    return 'Bukan akun sendiri';
                }
                $me->name = $this->s($j['name'] ?? $me->name, 150) ?: $me->name;
                $me->phone = $this->s($j['phone'] ?? '', 40);
                $me->city = $this->s($j['city'] ?? '', 120);
                $me->bio = (string) ($j['bio'] ?? '');
                $me->save();
                return null;

            case 'avatar':
                if (($j['userId'] ?? '') !== $me->id) {
                    return 'Bukan akun sendiri';
                }
                if (!empty($j['remove'])) {
                    foreach (glob(public_path('uploads/avatars/' . preg_replace('/[^A-Za-z0-9_-]/', '_', $me->id)) . '-*') ?: [] as $old) {
                        @unlink($old);
                    }
                    $me->avatar_url = '';
                    $me->save();
                    $avatarUrls[$me->id] = '';
                    return null;
                }
                $saved = $this->saveDataUri((string) ($j['dataUri'] ?? ''), 'avatars', $me->id);
                if (!$saved) {
                    return 'Gambar tidak valid';
                }
                $this->logUpload($me->id, 'avatar', $saved);
                $me->avatar_url = $saved[0];
                $me->save();
                $avatarUrls[$me->id] = $this->abs($saved[0], $host);
                return null;

            case 'event': {
                if (!$isOrg) {
                    return 'Hanya penyelenggara yang boleh mengelola event';
                }
                if ($id === '') {
                    return 'ID kosong';
                }
                $old = DB::table('events')->where('id', $id)->first();
                if ($old && $old->owner_id !== '' && $old->owner_id !== $me->id) {
                    return 'Bukan pemilik event';
                }
                if (!empty($j['deleted'])) {
                    if ($old) {
                        DB::table('events')->where('id', $id)->update(['is_deleted' => 1]);
                    }
                    return null;
                }
                $meta = is_array($j['meta'] ?? null) ? $j['meta'] : [];
                $meta['ownerId'] = $me->id;
                $j['meta'] = $meta;
                $j = $this->externalize($j, 'events', $id, $me->id);
                $image = (string) ($j['image'] ?? '');
                DB::table('events')->updateOrInsert(['id' => $id], [
                    'owner_id' => $me->id,
                    'title' => $this->s($j['title'] ?? ''),
                    'category' => $this->s($j['category'] ?? '', 60),
                    'organizer' => $this->s($j['organizer'] ?? '', 190),
                    'location' => $this->s($j['location'] ?? ''),
                    'description' => (string) ($j['description'] ?? ''),
                    'image_url' => str_starts_with($image, 'uploads/') || str_starts_with($image, 'http') ? $this->s($image) : '',
                    'event_time' => $this->s($j['time'] ?? '', 60),
                    'event_date' => $this->dt($j['date'] ?? null),
                    'quota' => (int) ($j['quota'] ?? 0),
                    'base_participants' => (int) ($j['baseParticipants'] ?? 0),
                    'points' => (int) ($j['points'] ?? 0),
                    'hours' => (int) ($j['hours'] ?? 0),
                    'impact' => (int) ($j['impact'] ?? 0),
                    'price' => (int) ($j['price'] ?? 0),
                    'status' => $this->s($meta['status'] ?? 'published', 20),
                    'deadline' => $this->dt($meta['deadline'] ?? null),
                    'require_approval' => !empty($meta['requireApproval']) ? 1 : 0,
                    'is_deleted' => 0,
                    'data' => $this->json($j),
                ]);
                return null;
            }

            case 'reg': {
                $userId = (string) ($j['userId'] ?? '');
                $eventId = $this->s($j['eventId'] ?? '', 64);
                if ($id === '' || $userId === '' || $eventId === '') {
                    return 'Data pendaftaran tidak lengkap';
                }
                $ownerId = DB::table('events')->where('id', $eventId)->value('owner_id');
                $isEventOwner = $ownerId !== null && $ownerId === $me->id;
                if (!$isEventOwner && $userId !== $me->id) {
                    return 'Bukan pendaftaran milikmu';
                }
                $old = DB::table('registrations')->where('id', $id)->first();
                if ($old && $old->user_id !== $userId) {
                    return 'ID pendaftaran bentrok';
                }
                $code = (string) ($j['code'] ?? '');
                $status = (string) ($j['status'] ?? 'registered');
                $approval = (string) ($j['approval'] ?? '');
                $in = (string) ($j['checkIn'] ?? '');
                $out = (string) ($j['checkOut'] ?? '');
                if ($old) {
                    if ($code === '') {
                        $code = $old->code;
                    }
                    if (!$isEventOwner) {
                        // relawan tidak boleh menimpa keputusan penyelenggara
                        if ($old->approval !== '') { $approval = $old->approval; }
                        if ($old->checked_in_at !== '') { $in = $old->checked_in_at; }
                        if ($old->checked_out_at !== '') { $out = $old->checked_out_at; }
                        if ($old->status === 'attended') { $status = 'attended'; }
                    }
                }
                DB::table('registrations')->updateOrInsert(['id' => $id], [
                    'user_id' => $userId,
                    'event_id' => $eventId,
                    'code' => $this->s($code, 40),
                    'status' => $this->s($status, 20),
                    'approval' => $this->s($approval, 20),
                    'checked_in_at' => $this->s($in, 40),
                    'checked_out_at' => $this->s($out, 40),
                    'registered_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;
            }

            case 'notif': {
                $userId = $this->s($j['userId'] ?? '', 64);
                if ($id === '' || $userId === '') {
                    return 'Data notifikasi tidak lengkap';
                }
                $old = DB::table('notifications')->where('id', $id)->first();
                $read = !empty($j['read']) || ($old && $old->is_read);
                DB::table('notifications')->updateOrInsert(['id' => $id], [
                    'user_id' => $userId,
                    'title' => $this->s($j['title'] ?? ''),
                    'body' => (string) ($j['body'] ?? ''),
                    'kind' => $this->s($j['kind'] ?? 'info', 80),
                    'is_read' => $read ? 1 : 0,
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;
            }

            case 'point': {
                $userId = $this->s($j['userId'] ?? '', 64);
                if ($id === '' || $userId === '') {
                    return 'Data poin tidak lengkap';
                }
                if ($userId !== $me->id && !$isOrg) {
                    return 'Bukan poin milikmu';
                }
                if (DB::table('point_entries')->where('id', $id)->exists()) {
                    return null;
                }
                DB::table('point_entries')->insert([
                    'id' => $id,
                    'user_id' => $userId,
                    'event_id' => isset($j['eventId']) ? $this->s($j['eventId'], 64) : null,
                    'type' => $this->s($j['type'] ?? $j['kind'] ?? 'event', 30),
                    'points' => (int) ($j['points'] ?? $j['value'] ?? 0),
                    'verified' => array_key_exists('verified', $j) ? (!empty($j['verified']) ? 1 : 0) : 1,
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;
            }

            case 'cert':
                if (!$isOrg) {
                    return 'Hanya penyelenggara';
                }
                if ($id === '' || DB::table('certificates')->where('id', $id)->exists()) {
                    return null;
                }
                DB::table('certificates')->insert([
                    'id' => $id,
                    'reg_id' => $this->s($j['regId'] ?? '', 64),
                    'user_id' => $this->s($j['userId'] ?? '', 64),
                    'event_id' => $this->s($j['eventId'] ?? '', 64),
                    'number' => $this->s($j['number'] ?? '', 60),
                    'issued_at' => $this->dt($j['issuedAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'orgmsg':
                if (!$isOrg) {
                    return 'Hanya penyelenggara';
                }
                if ($id === '' || DB::table('org_messages')->where('id', $id)->exists()) {
                    return null;
                }
                DB::table('org_messages')->insert([
                    'id' => $id,
                    'owner_id' => $me->id,
                    'kind' => $this->s($j['kind'] ?? '', 30),
                    'title' => $this->s($j['title'] ?? ''),
                    'body' => (string) ($j['body'] ?? ''),
                    'event_id' => isset($j['eventId']) ? $this->s($j['eventId'], 64) : null,
                    'recipient_count' => (int) ($j['recipientCount'] ?? $j['recipients'] ?? 0),
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'feedback':
                if (($j['userId'] ?? '') !== $me->id) {
                    return 'Bukan feedback milikmu';
                }
                if ($id === '' || DB::table('feedbacks')->where('id', $id)->exists()) {
                    return null;
                }
                DB::table('feedbacks')->insert([
                    'id' => $id,
                    'user_id' => $me->id,
                    'event_title' => $this->s($j['eventTitle'] ?? ''),
                    'rating' => (int) ($j['rating'] ?? 0),
                    'text' => (string) ($j['text'] ?? ''),
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'cmsg':
                if ($id === '') {
                    return 'ID kosong';
                }
                DB::table('comm_messages')->updateOrInsert(['id' => $id], [
                    'room_id' => $this->s($j['roomId'] ?? 'umum', 40),
                    'sender_id' => $this->s($j['senderId'] ?? '', 64),
                    'sender_name' => $this->s($j['senderName'] ?? '', 150),
                    'text' => (string) ($j['text'] ?? ''),
                    'type' => $this->s($j['type'] ?? 'text', 20),
                    'event_id' => isset($j['eventId']) ? $this->s($j['eventId'], 64) : null,
                    'reply_to_id' => isset($j['replyToId']) ? $this->s($j['replyToId'], 64) : null,
                    'is_deleted' => 0,
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'announce':
                if ($id === '') {
                    return 'ID kosong';
                }
                DB::table('comm_announcements')->updateOrInsert(['id' => $id], [
                    'author_id' => $this->s($j['authorId'] ?? '', 64),
                    'author_name' => $this->s($j['authorName'] ?? '', 150),
                    'title' => $this->s($j['title'] ?? ''),
                    'body' => (string) ($j['body'] ?? ''),
                    'important' => !empty($j['important']) ? 1 : 0,
                    'event_id' => isset($j['eventId']) ? $this->s($j['eventId'], 64) : null,
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'poll':
                if ($id === '') {
                    return 'ID kosong';
                }
                DB::table('comm_polls')->updateOrInsert(['id' => $id], [
                    'creator_id' => $this->s($j['creatorId'] ?? '', 64),
                    'creator_name' => $this->s($j['creatorName'] ?? '', 150),
                    'question' => $this->s($j['question'] ?? '', 500),
                    'ends_at' => $this->dt($j['endsAt'] ?? null),
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'report':
                if ($id === '' || DB::table('comm_reports')->where('id', $id)->exists()) {
                    return null;
                }
                DB::table('comm_reports')->insert([
                    'id' => $id,
                    'message_id' => $this->s($j['messageId'] ?? '', 64),
                    'reporter_id' => $this->s($j['reporterId'] ?? '', 64),
                    'reason' => $this->s($j['reason'] ?? ''),
                    'created_at' => $this->dt($j['createdAt'] ?? null) ?? $now,
                    'data' => $this->json($j),
                ]);
                return null;

            case 'orgprofile': {
                if (!$isOrg || $id !== $me->id) {
                    return 'Bukan profil milikmu';
                }
                $j = $this->externalize($j, 'orgs', $id, $me->id);
                $logo = '';
                foreach ($j as $v) {
                    if (is_string($v) && str_starts_with($v, 'uploads/orgs/')) {
                        $logo = $v;
                        break;
                    }
                }
                DB::table('org_profiles')->updateOrInsert(['user_id' => $me->id], [
                    'logo_url' => $this->s($logo),
                    'data' => $this->json($j),
                ]);
                return null;
            }

            case 'kv': {
                $key = $this->s($j['key'] ?? '', 60);
                if (($j['userId'] ?? '') !== $me->id || $key === '') {
                    return 'Bukan data milikmu';
                }
                DB::table('user_kv')->updateOrInsert(['id' => $this->s($me->id . ':' . $key, 140)], [
                    'user_id' => $me->id,
                    'k' => $key,
                    'value' => $this->json($j['value'] ?? null),
                ]);
                return null;
            }
        }
        return 'Jenis data tidak dikenal';
    }

    // --------------------------------------------------------------- pull
    public function pull(Request $r): JsonResponse
    {
        $me = $r->user();
        $isOrg = $me->role === 'organizer';
        $host = $r->getSchemeAndHttpHost();
        $e = [];

        // user
        $e['user'] = User::all()->map(function (User $u) use ($me, $isOrg, $host) {
            return $this->userJson($u, $host, $isOrg || $u->id === $me->id);
        })->values()->all();

        // event (termasuk yang dihapus -> {id, deleted:true})
        $owners = DB::table('events')->pluck('owner_id', 'id')->all();
        $events = [];
        foreach (DB::table('events')->orderBy('created_at', 'desc')->get() as $row) {
            if ($row->is_deleted) {
                $events[] = ['id' => $row->id, 'deleted' => true];
                continue;
            }
            $events[] = $this->absolutize($this->dec($row->data), $host);
        }
        $e['event'] = $events;

        // reg (kode & keputusan hanya terlihat oleh pemilik pendaftaran / penyelenggara event)
        $regs = [];
        foreach (DB::table('registrations')->get() as $row) {
            $j = $this->dec($row->data);
            $j['id'] = $row->id;
            $j['userId'] = $row->user_id;
            $j['eventId'] = $row->event_id;
            $j['status'] = $row->status;
            $mine = $row->user_id === $me->id;
            $eventOwner = ($owners[$row->event_id] ?? null) === $me->id;
            if ($mine || $eventOwner) {
                $j['code'] = $row->code;
                $j['approval'] = $row->approval;
                $j['checkIn'] = $row->checked_in_at;
                $j['checkOut'] = $row->checked_out_at;
            } else {
                $j['code'] = '';
                $j['approval'] = '';
                $j['checkIn'] = '';
                $j['checkOut'] = '';
            }
            $regs[] = $j;
        }
        $e['reg'] = $regs;

        // notif milik sendiri
        $e['notif'] = DB::table('notifications')->where('user_id', $me->id)->get()->map(function ($row) {
            $j = $this->dec($row->data);
            $j['id'] = $row->id;
            $j['read'] = (bool) $row->is_read;
            return $j;
        })->values()->all();

        // poin (untuk leaderboard)
        $e['point'] = DB::table('point_entries')->get()->map(fn ($row) => $this->dec($row->data))->values()->all();

        // sertifikat: milik sendiri atau dari event yang dikelola
        $e['cert'] = DB::table('certificates')->get()->filter(function ($row) use ($me, $owners) {
            return $row->user_id === $me->id || ($owners[$row->event_id] ?? null) === $me->id;
        })->map(fn ($row) => $this->dec($row->data))->values()->all();

        $e['orgmsg'] = DB::table('org_messages')->where('owner_id', $me->id)->get()
            ->map(fn ($row) => $this->dec($row->data))->values()->all();

        $fb = DB::table('feedbacks');
        if (!$isOrg) {
            $fb->where('user_id', $me->id);
        }
        $e['feedback'] = $fb->get()->map(fn ($row) => $this->dec($row->data))->values()->all();

        $e['cmsg'] = DB::table('comm_messages')->where('is_deleted', 0)->orderBy('created_at')->get()
            ->map(fn ($row) => $this->dec($row->data))->values()->all();
        $e['announce'] = DB::table('comm_announcements')->get()->map(fn ($row) => $this->dec($row->data))->values()->all();
        $e['poll'] = DB::table('comm_polls')->get()->map(fn ($row) => $this->dec($row->data))->values()->all();
        $e['report'] = DB::table('comm_reports')->get()->map(fn ($row) => $this->dec($row->data))->values()->all();

        $e['orgprofile'] = DB::table('org_profiles')->get()->map(function ($row) use ($host) {
            $j = $this->absolutize($this->dec($row->data), $host);
            $j['id'] = $row->user_id;
            return $j;
        })->values()->all();

        $e['kv'] = DB::table('user_kv')->where('user_id', $me->id)->get()->map(function ($row) {
            return [
                'id' => $row->id,
                'userId' => $row->user_id,
                'key' => $row->k,
                'value' => $row->value === null ? null : json_decode($row->value, true),
            ];
        })->values()->all();

        return response()->json(['ok' => true, 'entities' => $e, 'serverTime' => now()->toIso8601String()]);
    }
}
