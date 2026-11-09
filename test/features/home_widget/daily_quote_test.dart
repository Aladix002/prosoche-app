import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/home_widget/daily_quote.dart';

void main() {
  final pool = [for (var i = 0; i < 30; i++) 'quote:q.$i'];
  final day = LocalDate(2026, 11, 9);

  group('widgetQuotePool', () {
    test('keeps short quotes only, sorted by id, without disabled', () {
      final ids = widgetQuotePool(
        [
          (id: 'quote:b', text: 'Short.'),
          (id: 'quote:a', text: 'Also short.'),
          (id: 'quote:long', text: 'x' * (widgetQuoteMaxChars + 1)),
          (id: 'quote:edge', text: 'y' * widgetQuoteMaxChars),
          (id: 'passage:p', text: 'Not a quote card.'),
          (id: 'quote:empty', text: '   '),
          (id: 'quote:off', text: 'Disabled.'),
        ],
        disabled: {'quote:off'},
      );
      expect(ids, ['quote:a', 'quote:b', 'quote:edge']);
    });

    test('order of input rows does not matter', () {
      final rows = [for (final id in pool) (id: id, text: 'Text $id.')];
      expect(widgetQuotePool(rows.reversed), widgetQuotePool(rows));
    });
  });

  group('dailyQuoteId', () {
    test('is stable for the same date (all widgets, whole day)', () {
      final first = dailyQuoteId(day, pool);
      for (var i = 0; i < 5; i++) {
        expect(dailyQuoteId(LocalDate(2026, 11, 9), pool), first);
      }
    });

    test('pins the algorithm (changing it changes the quote of the day)', () {
      expect(dailyQuoteIndex(day, 30), dailyQuoteIndex(day, 30));
      final snapshot = [
        for (var i = 0; i < 5; i++) dailyQuoteIndex(day.addDays(i), 30),
      ];
      expect(snapshot.toSet(), hasLength(5));
      expect(snapshot.every((i) => i >= 0 && i < 30), isTrue);
    });

    test('changes after midnight', () {
      final a = dailyQuoteId(day, pool);
      final b = dailyQuoteId(day.addDays(1), pool);
      expect(a, isNot(b));
    });

    test('no repeat until the whole pool is shown (one cycle)', () {
      // Zaciatok cyklu: epochDay delitelny velkostou poolu.
      final epoch = LocalDate(1970, 1, 1);
      final offset = day.daysSince(epoch) % pool.length;
      final start = day.addDays(-offset);
      final seen = {
        for (var i = 0; i < pool.length; i++)
          dailyQuoteId(start.addDays(i), pool),
      };
      expect(seen, hasLength(pool.length));
    });

    test('empty pool has no quote; single quote is always shown', () {
      expect(dailyQuoteId(day, const []), isNull);
      expect(dailyQuoteId(day, const ['quote:x']), 'quote:x');
      expect(() => dailyQuoteIndex(day, 0), throwsRangeError);
    });
  });
}
