import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/ui/ui.dart';

/// Cast dna pre atmosferu hlaviciek (D-05) podla najblizsej modlitby;
/// bez polohy (bez casov modlitieb) podla hodiny.
SkDayPhase dayPhaseFor(Prayer? next, DateTime now) => switch (next) {
  Prayer.fajr => SkDayPhase.night,
  Prayer.sunrise => SkDayPhase.dawn,
  Prayer.dhuhr => SkDayPhase.morning,
  Prayer.asr => SkDayPhase.midday,
  Prayer.maghrib => SkDayPhase.afternoon,
  Prayer.isha => SkDayPhase.dusk,
  null => SkDayPhase.fromHour(now.hour),
};

/// Aktualna cast dna (prepocita sa kazdu minutu a pri zmene modlitby).
SkDayPhase watchDayPhase(WidgetRef ref) {
  final next = ref.watch(nextPrayerProvider).value;
  final now =
      ref.watch(minuteTickProvider).value ?? ref.read(appClockProvider).now();
  return dayPhaseFor(next?.prayer, now);
}
