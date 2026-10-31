import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/library/library.dart';

void main() {
  group('ftsQuery', () {
    test('quotes every word, prefix on the last one', () {
      expect(ftsQuery('  mind   power '), '"mind" "power"*');
      expect(ftsQuery('anger', prefixLast: false), '"anger"');
    });

    test('drops FTS5 syntax and empty input', () {
      expect(ftsQuery('"a" OR b'), '"a" "OR" "b"*');
      expect(ftsQuery('""'), isNull);
      expect(ftsQuery('   '), isNull);
    });
  });

  test('snippetParts splits highlighted words', () {
    expect(snippetParts('...the [mind] is [free]...'), [
      ('...the ', false),
      ('mind', true),
      (' is ', false),
      ('free', true),
      ('...', false),
    ]);
    expect(snippetParts('plain'), [('plain', false)]);
    expect(snippetParts('[x]'), [('x', true)]);
  });

  test('displayReference', () {
    expect(displayReference('Meditations', '2.1'), 'Meditations 2.1');
    expect(displayReference('Enchiridion', null), 'Enchiridion');
    expect(displayReference('Enchiridion', ''), 'Enchiridion');
  });

  test('readingProgress and sectionIndex', () {
    expect(readingProgress(0, 4), 0);
    expect(readingProgress(1, 4, offset: 0.5), 0.375);
    expect(readingProgress(9, 4), 1);
    expect(readingProgress(1, 0), 0);
    expect(readingProgress(-1, 3), 0);
    expect(readingProgress(1, 4, offset: double.nan), 0.25);
    expect(sectionIndex(['a', 'b'], 'b'), 1);
    expect(sectionIndex(['a', 'b'], 'gone'), 0);
    expect(sectionIndex(['a'], null), 0);
  });
}
