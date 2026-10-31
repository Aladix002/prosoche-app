import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/observability/allowlist_analytics.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';

class FakeTransport implements AnalyticsTransport {
  int starts = 0;
  final stops = <bool>[];
  final sent = <(String, Map<String, Object>)>[];
  Error? startError;
  Error? captureError;
  Error? stopError;

  bool get running => starts > stops.length;

  @override
  Future<void> start() async {
    if (startError != null) throw startError!;
    starts++;
  }

  @override
  Future<void> capture(String event, Map<String, Object> props) async {
    if (captureError != null) throw captureError!;
    sent.add((event, props));
  }

  @override
  Future<void> stop({required bool wipe}) async {
    stops.add(wipe);
    if (stopError != null) throw stopError!;
  }
}

class FakeCrashReporter implements CrashReporter {
  var _running = false;
  int starts = 0;
  final stops = <bool>[];
  final crumbs = <LogEntry>[];
  final captured = <LogEntry>[];
  Error? startError;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    if (startError != null) throw startError!;
    starts++;
    _running = true;
  }

  @override
  Future<void> stop({required bool wipe}) async {
    stops.add(wipe);
    _running = false;
  }

  @override
  void addBreadcrumb(LogEntry entry) => crumbs.add(entry);

  @override
  void captureEntry(LogEntry entry) => captured.add(entry);
}
