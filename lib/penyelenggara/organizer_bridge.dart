part of '../providers/app_state.dart';

// ============================================================================
// JEMBATAN PENYELENGGARA <-> APPSTATE
// File ini adalah "part" dari app_state.dart, sehingga boleh memakai fungsi
// privat AppState (_award, _commit) tanpa mengubah logika relawan.
// ============================================================================

const String kOrgRole = 'organizer';
const String kVolRole = 'volunteer';
const String kDemoOrgId = 'u_org_demo';
const String kDemoOrgEmail = 'organizer@volunteer.id';

/// Akun penyelenggara contoh. Di produksi akun ini dibuat ADMIN lewat backend,
/// bukan lewat halaman registrasi (register() selalu membuat role relawan).
AppUser buildDemoOrganizer() => AppUser(
      id: kDemoOrgId,
      name: 'Volunteer Indonesia',
      email: kDemoOrgEmail,
      password: 'organizer123',
      phone: '031-5551234',
      city: 'Surabaya',
      bio: 'Akun penyelenggara contoh.',
      role: kOrgRole,
    );

extension OrganizerBridge on AppState {
  /// Check-in relawan oleh penyelenggara. Poin diberikan ke RELAWAN (bukan akun
  /// yang sedang login) dan memakai aturan poin yang sama dengan markAttended().
  String? orgCheckIn(String regId) {
    Registration? reg;
    for (final r in regs) {
      if (r.id == regId) reg = r;
    }
    if (reg == null) return 'Pendaftaran tidak ditemukan';
    if (reg.status == RegStatus.cancelled) return 'Pendaftaran dibatalkan atau ditolak';
    if (reg.status == RegStatus.attended) return 'Relawan sudah check-in';
    final u = userById(reg.userId);
    final e = eventById(reg.eventId);
    if (u == null || e == null) return 'Data relawan/event tidak ditemukan';

    reg.status = RegStatus.attended;
    var gained = _award(u, e, PointType.event, kPointsPerEvent, 'Kehadiran terverifikasi oleh panitia');
    final done = eventsOf(u.id);
    if (gained > 0 && done % 5 == 0) {
      gained += _award(u, e, PointType.bonus, kPointsBonus5Events, 'Bonus menyelesaikan $done event');
    }
    notifs.insert(
        0,
        Notif(
            id: newId('n'),
            userId: u.id,
            title: 'Kehadiran terverifikasi',
            body: '+$gained poin dari ${e.title}. Sertifikat segera tersedia.',
            kind: 'attend',
            createdAt: DateTime.now()));
    _commit();
    return null;
  }

  /// BARU: penyelenggara membalas pesan relawan. Balasan muncul di Notifikasi relawan.
  String? orgReplyToVolunteer(String userId, String title, String body) {
    if (userById(userId) == null) return 'Relawan tidak ditemukan';
    notifs.insert(
        0,
        Notif(
            id: newId('n'),
            userId: userId,
            title: title,
            body: body,
            kind: 'info',
            createdAt: DateTime.now()));
    _commit();
    return null;
  }
}