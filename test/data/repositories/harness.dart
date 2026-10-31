// Spolocne zostavenie repozitarov D-02 nad in-memory user.db a malym
// content.db fixture (placeholder obsah, PLAN_VYVOJA 5.5).
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/data/repositories/calendar/calendar_repository.dart';
import 'package:sakina/data/repositories/cards/card_actions_repository.dart';
import 'package:sakina/data/repositories/cards/card_content_repository.dart';
import 'package:sakina/data/repositories/catalog/content_catalog.dart';
import 'package:sakina/data/repositories/prayer/prayer_repository.dart';
import 'package:sakina/data/repositories/quran/quran_repository.dart';
import 'package:sakina/data/repositories/settings/drift_settings_repository.dart';
import 'package:sakina/data/repositories/today/daily_set_repository.dart';
import 'package:sakina/data/repositories/today/quest_repository.dart';
import 'package:sakina/data/repositories/today/streak_repository.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

import '../db/fixtures/content_fixture.dart';

/// Mutable hodiny pre testy (lokalny cas).
class TestClock extends Clock {
  TestClock(this.time) : super();

  DateTime time;

  @override
  DateTime now() => time;
}

/// Prida do fixture platne pravidla eventov a sablony questov (tvar z
/// pipeline `sakina-content`, text len placeholder).
Future<void> addCuratedRules(ContentDb content) async {
  Future<void> exec(String sql, List<Object?> args) =>
      content.customStatement(sql, args);
  await exec(
    'INSERT INTO islamic_event (id, status, origin, category, priority, '
    'rule_json) VALUES (?, ?, ?, ?, ?, ?)',
    [
      'fx_friday',
      'approved',
      'example',
      'core',
      50,
      jsonEncode({
        'when': {'weekday': 5},
        'phase': 'day',
        'merge': 'slots',
        'effects': {
          'cards': {
            'event_card_slot': 2,
            'ayah_slots': [3, 4],
            'surah': 2,
            'cursor': 'event_cursor.fx_friday',
          },
        },
      }),
    ],
  );
  await exec(
    'INSERT INTO islamic_event_text (event_id, lang, title, body, source_id) '
    'VALUES (?, ?, ?, ?, ?)',
    ['fx_friday', 'en', '[PLACEHOLDER friday]', null, 'fx-curated'],
  );
  await exec(
    'INSERT INTO quest_template (id, status, origin, slot, rule_json, tags) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [
      'read.fx.verses',
      'approved',
      'example',
      'read',
      jsonEncode({
        'when': null,
        'completion': {
          'mode': 'auto',
          'metric': 'ayah_read',
          'target': {'param': 'n'},
        },
        'params': {
          'n': [3],
        },
      }),
      '[]',
    ],
  );
  await exec(
    'INSERT INTO quest_text (quest_id, lang, title, source_id) '
    'VALUES (?, ?, ?, ?)',
    ['read.fx.verses', 'en', '[PLACEHOLDER read quest]', 'fx-curated'],
  );
}

/// Vsetky repozitare nad jednou user.db a content.db.
class Harness {
  Harness._(this.user, this.content, this.clock, {required this.tz});

  static Future<Harness> create({
    DateTime? now,
    bool rules = true,
    String tz = 'Europe/Bratislava',
    String lang = 'en',
    UserDb? user,
  }) async {
    final content = openContentFixture();
    if (rules) await addCuratedRules(content);
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
  late final CalendarRepository calendar = ContentCalendarRepository(
    catalog: catalog,
    settings: settings,
  );
  late final QuestRepository quests = DriftQuestRepository(
    userDb: user,
    catalog: catalog,
    calendar: calendar,
    installId: () async => 'test-install',
    language: () async => lang,
    clock: clock,
    ensureSet: (date) => dailySets.ensure(date),
  );
  late final DailySetRepository dailySets = DriftDailySetRepository(
    userDb: user,
    catalog: catalog,
    calendar: calendar,
    quests: quests,
    settings: settings,
    clock: clock,
    installId: () async => 'test-install',
    language: () async => lang,
    timeZone: () async => tz,
  );
  late final StreakRepository streak = DriftStreakRepository(
    userDb: user,
    clock: clock,
    timeZone: () async => tz,
  );
  late final QuranRepository quran = DriftQuranRepository(
    content: Future.value(content),
    userDb: user,
    settings: settings,
    clock: clock,
  );
  late final CardContentRepository cards = ContentCardRepository(
    catalog: catalog,
    quran: quran,
    calendar: calendar,
  );
  late final CardActionsRepository actions = DriftCardActionsRepository(
    userDb: user,
    clock: clock,
  );
  int prayerChanges = 0;
  late final PrayerRepository prayer = DriftPrayerRepository(
    db: user,
    settings: settings,
    clock: clock,
    onChanged: () async => prayerChanges++,
  );

  Future<void> dispose() async {
    await user.close();
    await content.close();
  }
}
