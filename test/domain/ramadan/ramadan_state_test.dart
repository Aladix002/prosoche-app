import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/prayer_schedule.dart';
import 'package:sakina/domain/ramadan/ramadan.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Prechody stavu s fixnym casom (PLAN_VYVOJA F-08 DoD). Umm al-Qura
/// 1448: 29. Shaban = 6. 2. 2027 (Shaban 30 dni), vypocitany 1. Ramadan
/// = 8. 2. 2027, dlzka 29, Eid 9. 3. 2027. Casy Bratislava (MWL).
void main() {
  tzdata.initializeTimeZones();
  final ba = tz.getLocation('Europe/Bratislava');
  final schedule = PrayerSchedule(
    lat: 48.15,
    lng: 17.11,
    zone: ba,
    settings: CalcSettings(method: PrayerMethod.muslimWorldLeague),
  );
  RamadanDayTimes times() => RamadanDayTimes.forSchedule(schedule);
  final machine = RamadanStateMachine(calendar: IslamicCalendar());

  LocalDate d(int m, int day) => LocalDate(2027, m, day);
  DateTime at(int m, int day, int h, [int min = 0]) =>
      tz.TZDateTime(ba, 2027, m, day, h, min);
  const minute = Duration(minutes: 1);

  RamadanState resolve(DateTime now, {RamadanConfirmation? stored}) =>
      machine.resolve(now: now, times: times(), stored: stored);

  final q = d(2, 6); // 29. Shaban
  final afterAsrQ = times().asr(q).add(minute);
  final afterMaghribQ = times().maghrib(q).add(minute);

  group('before Ramadan', () {
    test('inactive far before', () {
      expect(resolve(at(1, 20, 12)).phase, RamadanPhase.inactive);
      expect(resolve(at(1, 20, 12)), RamadanState.inactive);
    });

    test('upcoming from 25 Shaban with the calculated start', () {
      final s = resolve(at(2, 2, 9));
      expect(s.phase, RamadanPhase.upcoming);
      expect(s.season!.startDate, d(2, 8));
      expect(resolve(at(2, 1, 23, 59)).phase, RamadanPhase.inactive);
    });

    test('29 Shaban: question only after asr', () {
      expect(
        resolve(times().asr(q).subtract(minute)).phase,
        RamadanPhase.upcoming,
      );
      expect(resolve(afterAsrQ).phase, RamadanPhase.awaitingConfirmation);
    });

    test('no answer: still asking on 30 Shaban, calc start at maghrib', () {
      expect(resolve(afterMaghribQ).phase, RamadanPhase.awaitingConfirmation);
      final eve = times().maghrib(d(2, 7));
      expect(
        resolve(eve.subtract(minute)).phase,
        RamadanPhase.awaitingConfirmation,
      );
      final s = resolve(eve);
      expect(s.phase, RamadanPhase.active);
      expect(s.season!.source, SeasonSource.calc);
      expect(s.night, 1);
      expect(s.isNight, isTrue);
    });
  });

  group('confirmation of the start', () {
    test('"Tomorrow": fasting starts 30 Shaban, active from maghrib of Q', () {
      final c = machine.confirmStart(
        hijriYear: 1448,
        answerDay: q,
        daysAhead: 1,
      );
      expect(c.startDate, d(2, 7));
      expect(c.source, SeasonSource.userConfirmed);
      expect(resolve(afterAsrQ, stored: c).phase, RamadanPhase.confirmed);
      final s = resolve(afterMaghribQ, stored: c);
      expect(s.phase, RamadanPhase.active);
      expect(s.night, 1);
      expect(s.countdown!.moment, FastingMoment.suhurEnd);
      expect(s.countdown!.fastingDay, d(2, 7));
      expect(s.countdown!.dayNumber, 1);
    });

    test('"Day after tomorrow": confirmed until maghrib of 7 Feb', () {
      final c = machine.confirmStart(
        hijriYear: 1448,
        answerDay: q,
        daysAhead: 2,
      );
      expect(c.startDate, d(2, 8));
      expect(resolve(afterMaghribQ, stored: c).phase, RamadanPhase.confirmed);
      final eve = times().maghrib(d(2, 7));
      expect(
        resolve(eve.subtract(minute), stored: c).phase,
        RamadanPhase.confirmed,
      );
      expect(resolve(eve, stored: c).phase, RamadanPhase.active);
    });

    test('"Use calculation" stores the calculated start', () {
      final c = machine.confirmStart(hijriYear: 1448, answerDay: q);
      expect(c.startDate, d(2, 8));
      expect(c.source, SeasonSource.calc);
      expect(resolve(afterAsrQ, stored: c).phase, RamadanPhase.confirmed);
    });

    test('invalid answer', () {
      expect(
        () => machine.confirmStart(hijriYear: 1448, answerDay: q, daysAhead: 3),
        throwsRangeError,
      );
    });

    test('global offset +1 moves the calculated season, not the stored', () {
      final plusOne = RamadanStateMachine(calendar: IslamicCalendar(offset: 1));
      final calc = plusOne.resolve(now: at(2, 8, 12), times: times());
      expect(calc.phase, RamadanPhase.awaitingConfirmation);
      expect(calc.season!.startDate, d(2, 9));
      final c = machine.confirmStart(
        hijriYear: 1448,
        answerDay: q,
        daysAhead: 2,
      );
      final stored = plusOne.resolve(
        now: at(2, 8, 12),
        times: times(),
        stored: c,
      );
      expect(stored.phase, RamadanPhase.active);
      expect(stored.season!.startDate, d(2, 8));
    });
  });

  group('active: suhur and iftar countdown', () {
    test('before fajr: suhur ends at fajr of today', () {
      final now = at(2, 10, 3);
      final s = resolve(now);
      expect(s.phase, RamadanPhase.active);
      expect(s.night, 3);
      expect(s.isNight, isTrue);
      final fajr = times().fajr(d(2, 10));
      expect(s.countdown!.moment, FastingMoment.suhurEnd);
      expect(s.countdown!.at, fajr);
      expect(s.countdown!.left, fajr.difference(now));
      expect(s.trackerDay, d(2, 9));
    });

    test('during the day: iftar at maghrib (= PrayerSchedule)', () {
      final now = at(2, 10, 12);
      final s = resolve(now);
      final maghrib = schedule.day(d(2, 10))[Prayer.maghrib];
      expect(s.isNight, isFalse);
      expect(s.night, 3);
      expect(s.countdown!.moment, FastingMoment.iftar);
      expect(s.countdown!.at, maghrib);
      expect(s.countdown!.dayNumber, 3);
      expect(s.trackerDay, d(2, 9));
    });

    test('after iftar: next suhur across midnight, tracker for today', () {
      final now = at(2, 10, 22);
      final s = resolve(now);
      expect(s.night, 4);
      expect(s.isNight, isTrue);
      expect(s.countdown!.moment, FastingMoment.suhurEnd);
      expect(s.countdown!.fastingDay, d(2, 11));
      expect(s.countdown!.left, times().fajr(d(2, 11)).difference(now));
      expect(s.trackerDay, d(2, 10));
      // Po polnoci ide odpocet na ten isty fajr.
      final later = resolve(at(2, 11, 1));
      expect(later.countdown!.at, s.countdown!.at);
      expect(later.night, 4);
    });

    test('night 27 starts at maghrib of day 26', () {
      final day26 = d(3, 5);
      final maghrib = times().maghrib(day26);
      expect(resolve(maghrib.subtract(minute)).night, 26);
      expect(resolve(maghrib).night, 27);
    });

    test('first evening: no tracker yet, suhur countdown for day 1', () {
      final s = resolve(times().maghrib(d(2, 7)).add(minute));
      expect(s.trackerDay, isNull);
      expect(s.countdown!.dayNumber, 1);
    });

    test('without location: active, but no countdown', () {
      final s = machine.resolve(
        now: at(2, 10, 12),
        times: RamadanDayTimes(zone: ba),
      );
      expect(s.phase, RamadanPhase.active);
      expect(s.countdown, isNull);
      expect(s.night, 3);
    });
  });

  group('end of Ramadan', () {
    final day29 = d(3, 8);

    test('day 29 after asr asks about Eid', () {
      expect(resolve(at(3, 8, 10)).phase, RamadanPhase.active);
      final s = resolve(times().asr(day29).add(minute));
      expect(s.phase, RamadanPhase.ending);
      expect(s.phase.isActive, isTrue);
    });

    test('no answer: calculated length 29, Eid at maghrib', () {
      final s = resolve(times().maghrib(day29));
      expect(s.phase, RamadanPhase.eid);
      expect(s.countdown, isNull);
      expect(s.trackerDay, day29);
    });

    test('"No" = 30 days, night 30, then Eid', () {
      final season = resolve(at(3, 8, 16)).season!;
      final c = machine.confirmEnd(season: season, eidTomorrow: false);
      expect(c.lengthDays, 30);
      expect(
        resolve(times().asr(day29).add(minute), stored: c).phase,
        RamadanPhase.active,
      );
      final night30 = resolve(times().maghrib(day29), stored: c);
      expect(night30.phase, RamadanPhase.active);
      expect(night30.night, 30);
      expect(night30.countdown!.fastingDay, d(3, 9));
      expect(
        resolve(times().maghrib(d(3, 9)), stored: c).phase,
        RamadanPhase.eid,
      );
    });

    test('"Yes" = 29 days', () {
      final season = resolve(at(3, 8, 16)).season!;
      final c = machine.confirmEnd(season: season, eidTomorrow: true);
      expect(c.lengthDays, 29);
      expect(
        resolve(times().maghrib(day29), stored: c).phase,
        RamadanPhase.eid,
      );
    });

    test('"Use calculation" stores the Umm al-Qura length', () {
      final season = resolve(at(3, 8, 16)).season!;
      final c = machine.confirmEnd(season: season, eidTomorrow: null);
      expect(c.lengthDays, 29);
      expect(c.startDate, season.startDate);
    });

    test('Eid lasts until maghrib of the Eid day, then inactive', () {
      final eid = d(3, 9);
      expect(
        resolve(times().maghrib(eid).subtract(minute)).phase,
        RamadanPhase.eid,
      );
      expect(resolve(times().maghrib(eid)).phase, RamadanPhase.inactive);
      expect(resolve(at(3, 25, 12)).phase, RamadanPhase.inactive);
    });
  });

  group('DST', () {
    // New York prechadza na letny cas 9. 3. 2025 o 02:00 (9. den
    // Ramadanu 1446, start 1. 3. 2025).
    final ny = tz.getLocation('America/New_York');
    final nySchedule = PrayerSchedule(
      lat: 40.71,
      lng: -74.01,
      zone: ny,
      settings: CalcSettings(method: PrayerMethod.northAmerica),
    );

    test('countdown is real time across the DST jump', () {
      final now = tz.TZDateTime(ny, 2025, 3, 9, 1, 30); // EST
      final s = machine.resolve(
        now: now,
        times: RamadanDayTimes.forSchedule(nySchedule),
      );
      expect(s.phase, RamadanPhase.active);
      expect(s.night, 9);
      final fajr = s.countdown!.at as tz.TZDateTime;
      expect(fajr.timeZoneOffset, const Duration(hours: -4)); // EDT
      final wallMinutes = fajr.hour * 60 + fajr.minute - 90;
      expect(s.countdown!.left.inMinutes, wallMinutes - 60);
    });

    test('iftar on the DST day matches PrayerSchedule', () {
      final now = tz.TZDateTime(ny, 2025, 3, 9, 12);
      final s = machine.resolve(
        now: now,
        times: RamadanDayTimes.forSchedule(nySchedule),
      );
      final maghrib = RamadanDayTimes.forSchedule(nySchedule)
          .maghrib(LocalDate(2025, 3, 9));
      expect(s.countdown!.at, maghrib);
      expect(maghrib.hour, inInclusiveRange(18, 19)); // EDT, nie 17:xx
    });
  });

  group('value types', () {
    test('equality and toString', () {
      final a = resolve(at(2, 10, 12));
      final b = resolve(at(2, 10, 12));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.countdown, b.countdown);
      expect(a.countdown.hashCode, b.countdown.hashCode);
      expect(a.toString(), contains('active'));
      expect(a.countdown.toString(), contains('iftar'));
    });

    test('fallback times without location', () {
      final t = RamadanDayTimes(zone: ba);
      expect(t.hasLocation, isFalse);
      expect(t.fajr(d(2, 10)).hour, 5);
      expect(t.asr(d(2, 10)).hour, 15);
      expect(t.maghrib(d(2, 10)).hour, 18);
      expect(t.dateOf(at(2, 10, 23, 30)), d(2, 10));
    });
  });
}
