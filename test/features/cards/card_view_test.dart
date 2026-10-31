import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:prosoche/data/observability/problem_report.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/settings/problem_report_sheet.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import '../today/f02_harness.dart';

class FakeSharer implements CardSharer {
  final texts = <String>[];
  final images = <(Uint8List, String)>[];
  final imageShared = Completer<void>();

  @override
  Future<void> shareText(String text) async => texts.add(text);

  @override
  Future<void> shareImage(Uint8List png, {required String text}) async {
    images.add((png, text));
    if (!imageShared.isCompleted) imageShared.complete();
  }
}

final ContentCardId _quote = fakeQuoteId(2);

Future<FakeRepositories> _host(
  WidgetTester tester,
  CardId id, {
  CardSurface surface = CardSurface.feed,
  FakeSharer? sharer,
  double textScale = 1,
  List<Override> extra = const [],
}) async {
  final repos = FakeRepositories();
  await pumpF02(
    tester,
    repos: repos,
    location: '/host',
    textScale: textScale,
    host: CardView(
      cardId: id,
      date: f02Today,
      surface: surface,
      pos: 2,
      total: 10,
    ),
    overrides: [
      cardSharerProvider.overrideWithValue(sharer ?? FakeSharer()),
      ...extra,
    ],
  );
  await tester.pumpAndSettle();
  return repos;
}

const _translator = 'Translated by [PLACEHOLDER translator] (1862)';

List<CardAction> _actions(FakeRepositories repos) => [
  for (final l in repos.actions.logged) l.$2,
];

