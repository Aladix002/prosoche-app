import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/ui/ui.dart';

/// Cast dna pre atmosferu hlaviciek (D-05) podla hodiny.
SkDayPhase dayPhaseFor(DateTime now) => SkDayPhase.fromHour(now.hour);

/// Aktualna cast dna (prepocita sa kazdu minutu).
SkDayPhase watchDayPhase(WidgetRef ref) {
  final now =
      ref.watch(minuteTickProvider).value ?? ref.read(appClockProvider).now();
  return dayPhaseFor(now);
}
