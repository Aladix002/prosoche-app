import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/cards.dart';
import 'package:sakina/features/feed/feed_rules.dart';

void main() {
  group('buildShareText (docs/02 B0.7)', () {
    test('arabic, translation, reference with attribution and via', () {
      expect(
        buildShareText(
          const CardShareData(
            arabic: 'AR',
            translation: 'TR',
            reference: 'Ref 1:1',
            attribution: 'Translation: X',
          ),
          via: 'via Mursa',
        ),
        'AR\n\nTR\n\n- Ref 1:1 (Translation: X)\nvia Mursa',
      );
    });

    test('without arabic and attribution', () {
      expect(
        buildShareText(
          const CardShareData(translation: 'TR', reference: 'Ref'),
          via: 'via Mursa',
        ),
        'TR\n\n- Ref\nvia Mursa',
      );
    });
  });

  group('FeedRules', () {
    const base = Duration(milliseconds: 2500);

    test('short text keeps the base dwell', () {
      expect(FeedRules.dwellForOverflow(base, 10), base);
    });

    test('long text: 40 ms per char, at most 15 s (B0.5)', () {
      expect(FeedRules.dwellForOverflow(base, 100), const Duration(seconds: 4));
      expect(FeedRules.dwellForOverflow(base, 5000), FeedRules.maxDwell);
    });

    test('translationChars counts what the user reads', () {
      expect(translationChars(null), 0);
      expect(
        translationChars(
          ReflectionContent(
            ReflectionCardId(1),
            lang: 'en',
            text: 'abc',
            question: 'de',
          ),
        ),
        5,
      );
      expect(
        translationChars(
          NameContent(
            NameCardId(1),
            textAr: 'x',
            meaning: 'ab',
            shortNote: 'c',
          ),
        ),
        3,
      );
      expect(
        translationChars(
          DuaContent(
            DuaCardId(1),
            textAr: 'x',
            sourceRef: 'r',
            repeatCount: 1,
            text: 'abcd',
          ),
        ),
        4,
      );
      expect(
        translationChars(
          HadithContent(
            HadithCardId(1),
            textAr: 'x',
            grade: 'sahih',
            collection: 'c',
            sourceId: 's',
          ),
        ),
        0,
      );
    });

    test('nextReadingAyah continues after the position, wraps after 114:6', () {
      expect(nextReadingAyah(null), AyahId.first);
      expect(nextReadingAyah(AyahId(2, 5)), AyahId(2, 6));
      expect(nextReadingAyah(AyahId.last), AyahId.first);
    });
  });
}
