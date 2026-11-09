import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/l10n/generated/app_localizations.dart';
import 'package:prosoche/core/router/deep_link.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/home_widget/daily_quote.dart';
import 'package:prosoche/features/home_widget/home_widget_sync.dart';
import 'package:prosoche/features/home_widget/home_widget_wiring.dart';
import 'package:prosoche/features/shell/app_locale.dart';

import '../../data/db/fixtures/content_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));
  final today = LocalDate(2026, 11, 9);
  late ContentDb db;

  setUp(() => db = openContentFixture());
  tearDown(() => db.close());

  List<Map<String, Object?>> daysOf(Map<String, Object?> payload) =>
      (payload['days']! as List).cast<Map<String, Object?>>();

  test('payload has the quote of the day for each day ahead', () async {
    final payload = (await buildWidgetPayload(
      db: db,
      today: today,
      l10n: l10n,
      days: 3,
    ))!;
    expect(payload['v'], widgetPayloadVersion);
    expect(payload['labels'], {
      'eyebrow': "Today's quote",
      'readInContext': 'Read in context',
      'openApp': 'Open Prosoche',
    });
    final days = daysOf(payload);
    expect(
      [for (final d in days) d['date']],
      ['2026-11-08', '2026-11-09', '2026-11-10', '2026-11-11'],
    );

    final rows = await db.cardDao.allCards();
    final pool = widgetQuotePool([
      for (final r in rows)
        if (r.type == 'quote') (id: r.id, text: r.textContent),
    ]);
    final first = days[1];
    expect(first['card'], dailyQuoteId(today, pool));
    expect(days.first['card'], dailyQuoteId(today.addDays(-1), pool));
    final row = rows.firstWhere((r) => r.id == first['card']);
    expect(first['text'], row.textContent.trim());
    expect(first.containsKey('short'), isFalse);
    expect(
      (first['text']! as String).length,
      lessThanOrEqualTo(widgetQuoteMaxChars),
    );
    expect(
      first['reference'],
      isA<String>().having((s) => s, 'value', isNotEmpty),
    );
    expect(first['author'], isNotEmpty);
    expect(first['translatedBy'], startsWith('Translated by '));
    expect(first['link'], startsWith('prosoche://reader/${row.workId}?'));
  });

  test('same date = same payload (stable during the day)', () async {
    final a = await buildWidgetPayload(db: db, today: today, l10n: l10n);
    final b = await buildWidgetPayload(db: db, today: today, l10n: l10n);
    expect(jsonEncode(a), jsonEncode(b));
    expect(daysOf(a!), hasLength(widgetScheduleDays + 1));
  });

  test('disabled cards are never chosen; empty pool = no payload', () async {
    final rows = await db.cardDao.allCards();
    final quotes = {
      for (final r in rows)
        if (r.type == 'quote') r.id,
    };
    final keep = quotes.first;
    final payload = await buildWidgetPayload(
      db: db,
      today: today,
      l10n: l10n,
      days: 5,
      disabled: quotes.difference({keep}),
    );
    expect({for (final d in daysOf(payload!)) d['card']}, {keep});
    expect(
      await buildWidgetPayload(
        db: db,
        today: today,
        l10n: l10n,
        disabled: quotes,
      ),
      isNull,
    );
  });

  group('widgetDeepLink', () {
    QuoteContent quote({String? workId, String? section}) => QuoteContent(
      ContentCardId(CardType.quote, 'meditations.4.3.a'),
      text: 'Text, with & characters?',
      author: 'Marcus Aurelius',
      work: 'Meditations',
      sourceId: 'src',
      ref: '4.3',
      workId: workId,
      sectionKey: section,
    );

    test('opens the reader on the section with the quote highlighted', () {
      final link = widgetDeepLink(
        quote(workId: 'meditations', section: 'meditations.4.3'),
      );
      final route = mapDeepLink(Uri.parse(link))!;
      final uri = Uri.parse(route);
      expect(uri.path, '/reader/meditations');
      expect(uri.queryParameters, {
        'section': 'meditations.4.3',
        'hl': 'Text, with & characters?',
      });
    });

    test('without a work falls back to Today', () {
      expect(mapDeepLink(Uri.parse(widgetDeepLink(quote()))), '/today');
    });
  });

  group('HomeWidgetChannel and wiring', () {
    const channel = MethodChannel(HomeWidgetChannel.name);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('missing platform widget is not an error', () async {
      expect(await const HomeWidgetChannel().update(const {}), isFalse);
    });

    test('sends JSON on start and again after midnight', () async {
      final calls = <Map<String, Object?>>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'update');
        calls.add(jsonDecode(call.arguments as String) as Map<String, Object?>);
        return true;
      });
      final container = ProviderContainer(
        overrides: [
          contentDbProvider.overrideWith((ref) async => db),
          appClockProvider.overrideWithValue(
            Clock.fixed(DateTime(2026, 11, 9, 23, 59)),
          ),
          appLocaleProvider.overrideWithValue(const Locale('en')),
          disabledCardIdsProvider.overrideWithValue(const {}),
        ],
      );
      addTearDown(container.dispose);
      final sync = HomeWidgetSyncer(container, const HomeWidgetChannel())
        ..run();
      await sync.idle;
      expect(sync.lastResult, isTrue);
      expect(calls, hasLength(1));
      final days = (calls.single['days']! as List).cast<Map<String, Object?>>();
      expect(days[1]['date'], '2026-11-09');

      // Viac poziadaviek pocas behu = jeden dalsi beh.
      sync
        ..run()
        ..run()
        ..run();
      await sync.idle;
      expect(calls, hasLength(3));

      final stop = startHomeWidget(container, listenLifecycle: false);
      addTearDown(stop);
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();
      expect(calls.length, greaterThanOrEqualTo(4));
    });

    test('content error is logged, not thrown', () async {
      final container = ProviderContainer(
        overrides: [
          contentDbProvider.overrideWith((ref) async => throw StateError('x')),
          appLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);
      final sync = HomeWidgetSyncer(container, const HomeWidgetChannel())
        ..run();
      await sync.idle;
      expect(sync.lastResult, isFalse);
    });
  });
}
