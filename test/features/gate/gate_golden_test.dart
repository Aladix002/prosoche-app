@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/features/gate/gate_views.dart';

import '../../helpers/golden/golden.dart';

/// Goldeny stavov brany (PLAN_VYVOJA 4.2 bod 3, B-02): EN, AR, UR, BN x
/// svetla/tmava x textScale 1.0/2.0, ID a TR smoke. Karty maju vlastne
/// goldeny (F-02), tu je len chrome brany a stavove obrazovky.
///
///   flutter test --update-goldens test/features/gate/gate_golden_test.dart
void main() {
  void noop() {}

  /// Obrazovka telefonu (360 x 640).
  void screen(String name, Widget Function(BuildContext context) build) {
    goldenAllLocales(
      'gate $name',
      fileName: 'gate_$name',
      builder: (context) =>
          SizedBox(width: 360, height: 640, child: build(context)),
    );
  }

  screen(
    'cards',
    (context) => Column(
      children: [
        GateHeader(app: 'Instagram', done: 1, total: 3, onBack: noop),
        const Expanded(child: SizedBox.expand()),
        GateFooter(
          secondsLeft: 3,
          onNext: null,
          onEmergency: noop,
          onEmergencyA11y: noop,
        ),
      ],
    ),
  );

  screen(
    'free_reading',
    (context) => Column(
      children: [
        GateHeader(
          app: null,
          done: 3,
          total: 3,
          onBack: noop,
          freeReading: true,
          onContinue: noop,
        ),
        const Expanded(child: SizedBox.expand()),
        GateFooter(
          secondsLeft: 0,
          onNext: noop,
          onEmergency: null,
          onEmergencyA11y: null,
        ),
      ],
    ),
  );

  screen(
    'unlocked',
    (context) => GateUnlockedView(
      app: 'Instagram',
      minutes: 10,
      setFinished: true,
      onContinue: noop,
      onClose: noop,
      onKeepReading: noop,
    ),
  );

  screen(
    'error',
    (context) =>
        GateErrorView(app: 'Instagram', onContinue: noop, onBack: noop),
  );

  screen(
    'emergency',
    (context) =>
        GateEmergencyView(app: 'Instagram', secondsLeft: 7, onCancel: noop),
  );

  // G-01: pocitadlo s odporom v hlavicke, otazka zameru, ranny zamok.
  screen(
    'cards_friction',
    (context) => Column(
      children: [
        GateHeader(
          app: 'Instagram',
          done: 1,
          total: 4,
          onBack: noop,
          note: [
            context.l10n.gateOpenCountFor(
              'Instagram',
              4,
              Localizations.localeOf(context),
            ),
            context.l10n.gateFrictionNote,
          ].join(' '),
        ),
        const Expanded(child: SizedBox.expand()),
        GateFooter(
          secondsLeft: 7,
          onNext: null,
          onEmergency: noop,
          onEmergencyA11y: noop,
        ),
      ],
    ),
  );

  screen(
    'intent',
    (context) => GateIntentView(
      app: 'Instagram',
      opensNote: context.l10n.gateOpenCountFor(
        'Instagram',
        2,
        Localizations.localeOf(context),
      ),
      onChoose: (_) {},
      onEmergency: noop,
      onEmergencyA11y: noop,
    ),
  );

  screen(
    'practice_first',
    (context) => GatePracticeFirstView(
      app: 'Instagram',
      until: const TimeOfDay(hour: 10, minute: 0),
      onStart: noop,
      onBack: noop,
      onEmergency: noop,
      onEmergencyA11y: noop,
    ),
  );
}
