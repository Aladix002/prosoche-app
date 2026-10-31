import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/notifications/notification_texts.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Texty Ramadan notifikacii (F-08): len UI texty, ziadna dua.
void main() {
  tzdata.initializeTimeZones();
  final ba = tz.getLocation('Europe/Bratislava');
  final day = LocalDate(2027, 2, 10);

  final suhur = PlannedNotification(
    kind: NotificationKind.suhur,
    day: day,
    at: tz.TZDateTime(ba, 2027, 2, 10, 4, 27),
    prayer: Prayer.fajr,
    cardMinutes: 45,
  );
  final iftar = PlannedNotification(
    kind: NotificationKind.iftar,
    day: day,
    at: tz.TZDateTime(ba, 2027, 2, 10, 17, 2),
    prayer: Prayer.maghrib,
  );

  test('standard texts', () async {
    final texts = await NotificationTexts.load(const Locale('en'));
    expect(texts.render(suhur, private: false), (
      'Suhur · 04:27',
      'Suhur ends in 45 minutes.',
    ));
    expect(texts.render(iftar, private: false), (
      'Iftar · 17:02',
      "It's time for Maghrib.",
    ));
  });

  test('private mode hides Ramadan words', () async {
    final texts = await NotificationTexts.load(const Locale('en'));
    final (st, sb) = texts.render(suhur, private: true);
    final (it, ib) = texts.render(iftar, private: true);
    for (final t in [st, sb, it, ib]) {
      expect(t.toLowerCase(), isNot(contains('suhur')));
      expect(t.toLowerCase(), isNot(contains('iftar')));
    }
    expect(it, contains('17:02'));
  });

  test('ids replace morning and maghrib of the day', () {
    expect(suhur.id, NotificationIds.of(NotificationKind.morning, day));
    expect(
      iftar.id,
      NotificationIds.of(NotificationKind.prayer, day, Prayer.maghrib),
    );
    expect(suhur.channel, NotificationChannel.daily);
    expect(iftar.channel, NotificationChannel.prayer);
  });
}
