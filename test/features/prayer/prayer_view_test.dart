import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/prayer/prayer_view.dart';
import 'package:prosoche/ui/components/sk_prayer_row.dart';

import '../../fakes/fake_repositories.dart';

void main() {
  late PrayerSchedule schedule;
  final date = LocalDate(2026, 10, 29);

  setUpAll(() {
    ensureTimeZoneData();
    schedule = PrayerConfig(
      fakeBratislava,
      CalcSettings.resolve(lat: fakeBratislava.lat, country: 'SK'),
    ).schedule;
  });

  test('without schedule: 5 rows, all loggable', () {
    final rows = buildPrayerRows(
      date: date,
      now: DateTime.utc(2026, 10, 29, 3),
      log: {Prayer.fajr: PrayerStatus.excused, Prayer.asr: PrayerStatus.late},
    );
    expect([for (final r in rows) r.prayer], Prayer.salah);
    expect(rows.every((r) => r.canLog && r.time == null), isTrue);
    expect(rows.first.status, isNull);
    expect(rows[2].status, PrayerStatus.late);
  });

  test('states around Maghrib', () {
    final day = schedule.day(date);
    final now = day[Prayer.maghrib].add(const Duration(minutes: 1));
    final rows = {
      for (final r in buildPrayerRows(
        date: date,
        now: now,
        log: const {},
        schedule: schedule,
        notificationsOff: {Prayer.isha},
      ))
        r.prayer: r,
    };
    expect(rows[Prayer.asr]!.state, SkPrayerRowState.passed);
    expect(rows[Prayer.sunrise]!.state, SkPrayerRowState.passed);
    expect(rows[Prayer.sunrise]!.status, isNull);
    expect(rows[Prayer.maghrib]!.state, SkPrayerRowState.current);
    expect(rows[Prayer.isha]!.state, SkPrayerRowState.next);
    expect(rows[Prayer.isha]!.until, day[Prayer.isha].difference(now));
    expect(rows[Prayer.isha]!.canLog, isFalse);
    expect(rows[Prayer.isha]!.notificationOff, isTrue);
  });

  test('isha window ends at the next fajr', () {
    expect(
      prayerWindowEnd(schedule, date, Prayer.isha),
      schedule.day(date.addDays(1))[Prayer.fajr],
    );
    expect(
      prayerWindowEnd(schedule, date, Prayer.sunrise),
      schedule.day(date)[Prayer.dhuhr],
    );
  });

  test('skStatus maps every status (missed is not red)', () {
    expect(skStatus(null), SkPrayerStatus.unlogged);
    expect(skStatus(PrayerStatus.excused), SkPrayerStatus.unlogged);
    expect(skStatus(PrayerStatus.onTime), SkPrayerStatus.onTime);
    expect(skStatus(PrayerStatus.late), SkPrayerStatus.late);
    expect(skStatus(PrayerStatus.missed), SkPrayerStatus.missed);
    expect(skStatus(PrayerStatus.qada), SkPrayerStatus.qada);
  });

  test('estimated prayers: Oslo summer yes, Bratislava winter no', () {
    final oslo = PrayerConfig(
      PrayerLocation(lat: 59.91, lng: 10.75, country: 'NO', tz: 'Europe/Oslo'),
      CalcSettings.resolve(lat: 59.91, country: 'NO'),
    ).schedule;
    expect(estimatedPrayers(oslo, LocalDate(2026, 6, 21)), {
      Prayer.fajr,
      Prayer.isha,
    });
    expect(estimatedPrayers(schedule, LocalDate(2026, 12, 21)), isEmpty);
    // Umm al-Qura: isha je pevny interval po maghribe, nie odhad.
    final mecca = PrayerConfig(
      PrayerLocation(lat: 21.42, lng: 39.83, country: 'SA', tz: 'Asia/Riyadh'),
      CalcSettings.resolve(lat: 21.42, country: 'SA'),
    ).schedule;
    expect(estimatedPrayers(mecca, LocalDate(2026, 6, 21)), isEmpty);
  });
}
