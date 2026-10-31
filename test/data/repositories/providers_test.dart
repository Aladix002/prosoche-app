import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart' show UserDb;
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../../fakes/in_memory_settings_repository.dart';
import '../db/fixtures/content_fixture.dart';
import 'harness.dart';

class _FixtureSource implements ContentDbSource {
  _FixtureSource(this.db);

  final ContentDb db;

  @override
  Future<ContentDb> open() async => db;
}

void main() {
  late ProviderContainer c;
  late UserDb user;
  late TestClock clock;
  final thu = LocalDate(2026, 10, 29);

  /// Precita async provider s posluchacom (bez neho je pozastaveny).
  Future<T> get<T>(ProviderListenable<Future<T>> f) async {
    final sub = c.listen(f, (_, _) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }

  setUp(() async {
    final content = openContentFixture();
    user = UserDb.memory();
    clock = TestClock(DateTime(2026, 10, 29, 9));
    c = ProviderContainer(
      overrides: [
        userDbProvider.overrideWithValue(user),
        contentDbSourceProvider.overrideWithValue(_FixtureSource(content)),
        appClockProvider.overrideWithValue(clock),
        deviceTimeZoneProvider.overrideWith((ref) async => 'Europe/Bratislava'),
        deviceLanguageProvider.overrideWithValue('de'),
      ],
      retry: (_, _) => null,
    );
  });

  tearDown(() async {
    c.dispose();
    await user.close();
  });

  test('settings, install id and content language', () async {
    expect(await get(contentLanguageProvider.future), 'en');
    final id = await get(installIdProvider.future);
    expect(id, matches(RegExp('^[0-9a-f]{8}-[0-9a-f]{4}-4')));
    final repo = c.read(settingsRepositoryProvider);
    expect(await ensureInstallId(repo), id);
    final sub = c.listen(settingOf(SettingsKeys.simpleMode), (_, _) {});
    await get(settingProvider(SettingsKeys.simpleMode).future);
    expect(sub.read().value, isFalse);
    await repo.set(SettingsKeys.uiLocale, 'xx');
    await repo.reset(SettingsKeys.intentionText);
    c.invalidate(contentLanguageProvider);
    expect(await get(contentLanguageProvider.future), 'en');
    expect(resolveContentLanguage(null, 'en'), 'en');
    expect(resolveContentLanguage('xx', 'de'), 'en');
    expect(uuidV4(Random(1)), hasLength(36));
  });

  test('today providers', () async {
    expect(await get(activeSetDateProvider.future), thu);
    final set = await get(dailySetProvider(thu).future);
    expect(set.n, 12);
    final quests = await get(questsProvider(thu).future);
    expect(quests.first.slot, QuestSlot.read);
    final streak = await get(streakProvider.future);
    expect(streak.current, 0);
    expect(await get(dayLogProvider((2026, 10)).future), isEmpty);
    expect(await get(dayLogProvider((2026, 12)).future), isEmpty);
    final content = await c.read(
      cardContentProvider(set.set.cards.first.cardId).future,
    );
    expect(content, isA<IntroContent>());
    expect(
      await c.read(cardContentProvider(set.set.cards[1].cardId).future),
      isA<QuoteContent>(),
    );
    expect(await get(isSavedProvider(set.set.cards[1].cardId).future), isFalse);
  });

  test('saved cards', () async {
    await c
        .read(cardActionsRepositoryProvider)
        .save(thu, ContentCardId.quote('q_0001'), context: CardContext.feed);
    expect(
      await c.read(cardActionsRepositoryProvider).watchSaved().first,
      hasLength(1),
    );
  });

  test('local date refreshes from the clock', () {
    expect(c.read(localDateProvider), thu);
    clock.time = DateTime(2026, 10, 30, 0, 1);
    c.read(localDateProvider.notifier).refresh();
    expect(c.read(localDateProvider), thu.addDays(1));
  });

  test('defaults: no content source, no disabled ids', () {
    final bare = ProviderContainer(retry: (_, _) => null);
    addTearDown(bare.dispose);
    expect(() => bare.read(contentDbSourceProvider), throwsA(anything));
    expect(bare.read(disabledCardIdsProvider), isEmpty);
    expect(InMemorySettingsRepository(), isA<SettingsRepository>());
  });
}
