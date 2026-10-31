import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/feed/feed_rules.dart';

void main() {
  group('buildShareText (docs/02 B0.7)', () {
    test('text, reference with attribution, source and via', () {
      expect(
        buildShareText(
          const CardShareData(
            text: 'TX',
            reference: 'Work 1.1',
            attribution: 'Author',
            source: 'Source: S',
          ),
          via: 'via Prosoche',
        ),
        'TX\n\n- Work 1.1 (Author)\nSource: S\nvia Prosoche',
      );
    });

    test('without attribution', () {
      expect(
        buildShareText(
          const CardShareData(text: 'TX', reference: 'Ref'),
          via: 'via Prosoche',
        ),
        'TX\n\n- Ref\nvia Prosoche',
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
          IntroContent(
            IntroCardId(LocalDate(2026, 1, 1)),
            date: LocalDate(2026, 1, 1),
          ),
        ),
        0,
      );
      expect(
        translationChars(
          QuoteContent(
            ContentCardId.quote('q'),
            text: 'abcde',
            author: 'A',
            work: 'W',
            sourceId: 's',
          ),
        ),
        5,
      );
    });

    test('quote reference with and without ref', () {
      final q = QuoteContent(
        ContentCardId.quote('q'),
        text: 't',
        author: 'A',
        work: 'W',
        ref: '2.1',
        sourceId: 's',
      );
      expect(q.reference, 'W 2.1');
      expect(
        QuoteContent(
          ContentCardId.quote('q'),
          text: 't',
          author: 'A',
          work: 'W',
          sourceId: 's',
        ).reference,
        'W',
      );
    });
  });
}
