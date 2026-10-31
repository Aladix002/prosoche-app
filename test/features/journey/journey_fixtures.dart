// Fixture data a fakes pre testy Moja cesta (F-06). Obsah je len
// placeholder (PLAN_VYVOJA 5.5).
import 'dart:async';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/streak/streak.dart';

import '../../fakes/fake_repositories.dart';

/// Dnes v testoch (stvrtok 29. 10. 2026, 9:00, ako `pumpSakina`).
final journeyToday = LocalDate(2026, 10, 29);
final journeyNow = DateTime(2026, 10, 29, 9);

/// Stav dna `i` (0 = najstarsi) v 60-dnovej fixture.
DayStatus fixtureStatus(int i) {
  if (i == 20) return DayStatus.excused;
  return switch (i % 10) {
    3 => DayStatus.grace,
    7 => DayStatus.missed,
    _ => DayStatus.done,
  };
}

/// 60 uzavretych dni 30. 8. - 28. 10. 2026 (splnene, grace, nesplnene,
/// jeden ospravedlneny).
final List<DayLogEntry> sixtyDays = [
  for (var i = 0; i < 60; i++)
    DayLogEntry(
      date: journeyToday.addDays(i - 60),
      status: fixtureStatus(i),
      sources: fixtureStatus(i) == DayStatus.done
          ? {DaySource.set, if (i.isEven) DaySource.quest}
          : const {},
    ),
];

StreakSummary fixtureSummary({
  int current = 6,
  int longest = 14,
  int graceLeft = 1,
  LocalDate? refill,
  bool todayDone = false,
}) => StreakSummary(
  state: StreakState(
    current: current,
    longest: longest,
    graceLeft: graceLeft,
    graceRefillAt: refill,
    lastEvaluatedDate: journeyToday.addDays(-1),
  ),
  todayDone: todayDone,
);

/// Streak s 60 dnami historie.
FakeStreakRepository fixtureStreak({StreakSummary? summary}) =>
    FakeStreakRepository(
      summary: summary ?? fixtureSummary(refill: LocalDate(2026, 11, 2)),
      days: sixtyDays,
    );

/// Streak, ktory sa nikdy nenacita (stav loading) alebo zlyha (error).
class StuckStreakRepository extends FakeStreakRepository {
  StuckStreakRepository({this.error});

  final Object? error;

  @override
  Stream<StreakSummary> watch(LocalDate today) => error == null
      ? StreamController<StreakSummary>().stream
      : Stream.error(error!);
}

/// Koran s precitanymi versami, khatmami a nazvami vsetkych 114 sur.
class JourneyQuranRepository extends FakeQuranRepository {
  JourneyQuranRepository({this.counts = const {}, this.khatms = 0});

  final Map<int, int> counts;
  final int khatms;

  @override
  Future<List<SurahInfo>> surahs(String lang) async => [
    for (var s = 1; s <= AyahId.surahCount; s++)
      SurahInfo(
        id: s,
        nameAr: '[PLACEHOLDER name_ar $s]',
        nameTranslit: 'Placeholder $s',
        revelationPlace: 'meccan',
        ayahCount: AyahId.ayahCount(s),
        bismillahPre: s != 1 && s != 9,
      ),
  ];

  @override
  Stream<Map<int, int>> watchReadCounts() => Stream.value(counts);

  @override
  Future<int> completedKhatms() async => khatms;
}

/// Ulozene karty, ktore sa nikdy nenacitaju alebo zlyhaju.
class StuckActionsRepository extends FakeCardActionsRepository {
  StuckActionsRepository({this.error});

  final Object? error;

  @override
  Stream<List<SavedCard>> watchSaved({CardType? type}) => error == null
      ? StreamController<List<SavedCard>>().stream
      : Stream.error(error!);
}

/// Sada dna, ktora zlyha pri citani.
class FailingDailySetRepository extends FakeDailySetRepository {
  @override
  Stream<DailySetState?> watch(LocalDate date) =>
      Stream.error(StateError('db'));
}

/// Telefon 360 x 780 dp.
void phoneView(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Obsah kariet, kde preklad versa ma znacky a poznamky prekladatela
/// (text, footnotes) podla versa (BF-02).
class NotesCardContentRepository extends FakeCardContentRepository {
  NotesCardContentRepository(this.notes);

  final Map<AyahId, (String, String)> notes;

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    final c = await super.load(id, lang: lang);
    if (c is! AyahContent) return c;
    final tr = c.ayah.translation;
    final n = notes[c.ayah.id];
    if (tr == null || n == null) return c;
    return AyahContent(
      id as AyahCardId,
      surah: c.surah,
      arabicOnly: c.arabicOnly,
      ayah: AyahView(
        id: c.ayah.id,
        textUthmani: c.ayah.textUthmani,
        juz: c.ayah.juz,
        page: c.ayah.page,
        translation: TranslationText(
          text: n.$1,
          footnotes: n.$2,
          sourceId: tr.sourceId,
          lang: tr.lang,
          isFallback: tr.isFallback,
        ),
      ),
    );
  }
}
