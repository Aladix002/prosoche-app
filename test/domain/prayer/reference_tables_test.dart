import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/country_defaults.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/prayer_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Porovnanie s referencnymi tabulkami (TECHNICKY_PLAN 17.2, PLAN_VYVOJA
/// P-01). Kazde CSV v `reference/` ma v hlavicke zdroj, URL, datum stiahnutia,
/// polohu a nastavenie vypoctu; vid `reference/README.md`.
void main() {
  tzdata.initializeTimeZones();

  final tables =
      Directory('test/domain/prayer/reference')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.csv'))
          .map(RefTable.load)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  test('all DoD cities have a reference table', () {
    final cities = tables.map((t) => t.name.split('_').first).toSet();
    expect(
      cities,
      containsAll([
        'bratislava',
        'sarajevo',
        'istanbul',
        'london',
        'jakarta',
        'mecca',
        'karachi',
        'lahore',
        'dhaka',
        'kuala',
        'oslo',
        'reykjavik',
      ]),
    );
  });

  for (final t in tables) {
    group(t.name, () {
      test('has source, url and retrieval date', () {
        expect(t.value('source'), isNotEmpty);
        expect(t.value('url'), startsWith('https://'));
        expect(LocalDate.tryParse(t.value('retrieved')), isNotNull);
        expect(t.rows, hasLength(greaterThanOrEqualTo(365)));
      });

      test('matches within tolerance', () {
        final schedule = t.schedule();
        final problems = <String>[];
        for (final row in t.rows) {
          final day = schedule.day(row.date);
          for (final p in Prayer.values) {
            if (t.skips(p, row.date)) continue;
            final diff = _minutesOfDayDiff(day[p], row.times[p]!);
            if (diff.abs() > t.tolerance(p)) {
              problems.add('${row.date} ${p.name}: ${row.times[p]} vs $diff');
            }
          }
        }
        expect(problems, isEmpty, reason: problems.take(20).join('\n'));
      });
    });
  }

  test('official tables use the country default method', () {
    for (final name in [
      'istanbul_diyanet',
      'jakarta_kemenag',
      'kuala_lumpur_jakim',
      'karachi_aladhan',
      'lahore_aladhan',
      'mecca_aladhan',
    ]) {
      final t = tables.singleWhere((t) => t.name == name);
      final defaults = CountryDefaults.forCountry(t.value('country'));
      expect(defaults.method.key, t.value('method'), reason: name);
      expect(defaults.asr.key, t.value('asr'), reason: name);
      expect(defaults.verified, isTrue, reason: name);
    }
  });
}

/// Rozdiel lokalneho casu [got] a `HH:MM` [want] v minutach, cez polnoc
/// zabaleny do -720..719.
int _minutesOfDayDiff(DateTime got, String want) {
  final [h, m] = want.split(':').map(int.parse).toList();
  final diff = got.hour * 60 + got.minute - (h * 60 + m);
  return (diff + 720) % 1440 - 720;
}

class RefRow {
  RefRow(this.date, this.times);

  final LocalDate date;
  final Map<Prayer, String> times;
}

class RefTable {
  RefTable(this.name, this.meta, this.rows);

  factory RefTable.load(File file) {
    final meta = <String, List<String>>{};
    final rows = <RefRow>[];
    List<String>? header;
    for (final line in file.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('#')) {
        final i = line.indexOf(':');
        final key = line.substring(1, i).trim();
        (meta[key] ??= []).add(line.substring(i + 1).trim());
      } else if (header == null) {
        header = line.split(',');
        final want = ['date', for (final p in Prayer.values) p.name];
        if (header.join(',') != want.join(',')) {
          throw FormatException('${file.path}: header must be $want');
        }
      } else {
        final cells = line.split(',');
        rows.add(
          RefRow(LocalDate.parse(cells.first), {
            for (final (i, p) in Prayer.values.indexed) p: cells[i + 1],
          }),
        );
      }
    }
    final name = file.uri.pathSegments.last.replaceAll('.csv', '');
    return RefTable(name, meta, rows);
  }

  final String name;
  final Map<String, List<String>> meta;
  final List<RefRow> rows;

  String value(String key) => meta[key]!.single;
  String? optional(String key) => meta[key]?.single;

  bool get highLatitude => optional('high_latitude') == 'true';

  /// Pri vysokych sirkach sa +-2 kontroluje len pre casy, ktore nezavisia
  /// od pravidla vysokych sirok (vid poznamku v CSV).
  int tolerance(Prayer p) {
    if (highLatitude &&
        (p == Prayer.fajr || p == Prayer.asr || p == Prayer.isha)) {
      return 30;
    }
    if (p == Prayer.asr && optional('asr_tolerance') != null) {
      return int.parse(value('asr_tolerance'));
    }
    return int.parse(value('tolerance'));
  }

  /// `skip: <prayer> [YYYY-MM-DD[..YYYY-MM-DD]]`
  bool skips(Prayer p, LocalDate date) {
    for (final rule in meta['skip'] ?? const <String>[]) {
      final [prayer, ...range] = rule.split(' ');
      if (prayer != p.name) continue;
      if (range.isEmpty) return true;
      final bounds = range.single.split('..').map(LocalDate.parse).toList();
      if (!date.isBefore(bounds.first) && !date.isAfter(bounds.last)) {
        return true;
      }
    }
    return false;
  }

  PrayerSchedule schedule() {
    final lat = double.parse(value('lat'));
    return PrayerSchedule(
      lat: lat,
      lng: double.parse(value('lng')),
      zone: tz.getLocation(value('tz')),
      settings: CalcSettings.resolve(
        lat: lat,
        country: value('country'),
        method: value('method'),
        asr: value('asr'),
        highLatRule: optional('high_lat_rule'),
      ),
    );
  }
}
