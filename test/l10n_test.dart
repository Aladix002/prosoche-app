import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/merge_arb.dart';

/// ARB sa skladaju z lib/l10n/parts (PLAN_VYVOJA kap. 2, ADR-15).
void main() {
  test('lib/l10n/app_*.arb are up to date with parts', () {
    final err = StringBuffer();
    expect(
      runMergeArb(['--check'], out: StringBuffer(), err: err),
      0,
      reason: err.toString(),
    );
  });

  test('every ARB has only keys from app_en.arb', () {
    Set<String> keys(File f) =>
        (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();

    final template = keys(File('lib/l10n/app_en.arb'));
    expect(template, isNotEmpty);
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'));
    for (final arb in arbs) {
      final extra = keys(arb).difference(template);
      expect(extra, isEmpty, reason: '${arb.path} navyse: $extra');
    }
  });
}
