import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/streak/streak.dart';

const _policy = StreakPolicy();
final _d0 = LocalDate(2026, 11, 2); // pondelok

LocalDate _d(int i) => _d0.addDays(i);

/// Rano dna [i] o 10:00 (lokalne).
DateTime _morning(int i) =>
    _d(i).toLocalDateTime().add(const Duration(hours: 10));

/// Den [i] splneny dokoncenim sady o 20:00.
DayActivity _set(int i) => DayActivity(
  setCompletedAt: _d(i).toLocalDateTime().add(const Duration(hours: 20)),
);

/// Vyhodnoti dni 0..[days]-1 jednym volanim (rano dna [days]).
StreakEvaluation _run(
  Map<int, DayActivity> activity,
  int days, {
  StreakState? from,
}) => _policy.evaluate(
  state: from ?? _policy.initialState(_d0),
  now: _morning(days),
  activity: {for (final e in activity.entries) _d(e.key): e.value},
);

List<DayStatus> _statuses(StreakEvaluation e) => [
  for (final x in e.entries) x.status,
];

void main() {
  test('done days grow the streak and longest', () {
    final e = _run({0: _set(0), 1: _set(1), 2: _set(2)}, 3);
    expect(_statuses(e), List.filled(3, DayStatus.done));
    expect(e.state.current, 3);
    expect(e.state.longest, 3);
    expect(e.state.graceLeft, 2);
    expect(e.state.lastEvaluatedDate, _d(2));
    expect(e.entries.first.sources, {DaySource.set});
  });

  test('one quest is enough', () {
    final e = _run({
      0: DayActivity(questsDoneAt: [_morning(0)]),
    }, 1);
    expect(e.entries.single.status, DayStatus.done);
    expect(e.entries.single.sourcesWire, 'quest');
    final both = _run({
      0: DayActivity(setCompletedAt: _morning(0), questsDoneAt: [_morning(0)]),
    }, 1);
    expect(both.entries.single.sourcesWire, 'set,quest');
  });

  test('1 missed day uses a grace day and keeps the streak', () {
    final e = _run({0: _set(0), 2: _set(2)}, 3);
    expect(_statuses(e), [DayStatus.done, DayStatus.grace, DayStatus.done]);
    expect(e.state.current, 2);
    expect(e.state.graceLeft, 1);
    expect(e.state.graceRefillAt, _d(8));
  });

  test('3 missed days with 2 grace days reset the streak', () {
    final e = _run({0: _set(0), 1: _set(1), 5: _set(5)}, 6);
    expect(_statuses(e), [
      DayStatus.done,
      DayStatus.done,
      DayStatus.grace,
      DayStatus.grace,
      DayStatus.missed,
      DayStatus.done,
    ]);
    expect(e.state.current, 1);
    expect(e.state.longest, 2);
    expect(e.state.graceLeft, 0);
  });

  test('grace days refill 7 days after the first use', () {
    final active = {for (var i = 0; i < 20; i++) i: _set(i)}..remove(1);
    final before = _run(active, 8); // dni 0..7
    expect(before.state.graceLeft, 1);
    expect(before.state.graceRefillAt, _d(8));
    final after = _run(active, 9); // + den 8
    expect(after.state.graceLeft, 2);
    expect(after.state.graceRefillAt, isNull);
    expect(after.state.current, 8);

    // Druhe minutie pred doplnenim neposuva termin doplnenia.
    final twice = _run({0: _set(0), 3: _set(3)}, 4);
    expect(twice.state.graceLeft, 0);
    expect(twice.state.graceRefillAt, _d(8));
    // Den 8 vynechany: najprv doplnenie, potom grace.
    final refilled = _run({0: _set(0), 3: _set(3)}, 9);
    expect(refilled.entries.last.status, DayStatus.grace);
    expect(refilled.state.graceLeft, 1);
    expect(refilled.state.graceRefillAt, _d(15));
  });

  test('excused days neither break the streak nor use grace', () {
    final e = _run({
      0: _set(0),
      for (var i = 1; i <= 5; i++) i: DayActivity(excused: true),
      6: _set(6),
    }, 7);
    expect(e.entries.sublist(1, 6).map((x) => x.status), [
      for (var i = 0; i < 5; i++) DayStatus.excused,
    ]);
    expect(e.state.current, 2);
    expect(e.state.graceLeft, 2);
    // Splneny ospravedlneny den je normalne splneny.
    final done = _run({
      0: DayActivity(excused: true, setCompletedAt: _morning(0)),
    }, 1);
    expect(done.entries.single.status, DayStatus.done);
  });

  group('day boundary and 03:00 tolerance', () {
    DateTime at(int day, int hour, int minute) =>
        DateTime(_d(day).year, _d(day).month, _d(day).day, hour, minute);

    test('yesterday stays open until 03:00', () {
      expect(_policy.lastClosedDay(at(1, 0, 0)), _d(-1));
      expect(_policy.lastClosedDay(at(1, 2, 59)), _d(-1));
      expect(_policy.lastClosedDay(at(1, 3, 0)), _d(0));
      expect(_policy.lastClosedDay(at(1, 23, 59)), _d(0));
    });

    test('completing yesterday before 03:00 counts, after does not', () {
      final ok = DayActivity(setCompletedAt: at(1, 2, 59));
      final late = DayActivity(setCompletedAt: at(1, 3, 0));
      final quest = DayActivity(questsDoneAt: [at(1, 3, 1)]);
      expect(_policy.sources(_d(0), ok), {DaySource.set});
      expect(_policy.sources(_d(0), late), isEmpty);
      expect(_policy.sources(_d(0), quest), isEmpty);
      expect(_policy.sources(_d(0), null), isEmpty);

      final start = _policy.initialState(_d0);
      expect(
        _policy
            .evaluate(state: start, now: at(1, 2, 0), activity: const {})
            .entries,
        isEmpty,
      );
      final e = _policy.evaluate(
        state: start,
        now: at(1, 3, 5),
        activity: {_d(0): ok},
      );
      expect(e.entries.single.status, DayStatus.done);
      final missed = _policy.evaluate(
        state: start,
        now: at(1, 3, 5),
        activity: {_d(0): late},
      );
      expect(missed.entries.single.status, DayStatus.grace);
    });

    test('custom tolerance (docs/02 E1 alternative 4 h)', () {
      const p = StreakPolicy(lateCompletionHours: 4);
      expect(p.lastClosedDay(at(1, 3, 30)), _d(-1));
      expect(p.sources(_d(0), DayActivity(setCompletedAt: at(1, 3, 30))), {
        DaySource.set,
      });
    });

    test('DST change night does not shift the deadline', () {
      // Posledna nedela v oktobri 2026 = 25. 10.
      final sat = LocalDate(2026, 10, 24);
      final sunLate = DateTime(2026, 10, 25, 2, 30);
      expect(_policy.sources(sat, DayActivity(setCompletedAt: sunLate)), {
        DaySource.set,
      });
      expect(_policy.lastClosedDay(sunLate), LocalDate(2026, 10, 23));
    });
  });

  group('time zone changes (docs/02 0.1)', () {
    test('zone change across midnight evaluates each day once', () {
      // 23:30 v Bratislave, sada dna 0 hotova o 23:00.
      final start = _policy.initialState(_d0);
      final activity = {
        _d(0): DayActivity(
          setCompletedAt: _d(0)
              .toLocalDateTime()
              .add(const Duration(hours: 23)),
        ),
      };
      // Let na vychod: lokalne hned 01:30 dna 1. Den 0 este nie je uzavrety.
      final early = _policy.evaluate(
        state: start,
        now: DateTime(_d(1).year, _d(1).month, _d(1).day, 1, 30),
        activity: activity,
      );
      expect(early.entries, isEmpty);
      expect(early.state, start);
      // O 03:00 novej zony sa den 0 uzavrie ako splneny.
      final closed = _policy.evaluate(
        state: early.state,
        now: _morning(1),
        activity: activity,
      );
      expect(
        closed.entries.single,
        DayLogEntry(
          date: _d(0),
          status: DayStatus.done,
          sources: const {DaySource.set},
        ),
      );
      expect(closed.state.current, 1);
    });

    test('west across the date line: no re-evaluation, no regress', () {
      // Vyhodnotene po den 2 (rano dna 3).
      final e = _run({0: _set(0), 1: _set(1), 2: _set(2)}, 3);
      // Prelet na zapad: lokalny datum je znova den 2, potom den 1 vecer.
      for (final now in [_morning(2), _d(1).toLocalDateTime()]) {
        final again = _policy.evaluate(
          state: e.state,
          now: now,
          activity: const {},
        );
        expect(again.entries, isEmpty);
        expect(again.state, e.state);
      }
      // Ked den 3 skonci, vyhodnoti sa len den 3.
      final next = _policy.evaluate(
        state: e.state,
        now: _morning(4),
        activity: {_d(3): _set(3)},
      );
      expect(next.entries.map((x) => x.date), [_d(3)]);
      expect(next.state.current, 4);
    });
  });

  group('idempotent evaluation', () {
    test('10 days without opening == 10 daily evaluations', () {
      final rng = Random(7);
      for (var round = 0; round < 200; round++) {
        final activity = <LocalDate, DayActivity>{
          for (var i = 0; i < 10; i++)
            if (rng.nextInt(3) > 0)
              _d(i): switch (rng.nextInt(4)) {
                0 => DayActivity(excused: true),
                1 => DayActivity(questsDoneAt: [_morning(i)]),
                _ => _set(i),
              },
        };
        final start = _policy.initialState(_d0);
        final batch = _policy.evaluate(
          state: start,
          now: _morning(10),
          activity: activity,
        );
        var daily = start;
        final dailyEntries = <DayLogEntry>[];
        for (var i = 1; i <= 10; i++) {
          final e = _policy.evaluate(
            state: daily,
            now: _morning(i),
            activity: activity,
          );
          daily = e.state;
          dailyEntries.addAll(e.entries);
        }
        expect(batch.state, daily, reason: 'round $round');
        expect(batch.entries, dailyEntries, reason: 'round $round');
        expect(batch.entries, hasLength(10));

        // Opakovane volanie nic nezmeni.
        final again = _policy.evaluate(
          state: batch.state,
          now: _morning(10).add(const Duration(hours: 5)),
          activity: activity,
        );
        expect(again.entries, isEmpty);
        expect(again.state, batch.state);
      }
    });
  });

  group('value types', () {
    test('DayStatus wire', () {
      for (final s in DayStatus.values) {
        expect(DayStatus.fromWire(s.wire), s);
      }
      expect(DayStatus.fromWire('x'), isNull);
    });

    test('StreakState helpers', () {
      final s = _policy.initialState(_d0);
      expect(s.graceLeft, 2);
      expect(s.lastEvaluatedDate, _d(-1));
      expect(s.displayCurrent(todayDone: false), 0);
      expect(s.displayCurrent(todayDone: true), 1);
      expect(s.copyWith(), s);
      expect(s.copyWith().hashCode, s.hashCode);
      expect(s.copyWith(current: 1), isNot(s));
      expect(s.copyWith(graceRefillAt: () => _d(3)).graceRefillAt, _d(3));
      expect(s.toString(), contains('grace: 2'));
      expect(
        const StreakPolicy(maxGraceDays: 1).initialState(_d0).graceLeft,
        1,
      );
    });

    test('DayLogEntry equality', () {
      final a = DayLogEntry(date: _d0, status: DayStatus.grace);
      expect(a, DayLogEntry(date: _d0, status: DayStatus.grace));
      expect(
        a.hashCode,
        DayLogEntry(date: _d0, status: DayStatus.grace).hashCode,
      );
      expect(a.sourcesWire, '');
      expect(a.toString(), contains('grace'));
    });
  });
}
