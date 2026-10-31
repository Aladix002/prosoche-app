import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import 'in_memory_settings_repository.dart';

void main() {
  late InMemorySettingsRepository repo;

  setUp(() => repo = InMemorySettingsRepository());
  tearDown(() => repo.dispose());

  test('get returns default, set stores encoded value', () async {
    expect(await repo.get(SettingsKeys.feedCardsCount), 12);
    await repo.set(SettingsKeys.feedCardsCount, 16);
    expect(await repo.get(SettingsKeys.feedCardsCount), 16);
    expect(repo.raw, {'feed.cards_count': '16'});
  });

  test('set rejects invalid value', () async {
    await expectLater(
      repo.set(SettingsKeys.feedCardsCount, 5),
      throwsArgumentError,
    );
    expect(repo.raw, isEmpty);
  });

  test('reset returns to default', () async {
    await repo.set(SettingsKeys.simpleMode, true);
    await repo.reset(SettingsKeys.simpleMode);
    expect(await repo.get(SettingsKeys.simpleMode), isFalse);
  });

  test('seeded raw values, invalid ones read as default', () async {
    final seeded = InMemorySettingsRepository({
      'ui.locale': '"ur"',
      'feed.cards_count': '"many"',
    });
    addTearDown(seeded.dispose);
    expect(await seeded.get(SettingsKeys.uiLocale), 'ur');
    expect(await seeded.get(SettingsKeys.feedCardsCount), 12);
  });

  test('watch emits current value and changes of that key only', () async {
    final values = <bool>[];
    final sub = repo.watch(SettingsKeys.analyticsOptIn).listen(values.add);
    await pumpEventQueue();
    await repo.set(SettingsKeys.analyticsOptIn, true);
    await repo.set(SettingsKeys.crashReports, false);
    await repo.reset(SettingsKeys.analyticsOptIn);
    await pumpEventQueue();
    await sub.cancel();
    expect(values, [false, true, false]);
  });
}
