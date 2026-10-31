import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_routes.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import 'settings_test_app.dart';

ContentSource _source(String id, String kind, {String? lang}) => ContentSource(
  id: id,
  kind: kind,
  lang: lang,
  name: 'Name $id',
  version: '1',
  license: 'test-only',
  attribution: '[PLACEHOLDER attribution]',
  url: 'https://example.invalid/$id',
);

void main() {
  group('groupSources', () {
    test('orders kinds as on the screen, unknown kinds last', () {
      final groups = groupSources([
        _source('f', 'font'),
        _source('x', 'zzz_new'),
        _source('t2', 'translation', lang: 'id'),
        _source('q', 'text'),
        _source('t1', 'translation', lang: 'en'),
        _source('a', 'aaa_new'),
      ]);
      expect(groups.map((g) => g.kind), [
        'text',
        'translation',
        'font',
        'aaa_new',
        'zzz_new',
      ]);
      expect(groups[1].sources.map((s) => s.id), ['t1', 't2']);
    });
  });

  group('SourcesScreen', () {
    testWidgets('every source from content.db is shown with attribution '
        'and version (DoD F-07)', (tester) async {
      final content = contentFixture();
      final rows = await content.contentMetaDao.allSources();
      expect(rows, isNotEmpty);
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: content,
        ),
      );

      for (final r in rows) {
        final tile = find.byKey(ValueKey('source:${r.id}'));
        await tester.scrollUntilVisible(
          tile,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tile, findsOneWidget, reason: r.id);
        expect(r.license, isNotEmpty, reason: 'license of ${r.id}');
        final inTile = find.descendant(of: tile, matching: find.byType(Text));
        final texts = tester
            .widgetList<Text>(inTile)
            .map((t) => t.data ?? '')
            .toList();
        expect(
          texts,
          contains('Version ${r.version} · License: ${r.license}'),
          reason: r.id,
        );
        expect(texts, contains(r.attribution), reason: r.id);
      }
      expect(find.textContaining('Content version fixture'), findsOneWidget);
    });

    testWidgets('link opens the source URL in the browser', (tester) async {
      final links = LinkLog();
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: contentFixture(),
          links: links,
        ),
      );
      final tile = find.byKey(const ValueKey('source:fx-text'));
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(TextButton)),
      );
      await tester.pump();
      expect(links.opened, [Uri.parse('https://example.invalid/fx-text')]);
    });

    testWidgets('failed link shows a snackbar', (tester) async {
      final links = LinkLog()..result = false;
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: contentFixture(),
          links: links,
        ),
      );
      final tile = find.byKey(const ValueKey('source:fx-text'));
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(TextButton)),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('tap shows detail with full license text', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: contentFixture(),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('source:fx-text')));
      await tester.pumpAndSettle();
      expect(find.byType(SkSheet), findsOneWidget);
      expect(find.text('[PLACEHOLDER license note]'), findsOneWidget);
    });

    testWidgets('loading state', (tester) async {
      final never = Completer<SourcesInfo>();
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        settle: false,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          sourcesInfoProvider.overrideWith((ref) => never.future),
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SkLoadingView), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          sourcesInfoProvider.overrideWith(
            (ref) async => const SourcesInfo(sources: []),
          ),
        ],
      );
      expect(find.byType(SkEmptyState), findsOneWidget);
      expect(find.byKey(const ValueKey('sources:oss')), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      var calls = 0;
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          contentDbProvider.overrideWith((ref) async {
            calls++;
            throw StateError('no db');
          }),
        ],
      );
      expect(find.byType(SkErrorState), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    });

    testWidgets('open-source licenses open the license page', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.sources,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          sourcesInfoProvider.overrideWith(
            (ref) async => SourcesInfo(sources: [_source('q', 'text')]),
          ),
        ],
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sources:oss')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('sources:oss')));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
