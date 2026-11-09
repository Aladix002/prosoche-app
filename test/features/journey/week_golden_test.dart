@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/journey/week_summary.dart';
import 'package:prosoche/domain/practice/routine.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/journey/week/week_card.dart';
import 'package:prosoche/features/journey/week/week_share.dart';

import '../../fakes/fake_week_repository.dart';
import '../../helpers/golden/golden.dart';

final _today = LocalDate(2026, 11, 8);

WeekSummary _summary({
  bool gate = true,
  int? streak = 6,
  LocalDate? first,
  bool empty = false,
}) => WeekSummary.compute(
  window: WeekWindow.endingOn(_today),
  gateAvailable: gate,
  streak: streak,
  activity: empty
      ? WeekActivity(firstActiveDay: first)
      : WeekActivity(
          firstActiveDay: first ?? LocalDate(2026, 9, 1),
          gateVisits: [
            for (var i = 0; i < 9; i++)
              GateVisit(
                at: DateTime(2026, 11, 2 + i % 7, 20),
                outcome: i % 3 == 0
                    ? GateOutcome.passed
                    : GateOutcome.dismissed,
                appLabel: i.isEven ? '[PH] app A' : '[PH] app B',
              ),
          ],
          cardsReadByDay: {LocalDate(2026, 11, 3): 12, _today: 9},
          practice: {
            LocalDate(2026, 11, 3): const {
              RoutineKind.morning,
              RoutineKind.evening,
            },
            LocalDate(2026, 11, 5): const {RoutineKind.morning},
            _today: const {RoutineKind.evening},
          },
        ),
);

/// Goldeny karty "This week" a obrazka tyzdna (J-01). Obsah je
/// placeholder.
///
///   flutter test --update-goldens test/features/journey/week_golden_test.dart
void main() {
  goldenAllLocales(
    'WeekSummaryCard',
    fileName: 'j01_week_card',
    builder: (context) => WeekSummaryCard(summary: _summary(), onShare: () {}),
  );

  goldenAllLocales(
    'WeekSummaryCard first week, lite',
    fileName: 'j01_week_card_first',
    builder: (context) => WeekSummaryCard(
      summary: _summary(gate: false, first: LocalDate(2026, 11, 6)),
      onShare: () {},
    ),
  );

  goldenAllLocales(
    'WeekSummaryCard empty',
    fileName: 'j01_week_card_empty',
    builder: (context) =>
        WeekSummaryCard(summary: _summary(empty: true, streak: null)),
  );

  goldenAllLocales(
    'WeekShareImage',
    fileName: 'j01_week_image',
    textScales: const [1.0],
    constraints: const BoxConstraints.tightFor(
      width: ShareImageSize.logicalWidth,
      height: weekImageHeight,
    ),
    builder: (context) => WeekShareImage(
      content: weekShareContent(
        context,
        _summary(),
        quote: fakeWeekQuote(),
        withApps: true,
      ),
      appName: 'Prosoche',
    ),
  );
}
