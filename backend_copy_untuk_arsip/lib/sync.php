<?php
// ============================================================================
// SINKRONISASI: aplikasi Flutter <-> database
//   GET  api.php?r=sync/pull  -> semua data yang boleh dilihat pengguna ini
//   POST api.php?r=sync/push  -> kirim perubahan (dengan validasi hak akses)
// ============================================================================

function enc($d) {
    return json_encode($d, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
}
function dj($s) {
    if (!is_string($s) || $s === '') return null;
    $d = json_decode($s, true);
    return is_array($d) ? $d : null;
}
function sid($v) {
    $s = is_string($v) ? trim($v) : '';
    return (strlen($s) > 0 && strlen($s) <= 64) ? $s : '';
}

// ============================================================================
// PULL
// ============================================================================
function route_sync_pull() {
    $me = current_user();
    $isOrg = $me['role'] === 'organizer';
    $uid = $me['id'];
    $out = array();
    foreach (array('user', 'event', 'reg', 'notif', 'point', 'cert', 'orgmsg', 'feedback', 'cmsg',
                   'announce', 'poll', 'report', 'orgprofile', 'kv') as $t) $out[$t] = array();

    foreach (all('SELECT * FROM users') as $r) {
        $out['user'][] = user_json($r, $r['id'] === $uid || $isOrg);
    }

    foreach (all('SELECT id, owner_id, status, is_deleted, data FROM events') as $r) {
        if ((int) $r['is_deleted'] === 1) { $out['event'][] = array('id' => $r['id'], 'deleted' => true); continue; }
        if ($r['status'] === 'draft' && $r['owner_id'] !== $uid) continue;
        $d = dj($r['data']);
        if ($d === null) continue;
        $d['image'] = url_out(arr_get($d, 'image'));
        $out['event'][] = $d;
    }

    foreach (all('SELECT user_id, data FROM registrations') as $r) {
        $d = dj($r['data']);
        if ($d === null) continue;
        if (!$isOrg && $r['user_id'] !== $uid) $d['code'] = ''; // kode tiket hanya untuk pemilik & penyelenggara
        $out['reg'][] = $d;
    }

    foreach (all('SELECT data FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 300', array($uid)) as $r) {
        $d = dj($r['data']); if ($d !== null) $out['notif'][] = $d;
    }
    foreach (all('SELECT data FROM point_entries') as $r) {
        $d = dj($r['data']); if ($d !== null) $out['point'][] = $d;
    }
    $certs = $isOrg ? all('SELECT data FROM certificates') : all('SELECT data FROM certificates WHERE user_id = ?', array($uid));
    foreach ($certs as $r) { $d = dj($r['data']); if ($d !== null) $out['cert'][] = $d; }

    if ($isOrg) {
        foreach (all('SELECT data FROM org_messages WHERE owner_id = ? ORDER BY created_at DESC LIMIT 300', array($uid)) as $r) {
            $d = dj($r['data']); if ($d !== null) $out['orgmsg'][] = $d;
        }
    }
    $fbs = $isOrg ? all('SELECT data FROM feedbacks') : all('SELECT data FROM feedbacks WHERE user_id = ?', array($uid));
    foreach ($fbs as $r) { $d = dj($r['data']); if ($d !== null) $out['feedback'][] = $d; }

    foreach (all('SELECT data FROM comm_messages WHERE is_deleted = 0 ORDER BY created_at DESC LIMIT 1500') as $r) {
        $d = dj($r['data']); if ($d === null) continue;
        if (isset($d['imageUrl'])) $d['imageUrl'] = url_out($d['imageUrl']);
        $out['cmsg'][] = $d;
    }
    foreach (all('SELECT data FROM comm_announcements ORDER BY created_at DESC LIMIT 200') as $r) {
        $d = dj($r['data']); if ($d !== null) $out['announce'][] = $d;
    }
    foreach (all('SELECT data FROM comm_polls ORDER BY created_at DESC LIMIT 200') as $r) {
        $d = dj($r['data']); if ($d !== null) $out['poll'][] = $d;
    }
    foreach (all('SELECT data FROM comm_reports ORDER BY created_at DESC LIMIT 300') as $r) {
        $d = dj($r['data']); if ($d !== null) $out['report'][] = $d;
    }

    if ($isOrg) {
        $p = one('SELECT data FROM org_profiles WHERE user_id = ?', array($uid));
        if ($p) {
            $d = dj($p['data']);
            if ($d !== null) { $d['id'] = $uid; $d['pic'] = url_out(arr_get($d, 'pic')); $out['orgprofile'][] = $d; }
        }
    }

    foreach (all('SELECT id, user_id, k, value FROM user_kv WHERE user_id = ?', array($uid)) as $r) {
        $out['kv'][] = array('id' => $r['id'], 'userId' => $r['user_id'], 'key' => $r['k'], 'value' => json_decode($r['value'], true));
    }

    json_out(array('ok' => true, 'serverTime' => gmdate('c'), 'entities' => $out));
}

// ============================================================================
// PUSH
// ============================================================================
function route_sync_push() {
    $me = current_user();
    $b = body();
    $changes = (isset($b['changes']) && is_array($b['changes'])) ? $b['changes'] : array();
    $deleted = (isset($b['deleted']) && is_array($b['deleted'])) ? $b['deleted'] : array();

    $accepted = array();
    $rejected = array();
    $avatarUrls = array();

    $order = array('user', 'avatar', 'event', 'reg', 'notif', 'point', 'cert', 'orgmsg', 'feedback',
                   'cmsg', 'announce', 'poll', 'report', 'orgprofile', 'kv');
    foreach ($order as $type) {
        if (!isset($changes[$type]) || !is_array($changes[$type])) continue;
        foreach ($changes[$type] as $item) {
            if (!is_array($item)) continue;
            $id = ($type === 'avatar') ? sid(arr_get($item, 'userId')) : sid(arr_get($item, 'id'));
            if ($id === '') { $rejected[] = array('type' => $type, 'id' => '', 'reason' => 'id kosong'); continue; }
            try {
                $err = push_one($type, $me, $item, $avatarUrls);
            } catch (Exception $e) {
                $err = cfg('debug') ? ('DB: ' . $e->getMessage()) : 'kesalahan server';
            }
            if ($err === null) $accepted[$type][] = $id;
            else $rejected[] = array('type' => $type, 'id' => $id, 'reason' => $err);
        }
    }

    $delOk = array();
    foreach ($deleted as $type => $ids) {
        if (!is_array($ids)) continue;
        foreach ($ids as $id) {
            $id = sid($id);
            if ($id === '') continue;
            try {
                $err = delete_one((string) $type, $me, $id);
            } catch (Exception $e) {
                $err = cfg('debug') ? $e->getMessage() : 'kesalahan server';
            }
            if ($err === null) $delOk[$type][] = $id;
            else $rejected[] = array('type' => $type, 'id' => $id, 'reason' => $err, 'deleted' => true);
        }
    }

    json_out(array('ok' => true, 'accepted' => $accepted, 'deleted' => $delOk,
        'rejected' => $rejected, 'avatarUrls' => $avatarUrls));
}

function is_org($me) { return $me['role'] === 'organizer'; }

function push_one($type, $me, $d, &$avatarUrls) {
    $uid = $me['id'];
    switch ($type) {

    // ------------------------------------------------------------ profil
    case 'user':
        if (sid(arr_get($d, 'id')) !== $uid) return 'bukan akun sendiri';
        $name = trim((string) arr_get($d, 'name'));
        if ($name === '') $name = $me['name'];
        q('UPDATE users SET name=?, phone=?, city=?, bio=? WHERE id=?', array(
            mb_substr($name, 0, 150), mb_substr((string) arr_get($d, 'phone'), 0, 40),
            mb_substr((string) arr_get($d, 'city'), 0, 120), (string) arr_get($d, 'bio'), $uid));
        return null;

    case 'avatar':
        if (sid(arr_get($d, 'userId')) !== $uid) return 'bukan akun sendiri';
        $old = (string) $me['avatar_url'];
        if (!empty($d['remove'])) {
            if ($old !== '') delete_upload($old);
            q('UPDATE users SET avatar_url = ? WHERE id = ?', array('', $uid));
            $avatarUrls[$uid] = '';
            return null;
        }
        $rel = save_image_data((string) arr_get($d, 'dataUri'), 'avatars', $uid);
        if ($rel === null) return 'gambar tidak valid atau terlalu besar';
        if ($old !== '') delete_upload($old);
        q('UPDATE users SET avatar_url = ? WHERE id = ?', array($rel, $uid));
        $avatarUrls[$uid] = url_out($rel);
        return null;

    // ------------------------------------------------------------- event
    case 'event':
        return push_event($me, $d);

    // ------------------------------------------------------ pendaftaran
    case 'reg':
        return push_reg($me, $d);

    // ------------------------------------------------------- notifikasi
    case 'notif': {
        $id = sid(arr_get($d, 'id'));
        $to = sid(arr_get($d, 'userId'));
        if ($to === '') return 'penerima kosong';
        $old = one('SELECT user_id FROM notifications WHERE id = ?', array($id));
        if ($old && $old['user_id'] !== $uid) return null; // notifikasi milik orang lain: abaikan
        if ($to !== $uid && !one('SELECT id FROM users WHERE id = ?', array($to))) return 'penerima tidak ditemukan';
        upsert('notifications', array(
            'id' => $id, 'user_id' => $to,
            'title' => mb_substr((string) arr_get($d, 'title'), 0, 255), 'body' => (string) arr_get($d, 'body'),
            'kind' => mb_substr((string) arr_get($d, 'kind', 'info'), 0, 80),
            'is_read' => !empty($d['read']) ? 1 : 0,
            'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)),
            ($to !== $uid)); // untuk orang lain: hanya sisipkan, tidak boleh mengubah
        return null;
    }

    // ------------------------------------------------------------- poin
    case 'point': {
        $id = sid(arr_get($d, 'id'));
        $to = sid(arr_get($d, 'userId'));
        if ($to === '') return 'data tidak lengkap';
        $ptype = (string) arr_get($d, 'type', 'event');
        if (!is_org($me)) {
            if ($to !== $uid) return 'bukan poin milik sendiri';
            if ($ptype === 'opening') return 'tidak diizinkan';
            $eid = sid(arr_get($d, 'eventId'));
            $ok = $eid !== '' && one('SELECT id FROM registrations WHERE user_id=? AND event_id=? AND status=?', array($uid, $eid, 'attended'));
            if (!$ok) return 'kehadiran belum terverifikasi';
        } else {
            if (!one('SELECT id FROM users WHERE id = ?', array($to))) return 'relawan tidak ditemukan';
        }
        upsert('point_entries', array(
            'id' => $id, 'user_id' => $to, 'event_id' => (string) arr_get($d, 'eventId', ''),
            'type' => mb_substr($ptype, 0, 30), 'points' => (int) arr_get($d, 'points', 0),
            'verified' => !empty($d['verified']) ? 1 : 0,
            'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)), true);
        return null;
    }

    // ------------------------------------------------------- sertifikat
    case 'cert': {
        if (!is_org($me)) return 'hanya penyelenggara';
        $id = sid(arr_get($d, 'id'));
        upsert('certificates', array(
            'id' => $id, 'reg_id' => (string) arr_get($d, 'regId'), 'user_id' => (string) arr_get($d, 'userId'),
            'event_id' => (string) arr_get($d, 'eventId'), 'number' => (string) arr_get($d, 'number'),
            'issued_at' => sqldt(arr_get($d, 'issuedAt')), 'data' => enc($d)), true);
        return null;
    }

    // ------------------------------------------- pesan penyelenggara
    case 'orgmsg': {
        if (!is_org($me)) return 'hanya penyelenggara';
        if (sid(arr_get($d, 'ownerId')) !== $uid) return 'bukan milik sendiri';
        upsert('org_messages', array(
            'id' => sid(arr_get($d, 'id')), 'owner_id' => $uid, 'kind' => (string) arr_get($d, 'kind'),
            'title' => mb_substr((string) arr_get($d, 'title'), 0, 255), 'body' => (string) arr_get($d, 'body'),
            'event_id' => (string) arr_get($d, 'eventId', ''), 'recipient_count' => (int) arr_get($d, 'count', 0),
            'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)), true);
        return null;
    }

    case 'feedback': {
        if (sid(arr_get($d, 'userId')) !== $uid) return 'bukan milik sendiri';
        upsert('feedbacks', array(
            'id' => sid(arr_get($d, 'id')), 'user_id' => $uid,
            'event_title' => mb_substr((string) arr_get($d, 'eventTitle'), 0, 255),
            'rating' => (int) arr_get($d, 'rating', 0), 'text' => (string) arr_get($d, 'text'),
            'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)));
        return null;
    }

    // --------------------------------------------------------- komunitas
    case 'cmsg':
        return push_cmsg($me, $d);

    case 'announce': {
        $id = sid(arr_get($d, 'id'));
        $old = one('SELECT author_id FROM comm_announcements WHERE id = ?', array($id));
        if ($old) {
            if ($old['author_id'] !== $uid && !is_org($me)) return 'tidak diizinkan';
        } else {
            if (!is_org($me)) return 'hanya penyelenggara yang dapat membuat pengumuman resmi';
            if (sid(arr_get($d, 'authorId')) !== $uid) return 'bukan milik sendiri';
        }
        upsert('comm_announcements', array(
            'id' => $id, 'author_id' => $old ? $old['author_id'] : $uid,
            'author_name' => mb_substr((string) arr_get($d, 'authorName'), 0, 150),
            'title' => mb_substr((string) arr_get($d, 'title'), 0, 255), 'body' => (string) arr_get($d, 'body'),
            'important' => !empty($d['important']) ? 1 : 0, 'event_id' => (string) arr_get($d, 'eventId', ''),
            'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)));
        return null;
    }

    case 'poll':
        return push_poll($me, $d);

    case 'report': {
        if (sid(arr_get($d, 'reporterId')) !== $uid) return 'bukan milik sendiri';
        upsert('comm_reports', array(
            'id' => sid(arr_get($d, 'id')), 'message_id' => (string) arr_get($d, 'messageId'), 'reporter_id' => $uid,
            'reason' => mb_substr((string) arr_get($d, 'reason'), 0, 255),
            'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)), true);
        return null;
    }

    // ---------------------------------------------- profil penyelenggara
    case 'orgprofile': {
        if (!is_org($me)) return 'hanya penyelenggara';
        if (sid(arr_get($d, 'id')) !== $uid) return 'bukan milik sendiri';
        $old = one('SELECT logo_url FROM org_profiles WHERE user_id = ?', array($uid));
        $pic = img_in((string) arr_get($d, 'pic'), 'org', $uid);
        if ($old && $old['logo_url'] !== '' && $old['logo_url'] !== $pic) delete_upload($old['logo_url']);
        $d['pic'] = $pic;
        upsert('org_profiles', array('user_id' => $uid, 'logo_url' => strpos($pic, 'uploads/') === 0 ? $pic : '', 'data' => enc($d)));
        $nm = trim((string) arr_get($d, 'name'));
        if ($nm !== '') q('UPDATE users SET name = ? WHERE id = ?', array(mb_substr($nm, 0, 150), $uid));
        return null;
    }

    // ------------------------------------- data kecil per pengguna (kv)
    case 'kv': {
        if (sid(arr_get($d, 'userId')) !== $uid) return 'bukan milik sendiri';
        $key = (string) arr_get($d, 'key');
        if (!in_array($key, array('bookmarks', 'blocked', 'lastread', 'profile_extra', 'activity_extra'), true)) return 'kunci tidak dikenal';
        $val = enc(arr_get($d, 'value', array()));
        if (strlen($val) > 3 * 1024 * 1024) return 'data terlalu besar';
        upsert('user_kv', array('id' => $uid . ':' . $key, 'user_id' => $uid, 'k' => $key, 'value' => $val));
        return null;
    }
    }
    return 'jenis data tidak dikenal';
}

// ---------------------------------------------------------------- event
function push_event($me, $d) {
    $uid = $me['id'];
    $id = sid(arr_get($d, 'id'));
    if (!is_org($me)) return 'hanya penyelenggara';
    $row = one('SELECT owner_id FROM events WHERE id = ?', array($id));
    if ($row && $row['owner_id'] !== '' && $row['owner_id'] !== $uid) return 'event milik penyelenggara lain';

    if (!empty($d['deleted'])) {
        upsert('events', array('id' => $id, 'owner_id' => $uid, 'is_deleted' => 1,
            'data' => enc(array('id' => $id, 'deleted' => true))));
        return null;
    }
    $title = trim((string) arr_get($d, 'title'));
    if ($title === '') return 'judul event kosong';
    $meta = (isset($d['meta']) && is_array($d['meta'])) ? $d['meta'] : array();
    $meta['ownerId'] = $uid; // event selalu dimiliki yang mengirim
    $d['meta'] = $meta;
    $d['image'] = img_in((string) arr_get($d, 'image'), 'events', $uid);

    $oldImg = $row ? one('SELECT image_url FROM events WHERE id = ?', array($id)) : null;
    if ($oldImg && $oldImg['image_url'] !== '' && $oldImg['image_url'] !== $d['image']) delete_upload($oldImg['image_url']);

    upsert('events', array(
        'id' => $id, 'owner_id' => $uid, 'title' => mb_substr($title, 0, 255),
        'category' => (string) arr_get($d, 'category'), 'organizer' => (string) arr_get($d, 'organizer'),
        'location' => (string) arr_get($d, 'location'), 'description' => (string) arr_get($d, 'description'),
        'image_url' => strpos($d['image'], 'uploads/') === 0 ? $d['image'] : '',
        'event_time' => (string) arr_get($d, 'time'), 'event_date' => sqldt(arr_get($d, 'date')),
        'quota' => (int) arr_get($d, 'quota', 0), 'base_participants' => (int) arr_get($d, 'baseParticipants', 0),
        'points' => (int) arr_get($d, 'points', 0), 'hours' => (int) arr_get($d, 'hours', 0),
        'impact' => (int) arr_get($d, 'impact', 0), 'price' => (int) arr_get($d, 'price', 0),
        'status' => (string) arr_get($meta, 'status', 'published'), 'deadline' => sqldt(arr_get($meta, 'deadline')),
        'require_approval' => !empty($meta['requireApproval']) ? 1 : 0, 'is_deleted' => 0, 'data' => enc($d)));
    return null;
}

// ----------------------------------------------------------- pendaftaran
function push_reg($me, $d) {
    $uid = $me['id'];
    $id = sid(arr_get($d, 'id'));
    $owner = sid(arr_get($d, 'userId'));
    $eid = sid(arr_get($d, 'eventId'));
    if ($owner === '' || $eid === '') return 'data tidak lengkap';

    $ev = one('SELECT owner_id, quota, base_participants, status FROM events WHERE id = ? AND is_deleted = 0', array($eid));
    $orgSide = is_org($me) && (!$ev || $ev['owner_id'] === $uid || $ev['owner_id'] === '');
    if ($owner !== $uid && !$orgSide) return 'tidak diizinkan';

    $old = one('SELECT * FROM registrations WHERE id = ?', array($id));
    if ($old && $old['user_id'] !== $owner) return 'tidak diizinkan';

    $status = (string) arr_get($d, 'status', 'registered');
    if (!in_array($status, array('registered', 'attended', 'cancelled'), true)) $status = 'registered';
    if (!$orgSide && $status === 'attended' && (!$old || $old['status'] !== 'attended') && !cfg('allow_self_verify', true)) {
        return 'kehadiran hanya dapat diverifikasi penyelenggara';
    }

    $approval = (string) arr_get($d, 'approval');
    $cin = (string) arr_get($d, 'checkIn');
    $cout = (string) arr_get($d, 'checkOut');
    if ($old && !$orgSide) { // relawan tidak boleh mengubah keputusan/absensi penyelenggara
        $approval = $old['approval'];
        $cin = $old['checked_in_at'];
        $cout = $old['checked_out_at'];
        if ($old['status'] === 'cancelled' && $status === 'registered') $status = 'cancelled';
    }

    $code = (string) arr_get($d, 'code');
    if (!$old) {
        // pendaftaran baru: cek kuota, duplikat, dan kode unik
        if ($status !== 'cancelled') {
            $dup = one('SELECT id FROM registrations WHERE user_id=? AND event_id=? AND status<>? AND id<>?',
                array($owner, $eid, 'cancelled', $id));
            if ($dup) $status = 'cancelled';
        }
        if ($status !== 'cancelled' && $ev) {
            $c = one('SELECT COUNT(*) AS c FROM registrations WHERE event_id=? AND status<>?', array($eid, 'cancelled'));
            if (((int) $ev['base_participants'] + (int) $c['c']) >= (int) $ev['quota']) {
                $status = 'cancelled';
                $nid = new_id('n');
                $nd = array('id' => $nid, 'userId' => $owner, 'title' => 'Kuota penuh',
                    'body' => 'Maaf, kuota kegiatan sudah penuh sehingga pendaftaranmu tidak dapat diproses.',
                    'kind' => 'cancel', 'createdAt' => date('Y-m-d\TH:i:s.000'), 'read' => false);
                upsert('notifications', array('id' => $nid, 'user_id' => $owner, 'title' => $nd['title'], 'body' => $nd['body'],
                    'kind' => 'cancel', 'is_read' => 0, 'created_at' => date('Y-m-d H:i:s'), 'data' => enc($nd)), true);
            }
        }
    }
    if ($code !== '' && one('SELECT id FROM registrations WHERE event_id=? AND code=? AND id<>?', array($eid, $code, $id))) {
        $code .= strtoupper(substr(bin2hex(random_bytes(2)), 0, 3));
    }

    $d['status'] = $status;
    $d['code'] = $code;
    $d['approval'] = $approval;
    $d['checkIn'] = $cin;
    $d['checkOut'] = $cout;
    upsert('registrations', array(
        'id' => $id, 'user_id' => $owner, 'event_id' => $eid, 'code' => $code, 'status' => $status,
        'approval' => $approval, 'checked_in_at' => $cin, 'checked_out_at' => $cout,
        'registered_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)));
    return null;
}

// ---------------------------------------------------- pesan komunitas
function merge_reactions($old, $new, $meId) {
    $res = array();
    $emojis = array_unique(array_merge(array_keys(is_array($old) ? $old : array()), array_keys(is_array($new) ? $new : array())));
    foreach ($emojis as $e) {
        $list = (is_array($old) && isset($old[$e]) && is_array($old[$e])) ? $old[$e] : array();
        $list = array_values(array_filter($list, function ($x) use ($meId) { return $x !== $meId; }));
        if (is_array($new) && isset($new[$e]) && is_array($new[$e]) && in_array($meId, $new[$e], true)) $list[] = $meId;
        if (count($list) > 0) $res[$e] = $list;
    }
    return $res;
}

function push_cmsg($me, $d) {
    $uid = $me['id'];
    $id = sid(arr_get($d, 'id'));
    $old = one('SELECT sender_id, data, is_deleted FROM comm_messages WHERE id = ?', array($id));
    if ($old) {
        if ((int) $old['is_deleted'] === 1) return null;
        // Pesan yang sudah ada: siapa pun boleh memberi reaksi (hanya reaksinya sendiri yang diubah)
        $od = dj($old['data']);
        if ($od === null) return null;
        $od['reactions'] = merge_reactions(arr_get($od, 'reactions', array()), arr_get($d, 'reactions', array()), $uid);
        q('UPDATE comm_messages SET data = ? WHERE id = ?', array(enc($od), $id));
        return null;
    }
    if (sid(arr_get($d, 'senderId')) !== $uid) return 'bukan pesan milik sendiri';
    $d['senderName'] = $me['name'];
    $d['text'] = mb_substr((string) arr_get($d, 'text'), 0, 2000);
    $img = img_in((string) arr_get($d, 'imageUrl'), 'chat', $uid);
    $d['imageUrl'] = $img;
    $d['reactions'] = merge_reactions(array(), arr_get($d, 'reactions', array()), $uid);
    upsert('comm_messages', array(
        'id' => $id, 'room_id' => mb_substr((string) arr_get($d, 'roomId', 'umum'), 0, 40), 'sender_id' => $uid,
        'sender_name' => mb_substr($me['name'], 0, 150), 'text' => $d['text'],
        'type' => mb_substr((string) arr_get($d, 'type', 'text'), 0, 20),
        'event_id' => (string) arr_get($d, 'eventId', ''), 'reply_to_id' => (string) arr_get($d, 'replyToId', ''),
        'image_url' => strpos($img, 'uploads/') === 0 ? $img : '', 'is_deleted' => 0,
        'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)));
    return null;
}

// ---------------------------------------------------------------- polling
function push_poll($me, $d) {
    $uid = $me['id'];
    $id = sid(arr_get($d, 'id'));
    $old = one('SELECT creator_id, data FROM comm_polls WHERE id = ?', array($id));
    $inVotes = (isset($d['votes']) && is_array($d['votes'])) ? $d['votes'] : array();
    if ($old) {
        $od = dj($old['data']);
        if ($od === null) return null;
        $votes = (isset($od['votes']) && is_array($od['votes'])) ? $od['votes'] : array();
        // Satu pengguna = satu suara, dan hanya boleh mengubah suaranya sendiri
        if (isset($inVotes[$uid]) && !isset($votes[$uid])) {
            $n = count(isset($od['options']) && is_array($od['options']) ? $od['options'] : array());
            $v = (int) $inVotes[$uid];
            if ($v >= 0 && $v < $n) $votes[$uid] = $v;
        }
        $od['votes'] = $votes;
        q('UPDATE comm_polls SET data = ? WHERE id = ?', array(enc($od), $id));
        return null;
    }
    if (sid(arr_get($d, 'creatorId')) !== $uid) return 'bukan milik sendiri';
    $opts = (isset($d['options']) && is_array($d['options'])) ? array_values($d['options']) : array();
    if (count($opts) < 2) return 'pilihan polling kurang';
    $d['creatorName'] = $me['name'];
    $d['votes'] = isset($inVotes[$uid]) ? array($uid => (int) $inVotes[$uid]) : array();
    upsert('comm_polls', array(
        'id' => $id, 'creator_id' => $uid, 'creator_name' => mb_substr($me['name'], 0, 150),
        'question' => mb_substr((string) arr_get($d, 'question'), 0, 500),
        'ends_at' => sqldt(arr_get($d, 'endsAt')), 'created_at' => sqldt(arr_get($d, 'createdAt')), 'data' => enc($d)));
    return null;
}

// ================================================================= HAPUS
function delete_one($type, $me, $id) {
    $uid = $me['id'];
    switch ($type) {
    case 'cmsg': {
        $r = one('SELECT sender_id, image_url FROM comm_messages WHERE id = ?', array($id));
        if (!$r) return null;
        if ($r['sender_id'] !== $uid && !is_org($me)) return 'hanya pengirim/penyelenggara yang dapat menghapus';
        if ($r['image_url'] !== '') delete_upload($r['image_url']);
        q('UPDATE comm_messages SET is_deleted = 1 WHERE id = ?', array($id));
        return null;
    }
    case 'announce': {
        $r = one('SELECT author_id FROM comm_announcements WHERE id = ?', array($id));
        if (!$r) return null;
        if ($r['author_id'] !== $uid && !is_org($me)) return 'tidak diizinkan';
        q('DELETE FROM comm_announcements WHERE id = ?', array($id));
        return null;
    }
    case 'poll': {
        $r = one('SELECT creator_id FROM comm_polls WHERE id = ?', array($id));
        if (!$r) return null;
        if ($r['creator_id'] !== $uid && !is_org($me)) return 'tidak diizinkan';
        q('DELETE FROM comm_polls WHERE id = ?', array($id));
        return null;
    }
    case 'report': {
        $r = one('SELECT reporter_id FROM comm_reports WHERE id = ?', array($id));
        if (!$r) return null;
        if ($r['reporter_id'] !== $uid && !is_org($me)) return 'tidak diizinkan';
        q('DELETE FROM comm_reports WHERE id = ?', array($id));
        return null;
    }
    }
    return 'penghapusan tidak didukung';
}
