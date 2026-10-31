@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/ramadan/ramadan.dart';
import 'package:sakina/features/ramadan/ramadan_today_card.dart';
import 'package:sakina/ui/theme/sakina_theme.dart';
import 'package:sakina/ui/tokens/sk_space.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/golden/golden.dart';
import '../prayer/f05_test_app.dart';

ThemeData _theme(Brightness b) =>
    b == Brightness.dark ? SakinaTheme.dark() : SakinaTheme.light();

/// Goldeny karty suhur/iftar a zaznamu postu (EN, AR, UR, BN; smoke ID
/// a TR; svetla/tmava; textScale 1.0 a 2.0).
///
///   flutter test --update-goldens test/features/ramadan/ramadan_golden_test.dart
void main() {
  final suhurAt = bratislava(2027, 2, 10, 5, 12);
  final iftarAt = bratislava(2027, 2, 10, 17, 2);

  FastingCountdown countdown(FastingMoment m, tz.TZDateTime at, Duration l) =>
      FastingCountdown(
        moment: m,
        at: at,
        left: l,
        fastingDay: LocalDate(2027, 2, 10),
        dayNumber: 3,
      );

  goldenAllLocales(
    'RamadanCountdownView suhur',
    fileName: 'f08_suhur',
    theme: _theme,
    builder: (_) => RamadanCountdownView(
      night: 3,
      isNight: true,
      countdown: countdown(
        FastingMoment.suhurEnd,
        suhurAt,
        const Duration(hours: 2, minutes: 41),
      ),
    ),
  );

  goldenAllLocales(
    'RamadanCountdownView iftar with fast log',
    fileName: 'f08_iftar',
    theme: _theme,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RamadanCountdownView(
          night: 27,
          isNight: false,
          countdown: countdown(
            FastingMoment.iftar,
            iftarAt,
            const Duration(minutes: 14),
          ),
        ),
        const SizedBox(height: SkSpace.space8),
        FastLogView(
          dayNumber: 26,
          selected: FastEntry.fasted,
          onSelected: (_) {},
        ),
      ],
    ),
  );

  goldenAllLocales(
    'RamadanQuestionView start',
    fileName: 'f08_question',
    theme: _theme,
    builder: (context) => RamadanQuestionView(
      question: context.l10n.ramadanStartQuestion,
      answers: [
        (context.l10n.ramadanStartTomorrow, () async {}),
        (context.l10n.ramadanStartDayAfter, () async {}),
        (context.l10n.ramadanUseCalculation, () async {}),
      ],
    ),
  );
}
