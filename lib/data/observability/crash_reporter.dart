import 'package:prosoche/core/logging/app_logger.dart';

/// Hlasenie chyb (Sentry, v testoch fake). Bezi len po suhlase
/// `crash_reports` (TECHNICKY_PLAN 13).
abstract interface class CrashReporter {
  bool get isRunning;

  /// Inicializacia SDK. Vola sa az po suhlase.
  Future<void> start();

  /// Okamzite vypnutie. [wipe] = zmazat neodoslane reporty na disku
  /// (odvolanie suhlasu).
  Future<void> stop({required bool wipe});

  /// Breadcrumb z uz prefiltrovaneho zaznamu loggera (allowlist C.7).
  void addBreadcrumb(LogEntry entry);

  /// Report chyby so statickou spravou `tag: msg` a kodom/typom z `kv`.
  void captureEntry(LogEntry entry);
}

/// Hlasenie chyb, ktore nic nerobi (bez suhlasu alebo bez DSN).
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  bool get isRunning => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop({required bool wipe}) async {}

  @override
  void addBreadcrumb(LogEntry entry) {}

  @override
  void captureEntry(LogEntry entry) {}
}

/// [LogSink] loggera, ktory posiela zaznamy do [CrashReporter], len kym
/// bezi (po suhlase). Inak zaznamy ostavaju len v lokalnom ring bufferi.
///
/// - `info` a vyssie = breadcrumb (uz po allowliste klucov AppLogger).
/// - `error`/`fatal` = report, okrem tagov `flutter` a `platform`: tie
///   zachyti Sentry integracia aj so stack trace (docs/06 C.4).
/// - `failure` s `reportable = true` loguje AppLogger ako `error`
///   a sprava `failure` s `code` (zoskupenie podla kodu).
class CrashLogSink implements LogSink {
  CrashReporter? _target;

  /// Napoji alebo odpoji ([reporter] = null) hlasenie chyb.
  // ignore: use_setters_to_change_properties
  void attach(CrashReporter? reporter) => _target = reporter;

  static const _handledBySdk = {'flutter', 'platform'};

  @override
  void add(LogEntry entry) {
    final target = _target;
    if (target == null || !target.isRunning) return;
    if (entry.level.index < LogLevel.info.index) return;
    target.addBreadcrumb(entry);
    if (entry.level.index >= LogLevel.error.index &&
        !_handledBySdk.contains(entry.tag)) {
      target.captureEntry(entry);
    }
  }
}
