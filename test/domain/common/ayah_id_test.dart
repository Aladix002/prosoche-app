import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/ayah_id.dart';

void main() {
  test('value is surah * 1000 + ayah', () {
    final id = AyahId(2, 255);
    expect(id.value, 2255);
    expect((id.surah, id.ayah), (2, 255));
    expect(id.toString(), '2:255');
    expect(AyahId.fromValue(2255), id);
    expect(AyahId.fromValue(2255).hashCode, id.hashCode);
  });

  test('ayah counts sum to 6236 over 114 surahs', () {
    var total = 0;
    for (var s = 1; s <= AyahId.surahCount; s++) {
      total += AyahId.ayahCount(s);
    }
    expect(total, AyahId.totalAyahs);
    expect(AyahId.ayahCount(1), 7);
    expect(AyahId.ayahCount(2), 286);
    expect(AyahId.ayahCount(18), 110);
    expect(AyahId.ayahCount(114), 6);
  });

  test('validates range', () {
    expect(() => AyahId(0, 1), throwsRangeError);
    expect(() => AyahId(115, 1), throwsRangeError);
    expect(() => AyahId(1, 0), throwsRangeError);
    expect(() => AyahId(1, 8), throwsRangeError);
    expect(() => AyahId.fromValue(2287), throwsRangeError);
    expect(AyahId.tryFromValue(2287), isNull);
    expect(AyahId.tryFromValue(0), isNull);
    expect(AyahId.tryFromValue(114006), AyahId.last);
    expect(AyahId.isValid(18, 110), isTrue);
    expect(AyahId.isValid(18, 111), isFalse);
  });

  test('next walks the reading order and wraps after 114:6', () {
    expect(AyahId(1, 1).next, AyahId(1, 2));
    expect(AyahId(1, 7).next, AyahId(2, 1));
    expect(AyahId(18, 110).next, AyahId(19, 1));
    expect(AyahId.last.next, AyahId.first);

    var id = AyahId.first;
    var steps = 0;
    do {
      id = id.next;
      steps++;
    } while (id != AyahId.first);
    expect(steps, AyahId.totalAyahs);
  });

  test('compareTo orders by value', () {
    final list = [AyahId(3, 1), AyahId(1, 7), AyahId(2, 255)]..sort();
    expect(list.map((a) => a.value), [1007, 2255, 3001]);
  });
}
