import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Inicializuje databazu casovych zon balika `timezone` (raz za proces).
/// Potrebuje ju planovanie notifikacii a prepocet casov medzi zonami.
void ensureTimeZoneData() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

var _tzReady = false;

/// `tz.Location` pre IANA nazov alebo null pri neznamej zone.
tz.Location? tryTimeZone(String name) {
  ensureTimeZoneData();
  try {
    return tz.getLocation(name);
  } on tz.LocationNotFoundException {
    return null;
  }
}

/// IANA casova zona zariadenia (`flutter_timezone`), napr.
/// `Europe/Bratislava`. Pri chybe pluginu `UTC`. Po `resumed` treba
/// `ref.invalidate(deviceTimeZoneProvider)` (zmena zony, docs/02 A2).
final FutureProvider<String> deviceTimeZoneProvider = FutureProvider<String>((
  ref,
) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object {
    return 'UTC';
  }
}, name: 'deviceTimeZoneProvider');

/// Jazyk systemu (ISO 639-1), z ktoreho sa berie predvolba `ui.locale`.
/// V testoch `deviceLanguageProvider.overrideWithValue('de')`.
final Provider<String> deviceLanguageProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
  name: 'deviceLanguageProvider',
);

/// Datum dna podla hodin zariadenia (docs/02 0.1, `localDate`).
///
/// Sam sa posunie o polnoci (casovac) a [LocalDateNotifier.refresh] ho
/// prepocita pri `AppLifecycleState.resumed` (zmena zony, dlhe spanie).
final NotifierProvider<LocalDateNotifier, LocalDate> localDateProvider =
    NotifierProvider<LocalDateNotifier, LocalDate>(
      LocalDateNotifier.new,
      name: 'localDateProvider',
    );

class LocalDateNotifier extends Notifier<LocalDate> {
  Timer? _timer;

  @override
  LocalDate build() {
    ref.onDispose(() => _timer?.cancel());
    return _computeAndSchedule();
  }

  /// Prepocita datum z hodin (volat pri `resumed`).
  void refresh() {
    final next = _computeAndSchedule();
    if (next != state) state = next;
  }

  LocalDate _computeAndSchedule() {
    final now = ref.read(appClockProvider).now();
    final today = LocalDate.fromDateTime(now);
    final midnight = today.addDays(1).toLocalDateTime();
    _timer?.cancel();
    // +1 s, aby casovac urcite skoncil az po polnoci.
    _timer = Timer(midnight.difference(now) + const Duration(seconds: 1), () {
      _timer = null;
      refresh();
    });
    return today;
  }
}

/// Tik raz za minutu (zarovnany na celu minutu) pre odpocty v UI.
/// Prvy tik hned.
final StreamProvider<DateTime> minuteTickProvider = StreamProvider<DateTime>((
  ref,
) {
  final clock = ref.watch(appClockProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void tick() {
    final now = clock.now();
    controller.add(now);
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    timer = Timer(next.difference(now), tick);
  }

  ref.onDispose(() {
    timer?.cancel();
    unawaited(controller.close());
  });
  tick();
  return controller.stream;
}, name: 'minuteTickProvider');
