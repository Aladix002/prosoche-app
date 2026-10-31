import 'dart:io';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:share_plus/share_plus.dart';

/// Hlavicka reportu: len technicke udaje (docs/06 C.9) - verzia appky,
/// `content_version`, OS, flavor. Ziadna poloha, ID ani nabozenske data.
@immutable
class DiagnosticsHeader {
  const DiagnosticsHeader(this.fields);

  /// Poradie poli = poradie riadkov v reporte.
  final Map<String, String> fields;

  String toText() =>
      [for (final e in fields.entries) '${e.key}: ${e.value}'].join('\n');
}

/// Zdielanie suboru (systemovy share sheet). V testoch fake.
typedef ShareFile = Future<void> Function(String path, {String? subject});

Future<void> _shareWithSharePlus(String path, {String? subject}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'text/plain')],
      subject: subject,
    ),
  );
}

/// "Nahlasit problem" (docs/06 C.9): citatelny textovy export ring buffera
/// loggera, ktory pouzivatel vidi ([preview]) a posle cez share sheet
/// ([share]). Bez vlastneho servera; nic sa neodosiela automaticky.
///
/// Zaznamy v ring bufferi uz presli allowlistom klucov AppLogger (C.7).
class ProblemReport {
  ProblemReport({
    required this._ring,
    required this._header,
    required this._tempDirectory,
    this._clock = const Clock(),
    ShareFile? share,
  }) : _share = share ?? _shareWithSharePlus;

  final RingBufferLog _ring;
  final DiagnosticsHeader Function() _header;
  final Future<Directory> Function() _tempDirectory;
  final Clock _clock;
  final ShareFile _share;

  static const _separator = '---';

  /// Presny text, ktory odide. [description] pise pouzivatel (volitelne),
  /// [includeLog] = checkbox "Prilozit technicky log" (default zapnuty).
  String preview({String? description, bool includeLog = true}) {
    final b = StringBuffer()
      ..writeln('Prosoche problem report')
      ..writeln('created: ${_clock.now().toUtc().toIso8601String()}')
      ..writeln(_header().toText());
    final text = description?.trim() ?? '';
    if (text.isNotEmpty) {
      b
        ..writeln(_separator)
        ..writeln(text);
    }
    if (includeLog) {
      final entries = _ring.entries;
      b
        ..writeln(_separator)
        ..writeln('log (${entries.length} entries):');
      for (final e in entries) {
        b.writeln(e.toJsonLine());
      }
    }
    return b.toString();
  }

  /// Nazov suboru, napr. `prosoche-report-20261029-1803.txt`.
  @visibleForTesting
  String fileName() {
    final t = _clock.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'prosoche-report-${t.year}${two(t.month)}${two(t.day)}'
        '-${two(t.hour)}${two(t.minute)}.txt';
  }

  /// Zapise [preview] do docasneho textoveho suboru a otvori share sheet.
  /// Vrati cestu k suboru.
  Future<String> share({
    String? description,
    bool includeLog = true,
    String? subject,
  }) async {
    final dir = await _tempDirectory();
    final file = File(p.join(dir.path, fileName()));
    await file.writeAsString(
      preview(description: description, includeLog: includeLog),
      flush: true,
    );
    await _share(file.path, subject: subject);
    return file.path;
  }
}
