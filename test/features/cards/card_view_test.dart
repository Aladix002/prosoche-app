import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/observability/observability_providers.dart';
import 'package:sakina/data/observability/problem_report.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';
import 'package:sakina/domain/quests/quests.dart';
import 'package:sakina/features/cards/cards.dart';
import 'package:sakina/features/settings/problem_report_sheet.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import '../../ui/helpers/arabic_text_guard.dart';
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

class _Explained implements HadithExtraRepository {
  @override
  Future<HadithExtra?> explanation(int hadithId, String lang) async =>
      HadithExtra(
        hadithId: hadithId,
        lang: lang,
        explanation: '[PLACEHOLDER explanation]',
      );
}

final _ayah = AyahCardId(AyahId(2, 2));

Future<FakeRepositories> _host(
  WidgetTester tester,
  CardId id, {
  CardSurface surface = CardSurface.feed,
  FakeSharer? sharer,
  bool explained = false,
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
      if (explained)
        hadithExtraRepositoryProvider.overrideWithValue(_Explained()),
      ...extra,
    ],
  );
  await tester.pumpAndSettle();
  return repos;
}

/// Zdroj `fake` (hadis z FakeCardContentRepository) ako riadok `source`.
final Override _hadithSource = cardSourceProvider.overrideWith(
  (ref, id) async => CardSourceInfo(
    id: id,
    name: 'HadeethEnc - Encyclopedia of Translated Prophetic Hadiths (EN)',
    version: 'snapshot-2026-10-29',
    attribution:
        'HadeethEnc.com - Encyclopedia of Translated Prophetic Hadiths, '
        'version snapshot-2026-10-29',
  ),
);

const _hadithSourceLine =
    'Source: HadeethEnc.com - Encyclopedia of Translated Prophetic Hadiths, '
    'version snapshot-2026-10-29';

List<CardAction> _actions(FakeRepositories repos) => [
  for (final l in repos.actions.logged) l.$2,
];

