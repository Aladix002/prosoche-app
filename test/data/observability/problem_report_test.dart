import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/observability/problem_report.dart';

void main() {
  late Directory tmp;
  late RingBufferLog ring;
  late AppLogger logger;
  final shared = <(String, String?)>[];

  ProblemReport report() => ProblemReport(
    ring: ring,
    clock: Clock.fixed(DateTime.utc(2026, 10, 29, 18, 3)),
    tempDirectory: () async => tmp,
    header: () => const DiagnosticsHeader({
      'app_version': '1.0.0',
      'content_version': '7',
    }),
    share: (path, {subject}) async => shared.add((path, subject)),
  );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('report');
    ring = RingBufferLog();
    logger = AppLogger(
      sinks: [ring],
      clock: Clock.fixed(DateTime.utc(2026, 10, 29, 18)),
      echoToConsole: false,
    );
    shared.clear();
  });

  tearDown(() => tmp.delete(recursive: true));

  test('preview has header, description and allowlisted log lines', () {
    logger
      ..warn('content', 'download failed', {'code': 'net.http.503', 'lat': 48})
      ..error('db', 'open failed', error: StateError('secret path'));
    final text = report().preview(description: '  Feed is empty  ');
    expect(
      text,
      'Sakina problem report\n'
      'created: 2026-10-29T18:03:00.000Z\n'
      'app_version: 1.0.0\n'
      'content_version: 7\n'
      '---\n'
      'Feed is empty\n'
      '---\n'
      'log (2 entries):\n'
      '{"t":"2026-10-29T18:00:00.000Z","l":"warn","tag":"content",'
      '"msg":"download failed","kv":{"code":"net.http.503"}}\n'
      '{"t":"2026-10-29T18:00:00.000Z","l":"error","tag":"db",'
      '"msg":"open failed","kv":{"type":"StateError"}}\n',
    );
    expect(text, isNot(contains('secret')));
    expect(text, isNot(contains('lat')));
  });

  test('log can be left out and empty description is skipped', () {
    logger.info('content', 'ok');
    final text = report().preview(description: ' ', includeLog: false);
    expect(text, isNot(contains('---')));
    expect(text, isNot(contains('log (')));
  });

  test('share writes a text file and opens the share sheet', () async {
    logger.info('content', 'ok');
    final path = await report().share(subject: 'Sakina problem');
    expect(path, endsWith('sakina-report-20261029-1803.txt'));
    expect(File(path).readAsStringSync(), contains('"msg":"ok"'));
    expect(shared.single, (path, 'Sakina problem'));
  });
}
