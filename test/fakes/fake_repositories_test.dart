import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/quests/quests.dart';

import 'fake_repositories.dart';

void main() {
  final thu = LocalDate(2026, 10, 29);
  late FakeRepositories fakes;
  late ProviderContainer c;

  Future<T> get<T>(ProviderListenable<Future<T>> f) async {
    final sub = c.listen(f, (_, _) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }

  setUp(() {
    fakes = FakeRepositories(
      prayer: FakePrayerRepository(location: fakeBratislava),
    );
    c = ProviderContainer(
      overrides: fakes.overrides(now: DateTime(2026, 10, 29, 9)),
      retry: (_, _) => null,
    );
  });
  tearDown(() => c.dispose());

  test('providers work on fakes without any database', () async {
    final set = await get(dailySetProvider(thu).future);
    expect(set.n, 10);
    expect(await get(questsProvider(thu).future), hasLength(3));
    expect((await get(streakProvider.future)).current, 5);
    expect(await get(prayerScheduleProvider(thu).future), isNotNull);
    expect(await get(nextPrayerProvider.future), isNotNull);
    expect(await get(surahsProvider.future), hasLength(2));
    expect(await get(contentLanguageProvider.future), 'en');
    expect(
      await get(cardContentProvider(set.set.cards[1].cardId).future),
      isA<AyahContent>(),
    );
    expect(await get(hijriDateProvider(thu).future), isNotNull);
    expect(await get(activeEventsProvider(thu).future), isEmpty);
  });

  test('daily set fake advances cursor and completes', () async {
    final set = await fakes.dailySets.ensure(thu);
    SeenResult? r;
    for (final card in set.set.cards) {
      r = await fakes.dailySets.markSeen(thu, card);
    }
    expect(r!.completedNow, isTrue);
    expect((await fakes.dailySets.get(thu))!.isCompleted, isTrue);
    expect(await fakes.dailySets.activeSetDate(thu.addDays(-1)), thu);
    await fakes.dailySets.markSkipped(thu, set.set.cards.first);
    expect(fakes.dailySets.skipped, hasLength(1));
  });

  test(
    'quest, prayer, quran, cards and actions fakes record changes',
    () async {
      await fakes.quests.setActStatus(thu, QuestStatus.done);
      expect((await fakes.quests.ensure(thu)).last.isDone, isTrue);

      await fakes.prayer.setStatus(thu, Prayer.asr, PrayerStatus.late);
      expect(await fakes.prayer.watchLog(thu).first, {
        Prayer.asr: PrayerStatus.late,
      });
      await fakes.prayer.clearStatus(thu, Prayer.asr);
      await fakes.prayer.saveLocation(fakeBratislava);
      await fakes.prayer.setAsr(AsrMadhab.hanafi);
      await fakes.prayer.setMethod(null);
      await fakes.prayer.setHighLatRule(null);
      await fakes.prayer.setAdjust(Prayer.fajr, 2);
      expect(fakes.prayer.changes, 5);
      expect((await fakes.prayer.config())!.settings.asr, AsrMadhab.hanafi);

      expect((await fakes.cities.search('sara')).single.countryCode, 'BA');
      expect(await fakes.cities.search(''), isEmpty);

      final r = await fakes.quran.markRead(
        AyahId.first,
        mode: ReaderMode.khatm,
        date: thu,
      );
      expect(r.moved, isTrue);
      expect(
        (await fakes.quran.search('2:255', lang: 'en')).reference,
        AyahId(2, 255),
      );

      for (final id in <CardId>[
        HadithCardId(1),
        DuaCardId(1),
        NameCardId(1),
        ReflectionCardId(1),
        EventCardId('fx', thu),
        KhatmCardId(1),
        IntroCardId(thu),
      ]) {
        expect(await fakes.cards.load(id, lang: 'en'), isNotNull);
      }
      expect(await fakes.cards.load(DoneCardId(thu), lang: 'en'), isNull);

      final card = AyahCardId(AyahId(2, 255));
      await fakes.actions.save(thu, card, context: CardContext.feed);
      expect(await fakes.actions.watchIsSaved(card).first, isTrue);
      await fakes.actions.unsave(thu, card, context: CardContext.feed);
      await fakes.actions.log(
        thu,
        card,
        CardAction.shared,
        context: CardContext.feed,
      );
      expect(fakes.actions.logged, hasLength(3));
      expect(await fakes.actions.watchSaved().first, isEmpty);

      expect(await fakes.calendar.month(1448, 5), isA<CalendarMonth>());
      expect(await fakes.calendar.eventText('x', 'en'), isNull);
    },
  );
}
