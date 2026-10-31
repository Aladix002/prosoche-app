import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pravidla vrstiev (plan 3.1, ADR-14): `lib/domain` je cisty Dart.
final _forbidden = <RegExp, String>{
  RegExp(r'''^\s*(import|export)\s+['"]package:flutter/'''): 'package:flutter',
  RegExp(r'''^\s*(import|export)\s+['"]package:flutter_\w+/'''):
      'flutter pluginy',
  RegExp(r'''^\s*(import|export)\s+['"]package:drift'''): 'drift',
  RegExp(r'''^\s*(import|export)\s+['"]dart:ui['"]'''): 'dart:ui',
  RegExp(r'''^\s*(import|export)\s+['"]package:prosoche/(data|features)/'''):
      'data/features vrstva',
  RegExp(r'DateTime\.now\(\)'): 'DateTime.now() (pouzi Clock)',
};

/// Vrati zoznam porušeni v jednom subore (prazdny = ok).
List<String> domainViolations(String path, String source) => [
  for (final (i, line) in source.split('\n').indexed)
    for (final MapEntry(key: re, value: what) in _forbidden.entries)
      if (re.hasMatch(line)) '$path:${i + 1}: $what',
];

void main() {
  group('domainViolations', () {
    test('catches forbidden imports', () {
      const src = '''
import 'package:flutter/material.dart';
import "package:drift/drift.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/data/db/user_db.dart';
export 'dart:ui';
final t = DateTime.now();
''';
      expect(domainViolations('x.dart', src), hasLength(6));
    });

    test('allows pure dart imports', () {
      const src = '''
import 'dart:math';
import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/domain/feed/card.dart';
''';
      expect(domainViolations('x.dart', src), isEmpty);
    });
  });

  test('lib/domain does not import flutter, drift or outer layers', () {
    final dir = Directory('lib/domain');
    expect(dir.existsSync(), isTrue);
    final violations = [
      for (final f in dir.listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          ...domainViolations(f.path, f.readAsStringSync()),
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
