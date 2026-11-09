import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/blocking/gate_behavior.dart';
import 'package:prosoche/features/settings/settings_paths.dart';

import '../settings_test_app.dart';
import 'blocking_screen_test.dart' show tapIn;
import 'blocking_test_app.dart';

/// G-01: "At the gate" v A10.1 a podobrazovka "Practice first".
void main() {
  testWidgets('switches default on/on/off and write settings', (tester) async {
    final h = BlockingHarness(apps: const [igApp]);
    await pumpSettings(
      tester,
      gate: true,
      overrides: h.overrides,
      location: SettingsPaths.blocking,
    );
    expect(find.text('At the gate'), findsOneWidget);
    SwitchListTile tile(String key) =>
        tester.widget<SwitchListTile>(find.byKey(ValueKey(key)));
    expect(tile('blocking:intent').value, isTrue);
    expect(tile('blocking:friction').value, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('blocking:practice_first')),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );

    await tapIn(tester, find.byKey(const ValueKey('blocking:intent')));
    await tapIn(tester, find.byKey(const ValueKey('blocking:friction')));
    final s = h.fakes.settings;
    expect(await s.get(SettingsKeys.gateAskIntent), isFalse);
    expect(await s.get(SettingsKeys.gateRisingFriction), isFalse);

    await s.set(SettingsKeys.gatePracticeFirst, true);
    await tester.pumpAndSettle();
    expect(find.text('On until 10:00 AM'), findsOneWidget);
    await tapIn(tester, find.byKey(const ValueKey('blocking:practice_first')));
    expect(find.byType(PracticeFirstScreen), findsOneWidget);
  });

  testWidgets('Practice first: switch, time and apps', (tester) async {
    final h = BlockingHarness(apps: const [igApp]);
    await pumpSettings(
      tester,
      gate: true,
      overrides: h.overrides,
      location: BlockingPaths.practiceFirst,
    );
    expect(
      find.text(
        'In the morning, chosen apps stay closed until you finish your '
        'morning preparation in Practice. Emergency still works.',
      ),
      findsOneWidget,
    );
    CheckboxListTile app() => tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('practice_first:app:1')),
    );
    // Vypnute: appky sa nedaju menit.
    expect(app().value, isTrue);
    expect(app().onChanged, isNull);

    await tapIn(tester, find.byKey(const ValueKey('practice_first:switch')));
    expect(await h.fakes.settings.get(SettingsKeys.gatePracticeFirst), isTrue);
    await tapIn(tester, find.byKey(const ValueKey('practice_first:app:1')));
    expect(h.repo.current.single.practiceFirst, isFalse);
    expect(app().value, isFalse);

    await tapIn(tester, find.byKey(const ValueKey('practice_first:until')));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      await h.fakes.settings.get(SettingsKeys.gatePracticeFirstUntil),
      '10:00',
    );
  });

  testWidgets('Practice first without apps says so', (tester) async {
    final h = BlockingHarness();
    await pumpSettings(
      tester,
      gate: true,
      overrides: h.overrides,
      location: BlockingPaths.practiceFirst,
    );
    expect(find.text('Add apps to the gate first.'), findsOneWidget);
  });

  test('practiceFirstUntil parses, invalid is 10:00', () {
    expect(practiceFirstUntil('06:30'), const TimeOfDay(hour: 6, minute: 30));
    expect(practiceFirstUntil('x'), const TimeOfDay(hour: 10, minute: 0));
  });
}
