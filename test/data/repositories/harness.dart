// Spolocne zostavenie repozitarov D-02 nad in-memory user.db a malym
// content.db fixture (placeholder obsah, PLAN_VYVOJA 5.5).
import 'package:clock/clock.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/cards/card_actions_repository.dart';
import 'package:prosoche/data/repositories/cards/card_content_repository.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/settings/drift_settings_repository.dart';
import 'package:prosoche/data/repositories/today/daily_set_repository.dart';
import 'package:prosoche/data/repositories/today/quest_repository.dart';
import 'package:prosoche/data/repositories/today/streak_repository.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../db/fixtures/content_fixture.dart';

/// Mutable hodiny pre testy (lokalny cas).
class TestClock extends Clock {
  TestClock(this.time) : super();

  DateTime time;

  @override
  DateTime now() => time;
}

/// Vsetky repozitare nad jednou user.db a content.db.
class Harness {
  Harness._(this.user, this.content, this.clock, {required this.tz});

  static Future<Harness> create({
    DateTime? now,
    String tz = 'Europe/Bratislava',
    String lang = 'en',
    UserDb? user,
  }) async {
    final content = openContentFixture();
    final h = Harness._(
      user ?? UserDb.memory(),
      content,
      TestClock(now ?? DateTime(2026, 10, 29, 9)),
      tz: tz,
    )..lang = lang;
    await h.settings.set(SettingsKeys.installId, 'test-install');
    return h;
  }

  final UserDb user;
  final ContentDb content;
  final TestClock clock;
  String tz;
  String lang = 'en';

  late final SettingsRepository settings = DriftSettingsRepository(
    user.settingsDao,
  );
  late final ContentCatalog catalog = ContentCatalog(Future.value(content));
  late final QuestRepository quests = DriftQuestRepository(
    userDb: user,
    catalog: catalog,
    installId: () async => 'test-install',
    language: () async => lang,
    clock: clock,
    ensureSet: (date) => dailySets.ensure(date),
  );
  late final DailySetRepository dailySets = DriftDailySetRepository(
    userDb: user,
    catalog: catalog,
    quests: quests,
    settings: settings,
    clock: clock,
    installId: () async => 'test-install',
    timeZone: () async => tz,
  );
  late final StreakRepository streak = DriftStreakRepository(
    userDb: user,
    clock: clock,
    timeZone: () async => tz,
  );
  late final CardContentRepository cards = ContentCardRepository(
    catalog: catalog,
  );
  late final CardActionsRepository actions = DriftCardActionsRepository(
    userDb: user,
    clock: clock,
  );

  Future<void> dispose() async {
    await user.close();
    await content.close();
  }
}
