import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/models/models.dart';
import 'package:volunteer_app/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('akun demo memiliki statistik sesuai desain', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.init();
    expect(s.login('aldi@email.com', '123456'), isNull);
    expect(s.totalEvents, 12);
    expect(s.totalHours, 48);
    expect(s.totalPoints, 2350);
    expect(s.totalImpact, 2850);
    expect(s.earnedBadges.length, 5);
    expect(s.rank, 12);
  });

  test('daftar event lalu hadir menambah poin', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.init();
    s.login('aldi@email.com', '123456');
    final e = s.eventById('e4')!;
    expect(s.registerEvent(e), isNull);
    expect(s.registerEvent(e), isNotNull); // tidak bisa dua kali
    s.markAttended(s.regOf('e4')!.id);
    expect(s.totalPoints, 2350 + e.points);
    expect(s.regOf('e4')!.status, RegStatus.attended);
  });
}
