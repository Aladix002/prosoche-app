import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/gallery/gallery_catalog.dart';
import 'package:prosoche/ui/gallery/sk_gallery_screen.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

import '../helpers/pump_sk.dart';

void main() {
  group('catalog smoke', () {
    for (final component in GalleryCatalog.components) {
      for (final entry in component.entries) {
        testWidgets('${component.name} / ${entry.name}', (tester) async {
          for (final theme in [ProsocheTheme.light(), ProsocheTheme.dark()]) {
            for (final scale in [1.0, 2.0]) {
              await tester.pumpSk(
                Builder(builder: entry.builder),
                theme: theme,
                textScale: scale,
              );
              await tester.pump(const Duration(milliseconds: 50));
              expect(tester.takeException(), isNull);
            }
          }
        });
      }
    }
  });

  group('SkButton', () {
    testWidgets('variants call onPressed and have min heights', (tester) async {
      var taps = 0;
      for (final variant in SkButtonVariant.values) {
        await tester.pumpSk(
          SkButton(label: 'Go', variant: variant, onPressed: () => taps++),
        );
        await tester.tap(find.text('Go'));
        final size = tester.getSize(find.byType(SkButton));
        expect(
          size.height,
          greaterThanOrEqualTo(variant == SkButtonVariant.primary ? 52 : 48),
        );
      }
      expect(taps, SkButtonVariant.values.length);
    });

    testWidgets('loading keeps width, blocks taps and announces', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpSk(
        Center(
          child: SkButton.primary(label: 'Continue', onPressed: () => taps++),
        ),
      );
      final width = tester.getSize(find.byType(SkButton)).width;
      await tester.pumpSk(
        Center(
          child: SkButton.primary(
            label: 'Continue',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(tester.getSize(find.byType(SkButton)).width, width);
      await tester.tap(find.byType(SkButton), warnIfMissed: false);
      expect(taps, 0);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('expand fills width', (tester) async {
      await tester.pumpSk(
        const SkButton.primary(label: 'A', expand: true, onPressed: null),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 800);
    });

    testWidgets('icon button selected state', (tester) async {
      var taps = 0;
      await tester.pumpSk(
        SkIconButton(
          icon: Icons.bookmark_border,
          selectedIcon: Icons.bookmark,
          selected: true,
          tooltip: 'Saved',
          onPressed: () => taps++,
        ),
      );
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
      expect(find.byTooltip('Saved'), findsOneWidget);
    });
  });

  group('SkHoldToConfirmButton', () {
    Widget button(VoidCallback onConfirmed, VoidCallback onAccessible) =>
        SkHoldToConfirmButton(
          label: 'Emergency',
          onConfirmed: onConfirmed,
          onAccessibleConfirm: onAccessible,
        );

    testWidgets('confirms only after full hold', (tester) async {
      var confirmed = 0;
      await tester.pumpSk(button(() => confirmed++, () {}));
      final center = tester.getCenter(find.text('Emergency'));

      var gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(confirmed, 0);

      gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1600));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(confirmed, 1);
    });

    testWidgets('with screen reader a tap opens the alternative', (
      tester,
    ) async {
      var accessible = 0;
      await tester.pumpSk(
        button(() {}, () => accessible++),
        accessibleNavigation: true,
      );
      await tester.tap(find.text('Emergency'));
      expect(accessible, 1);
    });
  });

  group('SkQuestItem', () {
    testWidgets('act: I did it, skipped: undo', (tester) async {
      var action = 0;
      var undo = 0;
      var tap = 0;
      await tester.pumpSk(
        SkQuestItem(
          title: 'Q',
          slot: SkQuestSlot.act,
          onAction: () => action++,
          onTap: () => tap++,
        ),
      );
      await tester.tap(find.text('I did it'));
      await tester.tap(find.text('Q'));
      expect((action, tap), (1, 1));
      expect(find.byType(Checkbox), findsNothing);

      await tester.pumpSk(
        SkQuestItem(
          title: 'Q',
          slot: SkQuestSlot.act,
          state: SkQuestState.skipped,
          onUndo: () => undo++,
        ),
      );
      expect(find.text('Skipped for today'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      expect(undo, 1);
    });

    testWidgets('done shows icon and text, auto shows progress', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSk(
        const SkQuestItem(
          title: 'Read',
          slot: SkQuestSlot.read,
          state: SkQuestState.inProgress,
          progress: 6,
          target: 10,
        ),
      );
      expect(find.text(Bidi.isolateLtr('6 / 10')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.getSemantics(find.byType(SkQuestItem)).value, '6 of 10');

      await tester.pumpSk(
        const SkQuestItem(
          title: 'Learn',
          slot: SkQuestSlot.learn,
          state: SkQuestState.done,
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('large text moves action below title', (tester) async {
      await tester.pumpSk(
        SkQuestItem(title: 'Q', slot: SkQuestSlot.act, onAction: () {}),
        textScale: 2,
      );
      expect(
        tester.getTopLeft(find.text('I did it')).dy,
        greaterThan(tester.getBottomLeft(find.text('Q')).dy),
      );
    });
  });

  group('SkPrayerRow', () {
    testWidgets('merged semantics label and tracker tap', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpSk(
        SkPrayerRow(
          name: 'Asr',
          time: '14:21',
          state: SkPrayerRowState.next,
          relative: 'in 1 h',
          estimated: true,
          notificationOff: true,
          onTrackerTap: () => taps++,
          customActions: {
            const CustomSemanticsAction(label: 'Mark on time'): () {},
          },
        ),
      );
      final node = tester.getSemantics(find.byType(SkPrayerRow));
      expect(
        node.label,
        'Asr, 14:21, in 1 h, Estimated, Notifications off, Not logged',
      );
      await tester.tap(find.byType(SkPrayerTracker));
      expect(taps, 1);
      expect(find.text('14:21 *'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('statuses have labels; current shows Now', (tester) async {
      final handle = tester.ensureSemantics();
      for (final (status, label) in [
        (SkPrayerStatus.onTime, 'On time'),
        (SkPrayerStatus.late, 'Late'),
        (SkPrayerStatus.missed, 'Missed'),
        (SkPrayerStatus.qada, 'Made up'),
      ]) {
        await tester.pumpSk(
          SkPrayerRow(
            name: 'Fajr',
            time: '05:12',
            state: SkPrayerRowState.current,
            status: status,
            adjustedLabel: '+2 min',
          ),
        );
        expect(
          tester.getSemantics(find.byType(SkPrayerRow)).label,
          'Fajr, 05:12, Now, +2 min, $label',
        );
      }
      handle.dispose();
    });

    testWidgets('large text stacks time under name', (tester) async {
      await tester.pumpSk(
        const SkPrayerRow(name: 'Maghrib', time: '16:43'),
        textScale: 2,
      );
      expect(
        tester.getTopLeft(find.text('16:43')).dy,
        greaterThan(tester.getTopLeft(find.text('Maghrib')).dy),
      );
    });
  });

  group('SkDailyProgress', () {
    testWidgets('semantics and states', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSk(const SkDailyProgress(done: 5, total: 12));
      var node = tester.getSemantics(find.byType(SkDailyProgress));
      expect(node.label, 'Daily cards');
      expect(node.value, '5 of 12');
      expect(find.text(Bidi.isolateLtr('5 / 12')), findsOneWidget);

      await tester.pumpSk(const SkDailyProgress(done: 12, total: 12));
      expect(find.byIcon(Icons.check), findsOneWidget);
      node = tester.getSemantics(find.byType(SkDailyProgress));
      expect(node.flagsCollection.isLiveRegion, isTrue);

      await tester.pumpSk(
        const SkDailyProgress(done: 12, total: 12, extended: true),
      );
      expect(find.text('Free reading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('chips and header', () {
    testWidgets('next prayer chip and hijri header are tappable', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpSk(
        Column(
          children: [
            SkNextPrayerChip(label: 'Asr in 1 h', onTap: () => taps++),
            SkHijriHeader(
              date: '14 Jumada al-Ula 1448',
              eventLabel: 'Event',
              offsetLabel: '+1 day',
              onTap: () => taps++,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Asr in 1 h'));
      await tester.tap(find.text('14 Jumada al-Ula 1448'));
      expect(taps, 2);
      expect(find.byType(SkTag), findsOneWidget);
      final style = tester
          .widget<Text>(find.text('14 Jumada al-Ula 1448'))
          .style!;
      expect(style.color, ProsocheColors.light.accentText);
    });
  });

  group('SkNavBar', () {
    testWidgets('selects destinations, no badges', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ProsocheTheme.light(),
          home: Scaffold(
            bottomNavigationBar: SkNavBar(
              selectedIndex: 0,
              onSelected: (i) => selected = i,
              destinations: [
                for (final (i, l) in ['A', 'B', 'C', 'D'].indexed)
                  SkNavDestination(
                    icon: SkNavBar.tabIcons[i].$1,
                    selectedIcon: SkNavBar.tabIcons[i].$2,
                    label: l,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('C'));
      expect(selected, 2);
      expect(find.byType(Badge), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('dialogs and sheets', () {
    testWidgets('confirm dialog returns choice', (tester) async {
      final results = <bool>[];
      await tester.pumpSk(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showSkConfirmDialog(
                context,
                title: 'Delete?',
                confirmLabel: 'Delete',
                variant: SkConfirmVariant.destructive,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results, [true, false]);
    });

    testWidgets('info sheet opens and closes with button', (tester) async {
      await tester.pumpSk(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showSkInfoSheet<void>(
              context,
              title: 'Info',
              closeLabel: 'Close',
              child: const Text('body'),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
    });
  });

  group('banners and snackbar', () {
    testWidgets('banner actions; critical has no dismiss', (tester) async {
      var action = 0;
      var dismiss = 0;
      await tester.pumpSk(
        SkInlineBanner(
          message: 'm',
          actionLabel: 'Fix',
          onAction: () => action++,
          onDismiss: () => dismiss++,
        ),
      );
      await tester.tap(find.text('Fix'));
      await tester.tap(find.text('Dismiss'));
      expect((action, dismiss), (1, 1));

      await tester.pumpSk(
        const SkInlineBanner(
          variant: SkBannerVariant.error,
          message: 'critical',
          actionLabel: 'Fix',
        ),
      );
      expect(find.text('Dismiss'), findsNothing);
    });

    for (final (accessible, seconds) in [(false, 4), (true, 10)]) {
      testWidgets('snackbar lasts $seconds s (screen reader: $accessible)', (
        tester,
      ) async {
        await tester.pumpSk(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSkSnackbar(
                context,
                message: 'Marked as done',
                actionLabel: 'Undo',
                onAction: () {},
              ),
              child: const Text('show'),
            ),
          ),
          accessibleNavigation: accessible,
        );
        await tester.tap(find.text('show'));
        await tester.pump();
        final bar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(bar.duration, Duration(seconds: seconds));
        expect(
          Theme.of(tester.element(find.byType(SnackBar)))
              .snackBarTheme
              .behavior,
          SnackBarBehavior.floating,
        );
      });
    }
  });

  group('states', () {
    testWidgets('loading view timing (docs/01 6)', (tester) async {
      await tester.pumpSk(const SkLoadingView());
      expect(find.byType(SkSkeleton), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SkSkeleton), findsOneWidget);
      expect(find.text('Still loading…'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Still loading…'), findsOneWidget);
    });

    testWidgets('state view switches child', (tester) async {
      for (final state in SkViewState.values) {
        await tester.pumpSk(
          SkStateView(
            state: state,
            loading: const Text('loading'),
            empty: const SkEmptyState(title: 'empty'),
            error: SkErrorState(title: 'error', onRetry: () {}),
            data: (_) => const Text('data'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(state.name), findsOneWidget);
      }
    });

    testWidgets('error state retry and secondary', (tester) async {
      var retry = 0;
      var secondary = 0;
      await tester.pumpSk(
        SkErrorState(
          title: 't',
          body: 'b',
          onRetry: () => retry++,
          secondaryLabel: 'Report a problem',
          onSecondary: () => secondary++,
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('Report a problem'));
      expect((retry, secondary), (1, 1));
    });

    testWidgets('strings scope overrides fallback', (tester) async {
      const custom = SkUiStrings(
        loading: 'L',
        stillLoading: 'SL',
        tryAgain: 'Znova',
        dismiss: 'D',
        undo: 'U',
        cancel: 'C',
        done: 'Hotovo',
        skippedForToday: 'S',
        iDidIt: 'I',
        now: 'N',
        freeReading: 'F',
        dailyCards: 'DC',
        scrollForMore: 'SM',
        notificationsOff: 'NO',
        estimated: 'E',
        holdToConfirm: 'H',
        contentUnavailableTitle: 'CT',
        contentUnavailableBody: 'CB',
        progressOf: _progress,
        prayerStatusUnlogged: 'PU',
        prayerStatusOnTime: 'PO',
        prayerStatusLate: 'PL',
        prayerStatusMissed: 'PM',
        prayerStatusQada: 'PQ',
      );
      await tester.pumpSk(
        SkUiStringsScope(
          strings: custom,
          child: SkErrorState(title: 't', onRetry: () {}),
        ),
      );
      expect(find.text('Znova'), findsOneWidget);
      expect(
        const SkUiStringsScope(
          strings: custom,
          child: SizedBox(),
        ).updateShouldNotify(
          const SkUiStringsScope(
            strings: SkUiStrings.fallbackEn,
            child: SizedBox(),
          ),
        ),
        isTrue,
      );
    });
  });

  group('SkCardSurface', () {
    testWidgets('overflowing full card scrolls with hint', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpSk(
        SizedBox(
          height: 300,
          child: SkCardSurface(
            eyebrow: 'REF',
            arabic: Builder(
              builder: GalleryCatalog.arabicText.entries[5].builder,
            ),
            translation: const Text('translation'),
          ),
        ),
        scroll: false,
      );
      await tester.pump();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.hint == 'Scroll for more',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('compact card is tappable and rejects arabic', (tester) async {
      var taps = 0;
      await tester.pumpSk(
        SkCardSurface(
          variant: SkCardVariant.compact,
          eyebrow: 'REF',
          translation: const Text('preview'),
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.text('preview'));
      expect(taps, 1);
      expect(
        () => SkCardSurface(
          variant: SkCardVariant.compact,
          arabic: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('gallery', () {
    testWidgets('renders and toggles settings', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SkGalleryScreen()));
      expect(find.text('Prosoche UI gallery'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark theme'));
      await tester.tap(find.text('High contrast'));
      await tester.tap(find.text('2.0'));
      await tester.tap(find.text('XL'));
      await tester.pumpAndSettle();
      final theme = Theme.of(tester.element(find.text('Prosoche UI gallery')));
      expect(theme.brightness, Brightness.dark);
      expect(
        theme.extension<ProsocheColors>(),
        ProsocheColors.darkHighContrast,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: SkGalleryScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}

String _progress(int n, int total) => '$n z $total';