void main() {
  setUpAll(loadSakinaFonts);

  testWidgets('loading skeleton, then the verse with attribution', (
    tester,
  ) async {
    await _host(tester, _ayah);
    expect(find.byType(AyahCard), findsOneWidget);
    // D-05: typ a referencia su v hlavicke na dvoch riadkoch.
    expect(find.text('VERSE'), findsOneWidget);
    expect(
      find.text('\u2068Placeholder 2\u2069 \u20682:2\u2069'),
      findsOneWidget,
    );
    expect(find.text('Translation: Fake translation'), findsOneWidget);
    expect(find.text('Read in context'), findsOneWidget);
    expect(bareArabicTexts(tester), isEmpty);
  });

  testWidgets('gate hides "Read in context" (B0.2)', (tester) async {
    await _host(tester, _ayah, surface: CardSurface.gate);
    expect(find.text('Read in context'), findsNothing);
  });

  testWidgets('Read in context opens the reader in browse mode', (
    tester,
  ) async {
    await _host(tester, _ayah);
    await tester.tap(find.text('Read in context'));
    await tester.pumpAndSettle();
    expect(
      find.text('stub:/quran/read/2?ayah=2002&mode=browse'),
      findsOneWidget,
    );
  });

  testWidgets('bookmark saves with Undo', (tester) async {
    final repos = await _host(tester, _ayah);
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
    final repos = await _host(tester, _ayah);
    final target = find.text('[PLACEHOLDER translation 2:2]');
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
    final repos = await _host(tester, _ayah, sharer: sharer);
    await tester.longPress(find.byType(AyahCard));
    await tester.pumpAndSettle();
    expect(find.text('Copy text'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    await tester.tap(find.text('Share as text'));
    await tester.pumpAndSettle();
    expect(sharer.texts.single, '''
[PLACEHOLDER uthmani 2:2]

[PLACEHOLDER translation 2:2]

- \u2068Placeholder 2\u2069 \u20682:2\u2069 (Translation: [PLACEHOLDER attribution])
via Mursa''');
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
    await _host(tester, _ayah);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();
    expect(copied, contains('[PLACEHOLDER translation 2:2]'));
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('show source logs source_opened', (tester) async {
    final repos = await _host(tester, _ayah);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show source'));
    await tester.pumpAndSettle();
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('[PLACEHOLDER attribution]'), findsOneWidget);
    expect(find.text('License: test-only'), findsOneWidget);
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
      _ayah,
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
      'Wrong verse number',
    );
    await tester.tap(find.byKey(const ValueKey('report:preview')));
    await tester.pumpAndSettle();
    expect(find.textContaining('card: ayah:2002'), findsWidgets);

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
    expect(text, contains('card: ayah:2002'));
    expect(text, contains('Wrong verse number'));
    expect(text, contains('feed'));
    // Ziadny text karty (preklad, arabcina) v reporte.
    expect(text, isNot(contains('PLACEHOLDER')));
    expect(_actions(repos), [CardAction.reported]);
    expect(find.byType(ProblemReportSheet), findsNothing);
  });

  testWidgets('report a problem: cancel logs nothing', (tester) async {
    final repos = await _host(tester, _ayah);
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
      host: CardView(cardId: _ayah, date: f02Today),
      overrides: [
        cardSharerProvider.overrideWithValue(sharer),
        cardImageRendererProvider.overrideWithValue((_, _) async => png),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    expect(sharer.images.single.$1, png);
    expect(
      sharer.images.single.$2,
      contains('Translation: [PLACEHOLDER attribution]'),
    );
    expect(_actions(repos), [CardAction.shared]);
  });

  testWidgets('too long for an image: offers sharing as text (B0.7)', (
    tester,
  ) async {
    final sharer = FakeSharer();
    await pumpF02(
      tester,
      location: '/host',
      host: CardView(cardId: _ayah, date: f02Today),
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
    await _host(tester, _ayah);
    final context = tester.element(find.byType(AyahCard));
    const data = CardShareData(
      arabic: '[PLACEHOLDER uthmani]',
      arabicIsQuran: true,
      translation: '[PLACEHOLDER translation]',
      reference: 'Placeholder 2:2',
      attribution: 'Translation: Fake translation',
    );
    final png = await tester.runAsync(
      () => renderWidgetToPng(
        context,
        const CardShareImage(data: data, appName: 'Mursa'),
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
            translation: List.filled(400, '[PLACEHOLDER]').join(' '),
          ),
          appName: 'Mursa',
        ),
      ),
    );
    expect(long, isNull);
  });

  testWidgets('hadith: collection, grade; explanation only when available', (
    tester,
  ) async {
    await _host(tester, HadithCardId(13));
    expect(find.byType(HadithCard), findsOneWidget);
    expect(find.text('Grade: Sahih (authentic)'), findsOneWidget);
    expect(find.text('Explanation'), findsNothing);
  });

  testWidgets('hadith shows HadeethEnc source with version (docs/09)', (
    tester,
  ) async {
    final sharer = FakeSharer();
    await _host(
      tester,
      HadithCardId(13),
      sharer: sharer,
      extra: [_hadithSource],
    );
    expect(find.text(_hadithSourceLine), findsOneWidget);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share as text'));
    await tester.pumpAndSettle();
    expect(sharer.texts.single, contains(_hadithSourceLine));
    expect(sharer.texts.single, contains('HadeethEnc.com'));
  });

  testWidgets('source line adds the version when attribution lacks it', (
    tester,
  ) async {
    await _host(
      tester,
      HadithCardId(13),
      extra: [
        cardSourceProvider.overrideWith(
          (ref, id) async => const CardSourceInfo(
            id: 'fake',
            name: 'HadeethEnc',
            version: 'v9',
            attribution: 'HadeethEnc.com',
          ),
        ),
      ],
    );
    expect(find.text('Source: HadeethEnc.com, version v9'), findsOneWidget);
  });

  testWidgets('hadith explanation opens a sheet', (tester) async {
    await _host(tester, HadithCardId(13), explained: true);
    await tester.tap(find.text('Explanation'));
    await tester.pumpAndSettle();
    expect(find.text('[PLACEHOLDER explanation]'), findsOneWidget);
  });

  testWidgets('dua counter counts repetitions locally', (tester) async {
    await _host(tester, DuaCardId(77));
    expect(find.byType(DuaCard), findsOneWidget);
    expect(find.text('Source: example:1'), findsOneWidget);
  });

  testWidgets('intro, name, reflection, event and khatm cards render', (
    tester,
  ) async {
    for (final id in <CardId>[
      IntroCardId(f02Today),
      NameCardId(7),
      ReflectionCardId(31),
      EventCardId('jumuah', f02Today),
      KhatmCardId(1),
    ]) {
      await _host(tester, id);
      expect(find.byType(SkCardSurface), findsOneWidget, reason: '$id');
      expect(find.byType(SkErrorState), findsNothing, reason: '$id');
      // Neulozitelne typy nemaju bookmark (docs/02 0.2).
      expect(
        find.byTooltip('Save'),
        id.type.canSave ? findsOneWidget : findsNothing,
        reason: '$id',
      );
      expectNoTextClipping(tester);
    }
  });

  testWidgets('missing content shows the card error', (tester) async {
    final repos = FakeRepositories(
      cards: FakeCardContentRepository(missing: {_ayah}),
    );
    await pumpF02(
      tester,
      repos: repos,
      location: '/host',
      host: CardView(cardId: _ayah, date: f02Today),
    );
    await tester.pumpAndSettle();
    expect(find.text("This card didn't load"), findsOneWidget);
  });

  testWidgets('every card type in a feed set', (tester) async {
    final repos = FakeRepositories(
      dailySets: FakeDailySetRepository(
        build: (d) => DailySet(
          date: d,
          phase: DayPhase.morning,
          cards: [
            DailySetCard(pos: 1, cardId: IntroCardId(d), slot: Slot.intro),
            DailySetCard(
              pos: 2,
              cardId: EventCardId('jumuah', d),
              slot: Slot.event,
            ),
            DailySetCard(pos: 3, cardId: HadithCardId(1), slot: Slot.hadithDua),
            DailySetCard(pos: 4, cardId: NameCardId(7), slot: Slot.name),
            DailySetCard(
              pos: 5,
              cardId: ReflectionCardId(3),
              slot: Slot.reflection,
            ),
          ],
        ),
      ),
    );
    await pumpF02(tester, repos: repos, location: '/feed', below: '/today');
    await tester.pumpAndSettle();
    for (final type in [IntroCard, EventCard, HadithCard, NameCard]) {
      expect(find.byType(type), findsOneWidget, reason: '$type');
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
      await tester.pumpAndSettle();
    }
    expect(find.byType(ReflectionCard), findsOneWidget);
    expect(find.text(Bidi.isolateLtr('0 / 5')), findsNothing);
    expect(find.text(Bidi.isolateLtr('4 / 5')), findsOneWidget);
  });
}
