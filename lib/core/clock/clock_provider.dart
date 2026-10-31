import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:clock/clock.dart' show Clock;

part 'clock_provider.g.dart';

/// Jediny zdroj aktualneho casu v appke (plan 3.1).
///
/// Nikdy nevolat `DateTime.now()`. V testoch prepisat cez
/// `appClockProvider.overrideWithValue(Clock.fixed(...))`.
@Riverpod(keepAlive: true)
Clock appClock(Ref ref) => const Clock();
