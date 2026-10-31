import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche_lints/prosoche_lints.dart';

String _fixture(String name) =>
    File(p.join('packages', 'prosoche_lints', 'test', 'fixtures', name))
        .readAsStringSync();

/// `// expect: kod[, kod]` na riadku -> ocakavane (riadok, kod).
Set<(int, String)> _expected(String content) {
  final re = RegExp(r'// expect: ([\w, ]+)$');
  final out = <(int, String)>{};
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final m = re.firstMatch(lines[i]);
    if (m == null) continue;
    for (final code in m[1]!.split(',')) {
      out.add((i + 1, code.trim()));
    }
  }
  return out;
}

void main() {
  group('forbidden_usages.dart', () {
    final content = _fixture('forbidden_usages.dart');
    final found = checkSource(content, path: 'forbidden_usages.dart');
    final expected = _expected(content);

    test('every marked line is reported with its rule', () {
      final actual = {for (final v in found) (v.line, v.rule.code)};
      expect(actual, expected);
      // Ziadne duplicitne hlasenia toho isteho miesta.
      expect(found.length, expected.length);
    });

    test('every rule is covered by the fixture', () {
      final codes = expected.map((e) => e.$2).toSet();
      expect(codes, {for (final r in ProsocheRule.values) r.code});
    });
  });

  test('allowed_usages.dart has no violations', () {
    final found = checkSource(
      _fixture('allowed_usages.dart'),
      path: 'allowed_usages.dart',
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('ignore-file suppresses a rule in the whole file', () {
    const src = '''
// prosoche-lint: ignore-file prosoche_text_align_left_right
const a = TextAlign.left;
const b = TextAlign.right;
const c = Alignment.centerLeft;
''';
    final found = checkSource(src);
    expect(found.map((v) => v.rule), [ProsocheRule.alignmentLeftRight]);
    expect(found.single.line, 4);
    expect(found.single.toString(), contains('prosoche_alignment_left_right'));
  });

  test('isExcludedPath skips generated code and translations', () {
    expect(isExcludedPath('lib/a.g.dart'), isTrue);
    expect(isExcludedPath('lib/a.freezed.dart'), isTrue);
    expect(isExcludedPath('lib/a.pigeon.dart'), isTrue);
    expect(
      isExcludedPath('lib/core/l10n/generated/app_localizations_ar.dart'),
      isTrue,
    );
    expect(isExcludedPath('lib/ui/x.dart'), isFalse);
  });

  group('checkPaths', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('prosoche_lints'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String rel, String content) {
      File(p.join(tmp.path, rel))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('applies exclusions and per-path allowances', () {
      write('lib/a.dart', 'const a = TextDirection.ltr;');
      write(
        'lib/ui/i18n/b.dart',
        "const b = TextDirection.ltr; const c = 'ب';",
      );
      write('lib/ui/i18n/c.dart', 'const d = TextAlign.left;');
      write('lib/d.g.dart', 'const e = TextAlign.left;');
      write('lib/core/l10n/generated/x.dart', "const f = 'ب';");
      write('lib/readme.md', 'TextAlign.left');

      final found = checkPaths([p.join(tmp.path, 'lib')], base: tmp.path);
      expect(
        [for (final v in found) '${v.path} ${v.rule.code}'],
        [
          'lib/a.dart prosoche_hardcoded_text_direction',
          'lib/ui/i18n/c.dart prosoche_text_align_left_right',
        ],
      );
    });

    test('accepts a single file and rejects a missing path', () {
      write('one.dart', 'const a = Alignment.topLeft;');
      expect(
        checkPaths([p.join(tmp.path, 'one.dart')], base: tmp.path),
        hasLength(1),
      );
      expect(
        () => checkPaths([p.join(tmp.path, 'missing')]),
        throwsArgumentError,
      );
    });
  });
}