void main() {
  setUpAll(loadProsocheFonts);

  testWidgets('quote card shows text, type, reference and author', (
    tester,
  ) async {
    await _host(tester, _quote);
    expect(find.byType(QuoteCard), findsOneWidget);
    expect(find.text('QUOTE'), findsOneWidget);
    expect(find.text('[PLACEHOLDER work] 1.1'), findsOneWidget);
    expect(find.text('[PLACEHOLDER quote q_0002]'), findsOneWidget);
    expect(find.text('[PLACEHOLDER author] · $_translator'), findsOneWidget);
    expect(find.text('Read in context'), findsOneWidget);
    expect(find.textContaining('Gutenberg'), findsNothing);
  });

  testWidgets('read in context opens the reader at the source section', (
    tester,
  ) async {
    final repos = await _host(tester, _quote);
    await tester.tap(find.text('Read in context'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader:section:fake-books.1.1')),
      findsOneWidget,
    );
    expect(_actions(repos), [CardAction.sourceOpened]);
    expect(
      repos.library.positions.value['fake-books']?.sectionKey,
      'fake-books.1.1',
    );
  });

  for (final (type, widget) in <(CardType, Type)>[
    (CardType.passage, QuoteCard),
    (CardType.practice, PracticeCard),
    (CardType.prompt, PromptCard),
    (CardType.concept, ConceptCard),
    (CardType.author, AuthorCard),
  ]) {
    testWidgets('${type.wire} card renders with type label', (tester) async {
      await _host(tester, ContentCardId(type, 'x1'));
      expect(find.byType(widget), findsOneWidget);
      expect(find.byType(SkErrorState), findsNothing);
      expect(find.byTooltip('Save'), findsOneWidget);
      expectNoTextClipping(tester);
    });
  }

  testWidgets('practice card opens the exercise in Practice', (tester) async {
    await _host(
      tester,
      ContentCardId(CardType.practice, 'morning-preparation'),
    );
    await tester.tap(find.text('Open in Practice'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('exercise:body:morning-preparation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('exercise:done')));
    await tester.pumpAndSettle();
    expect(find.text('Marked as done.'), findsOneWidget);
  });

  testWidgets('prompt card writes an answer to the local journal', (
    tester,
  ) async {
    final repos = await _host(tester, ContentCardId(CardType.prompt, 'q1'));
    await tester.tap(find.text('Write in journal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('prompt:field')),
      'my answer',
    );
    await tester.tap(find.byKey(const ValueKey('prompt:save')));
    await tester.pumpAndSettle();
    final entry = repos.practice.journal.value.single;
    expect(entry.body, 'my answer');
    expect(entry.promptId, 'prompt:q1');
    expect(_actions(repos), [CardAction.answered]);
  });

  testWidgets('author card opens the first work', (tester) async {
    await _host(tester, ContentCardId(CardType.author, 'a'));
    await tester.tap(find.text('Read [PLACEHOLDER] Work'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader:pages')), findsOneWidget);
  });

  testWidgets('bookmark saves with Undo', (tester) async {
    final repos = await _host(tester, _quote);
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(_actions(repos), [CardAction.saved]);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_actions(repos), [CardAction.saved, CardAction.unsaved]);
  });

  testWidgets('double tap toggles saving', (tester) async {
    final repos = await _host(tester, _quote);
    final target = find.text('[PLACEHOLDER quote q_0002]');
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(_actions(repos), [CardAction.saved]);
  });

  testWidgets('long press: share as text with reference and attribution', (
    tester,
  ) async {
    final sharer = FakeSharer();
    final repos = await _host(tester, _quote, sharer: sharer);
    await tester.longPress(find.byType(QuoteCard));
    await tester.pumpAndSettle();
    expect(find.text('Copy text'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    await tester.tap(find.text('Share as text'));
    await tester.pumpAndSettle();
    expect(sharer.texts.single, '''
[PLACEHOLDER quote q_0002]

- [PLACEHOLDER work] 1.1 ([PLACEHOLDER author])
$_translator
via Prosoche''');
    expect(_actions(repos), [CardAction.shared]);
  });

  testWidgets('copy text puts the share text on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _host(tester, _quote);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();
    expect(copied, contains('[PLACEHOLDER quote q_0002]'));
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('show source logs source_opened', (tester) async {
    final repos = await _host(tester, _quote);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show source'));
    await tester.pumpAndSettle();
    expect(find.text('Source'), findsOneWidget);
    expect(find.text(_translator), findsWidgets);
    expect(_actions(repos), [CardAction.sourceOpened]);
  });

  testWidgets('report a problem shares a .txt with the card reference only', (
    tester,
  ) async {
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('report'),
    ))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    final shared = <String>[];
    final ring = RingBufferLog()
      ..add(
        LogEntry(DateTime.utc(2026), LogLevel.info, 'feed', 'opened', const {}),
      );
    final report = ProblemReport(
      ring: ring,
      header: () => const DiagnosticsHeader({'app_version': '0.9.0'}),
      tempDirectory: () async => dir,
      share: (path, {subject}) async => shared.add(path),
    );
    final repos = await _host(
      tester,
      _quote,
      extra: [problemReportProvider.overrideWithValue(report)],
    );
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    // Pravdivy text: report posiela pouzivatel sam, nic "neodislo".
    expect(find.textContaining('you send yourself'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('report:description')),
      'Wrong reference',
    );
    await tester.tap(find.byKey(const ValueKey('report:preview')));
    await tester.pumpAndSettle();
    expect(find.textContaining('card: quote:q_0002'), findsWidgets);

    final shareButton = find.byKey(const ValueKey('report:share'));
    await tester.ensureVisible(shareButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(shareButton);
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    expect(shared.single, endsWith('.txt'));
    final text = File(shared.single).readAsStringSync();
    expect(text, contains('card: quote:q_0002'));
    expect(text, contains('Wrong reference'));
    expect(text, contains('feed'));
    // Ziadny text karty v reporte.
    expect(text, isNot(contains('[PLACEHOLDER quote')));
    expect(_actions(repos), [CardAction.reported]);
    expect(find.byType(ProblemReportSheet), findsNothing);
  });

  testWidgets('report a problem: cancel logs nothing', (tester) async {
    final repos = await _host(tester, _quote);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(_actions(repos), isEmpty);
  });

  testWidgets('share button shares the rendered image with text', (
    tester,
  ) async {
    final sharer = FakeSharer();
    final png = Uint8List.fromList([1, 2, 3]);
    final repos = FakeRepositories();
    await pumpF02(
      tester,
      repos: repos,
      location: '/host',
      host: CardView(cardId: _quote, date: f02Today),
      overrides: [
        cardSharerProvider.overrideWithValue(sharer),
        cardImageRendererProvider.overrideWithValue((_, _) async => png),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    expect(sharer.images.single.$1, png);
    expect(sharer.images.single.$2, contains('([PLACEHOLDER author])'));
    expect(_actions(repos), [CardAction.shared]);
  });

  testWidgets('too long for an image: offers sharing as text (B0.7)', (
    tester,
  ) async {
    final sharer = FakeSharer();
    await pumpF02(
      tester,
      location: '/host',
      host: CardView(cardId: _quote, date: f02Today),
      overrides: [
        cardSharerProvider.overrideWithValue(sharer),
        cardImageRendererProvider.overrideWithValue((_, _) async => null),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    expect(sharer.images, isEmpty);
    expect(
      find.text('Too long for an image. Share as text instead.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Share as text'));
    await tester.pumpAndSettle();
    expect(sharer.texts, hasLength(1));
  });

  testWidgets('renderWidgetToPng: 1080 px wide PNG, null when too tall', (
    tester,
  ) async {
    await _host(tester, _quote);
    final context = tester.element(find.byType(QuoteCard));
    const data = CardShareData(
      text: '[PLACEHOLDER quote]',
      textLang: 'en',
      reference: 'Placeholder 2.2',
      attribution: 'Placeholder author',
    );
    final png = await tester.runAsync(
      () => renderWidgetToPng(
        context,
        const CardShareImage(data: data, appName: 'Prosoche'),
      ),
    );
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(ByteData.sublistView(png, 16, 20).getUint32(0), 1080);
    expect(ByteData.sublistView(png, 20, 24).getUint32(0), 1350);

    final long = await tester.runAsync(
      () => renderWidgetToPng(
        context,
        CardShareImage(
          data: CardShareData(
            reference: 'x',
            text: List.filled(400, '[PLACEHOLDER]').join(' '),
          ),
          appName: 'Prosoche',
        ),
      ),
    );
    expect(long, isNull);
  });

  testWidgets('shared text never names Project Gutenberg', (tester) async {
    final sharer = FakeSharer();
    await _host(tester, _quote, sharer: sharer);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share as text'));
    await tester.pumpAndSettle();
    expect(sharer.texts.single, contains(_translator));
    expect(sharer.texts.single, isNot(contains('Gutenberg')));
  });

  testWidgets('intro card renders without bookmark', (tester) async {
    await _host(tester, IntroCardId(f02Today));
    expect(find.byType(IntroCard), findsOneWidget);
    expect(find.byType(SkErrorState), findsNothing);
    expect(find.byTooltip('Save'), findsNothing);
    expectNoTextClipping(tester);
  });

  testWidgets('missing content shows the card error', (tester) async {
    final repos = FakeRepositories(
      cards: FakeCardContentRepository(missing: {_quote}),
    );
    await pumpF02(
      tester,
      repos: repos,
      location: '/host',
      host: CardView(cardId: _quote, date: f02Today),
    );
    await tester.pumpAndSettle();
    expect(find.text("This card didn't load"), findsOneWidget);
  });

  testWidgets('intro and quotes in a feed set', (tester) async {
    final repos = FakeRepositories(
      dailySets: FakeDailySetRepository(build: (d) => fakeDailySet(d, n: 3)),
    );
    await pumpF02(tester, repos: repos, location: '/feed', below: '/today');
    await tester.pumpAndSettle();
    expect(find.byType(IntroCard), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
      await tester.pumpAndSettle();
      expect(find.byType(QuoteCard), findsOneWidget);
    }
    expect(find.text(Bidi.isolateLtr('2 / 3')), findsOneWidget);
  });
}
