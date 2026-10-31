import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/cards/card_providers.dart';
import 'package:sakina/features/settings/settings_providers.dart';

import '../../data/db/fixtures/content_fixture.dart';

/// DoD F-07: zmena prekladu v nastaveniach sa prejavi vo feede (karta
/// versa ma novy text aj atribuciu) nad skutocnymi repozitarmi D-02.
void main() {
  test('changing the translation updates feed cards', () async {
    final content = openContentFixture();
    final user = UserDb.memory();
    addTearDown(() async {
      await user.close();
      await content.close();
    });
    await content.customStatement(
      'INSERT INTO translation (ayah_id, lang, source_id, text) '
      "VALUES (1001, 'en', 'fx-en-b', 'Placeholder other translation 1:1')",
    );
    final container = ProviderContainer(
      overrides: [
        contentDbProvider.overrideWith((ref) async => content),
        userDbProvider.overrideWithValue(user),
        deviceLanguageProvider.overrideWithValue('en'),
        appClockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 10, 29))),
      ],
    );
    addTearDown(container.dispose);

    const id = AyahCardId(AyahId.first);
    // Feed drzi kartu otvorenu (watch), ako FeedScreen.
    final sub = container.listen(cardContentProvider(id), (_, _) {});
    addTearDown(sub.close);

    Future<TranslationText> translation() async {
      final c = await container.read(cardContentProvider(id).future);
      return (c! as AyahContent).ayah.translation!;
    }

    expect((await translation()).sourceId, 'fx-en-a');

    final sources = await container
        .read(quranRepositoryProvider)
        .translationSources('en');
    final other = sources.singleWhere((s) => s.id == 'fx-en-b');
    await container
        .read(settingsActionsProvider)
        .selectTranslation('en', other);
    // Karta sleduje `translation.en` (bez rucnej invalidacie, I-02).
    await pumpEventQueue();

    final t = await translation();
    expect(t.sourceId, 'fx-en-b');
    expect(t.text, 'Placeholder other translation 1:1');
    final attribution = await container.read(
      translationSourceProvider(('en', t.sourceId)).future,
    );
    expect(attribution?.name, 'Fixture fx-en-b');

    // Zmena kluca mimo SettingsActions (napr. import) sa prejavi tiez.
    await container
        .read(settingsRepositoryProvider)
        .set(
          SettingsKeys.translation('en'),
          sources.singleWhere((s) => s.id == 'fx-en-a').settingValue,
        );
    await pumpEventQueue();
    expect((await translation()).sourceId, 'fx-en-a');
  });
}
