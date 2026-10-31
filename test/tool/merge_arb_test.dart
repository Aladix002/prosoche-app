import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/merge_arb.dart';

Map<String, Object?> _json(String s) => jsonDecode(s) as Map<String, Object?>;

void main() {
  group('mergeArbParts', () {
    test('merges parts sorted by task ID with metadata', () {
      final out = mergeArbParts({
        'F-02_en.arb': '{"b": "B", "@b": {"description": "d"}}',
        'S-01_en.arb': '{"@@locale": "en", "a": "A"}',
      });
      expect(out.keys, ['app_en.arb']);
      final merged = _json(out['app_en.arb']!);
      expect(merged.keys.toList(), ['@@locale', 'b', '@b', 'a']);
      expect(merged['@@locale'], 'en');
      expect(out['app_en.arb'], endsWith('}\n'));
    });

    test('creates one output per language, missing keys allowed', () {
      final out = mergeArbParts({
        'S-01_en.arb': '{"a": "A", "b": "B"}',
        'S-01_ar.arb': '{"a": "[ar] A"}',
        'U-02_pt_BR.arb': '{"b": "[pt] B"}',
      });
      expect(out.keys, ['app_en.arb', 'app_ar.arb', 'app_pt_BR.arb']);
      expect(_json(out['app_ar.arb']!), {'@@locale': 'ar', 'a': '[ar] A'});
    });

    test('rejects duplicate keys across parts', () {
      expect(
        () => mergeArbParts({
          'S-01_en.arb': '{"a": "A"}',
          'F-02_en.arb': '{"a": "B"}',
        }),
        throwsA(
          isA<ArbMergeException>().having(
            (e) => e.message,
            'message',
            contains('"a"'),
          ),
        ),
      );
    });

    for (final (name, parts) in [
      ('bad file name', {'feed_en.arb': '{}'}),
      ('no EN template', {'S-01_ar.arb': '{"a": "x"}'}),
      ('invalid JSON', {'S-01_en.arb': '{'}),
      ('non-object JSON', {'S-01_en.arb': '[]'}),
      ('wrong @@locale', {'S-01_en.arb': '{"@@locale": "ar"}'}),
      ('metadata without key', {'S-01_en.arb': '{"@a": {}}'}),
      (
        'key missing in EN',
        {'S-01_en.arb': '{"a": "A"}', 'S-01_ar.arb': '{"z": "x"}'},
      ),
    ]) {
      test('rejects $name', () {
        expect(() => mergeArbParts(parts), throwsA(isA<ArbMergeException>()));
      });
    }
  });

  group('runMergeArb', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('merge_arb_');
      Directory('${dir.path}/parts').createSync();
      File('${dir.path}/parts/S-01_en.arb').writeAsStringSync('{"a": "A"}');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    int run(List<String> args, [StringBuffer? err]) => runMergeArb(
      args,
      dir: dir.path,
      out: StringBuffer(),
      err: err ?? StringBuffer(),
    );

    test('check fails when stale, write fixes it', () {
      final err = StringBuffer();
      File('${dir.path}/app_bs.arb').writeAsStringSync('{}');
      expect(run(['--check'], err), 1);
      expect(err.toString(), contains('app_en.arb'));

      expect(run([]), 0);
      expect(File('${dir.path}/app_en.arb').existsSync(), isTrue);
      expect(File('${dir.path}/app_bs.arb').existsSync(), isFalse);
      expect(run(['--check']), 0);
      expect(run([]), 0);
    });

    test('reports merge errors', () {
      File('${dir.path}/parts/F-02_en.arb').writeAsStringSync('{"a": "B"}');
      final err = StringBuffer();
      expect(run([], err), 1);
      expect(err.toString(), contains('merge_arb'));
    });

    test('fails without parts directory', () {
      Directory('${dir.path}/parts').deleteSync(recursive: true);
      expect(run([]), 2);
    });
  });
}
