import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';

void main() {
  final date = LocalDate(2026, 10, 29);

  // Vsetky typy z docs/02 0.2 s prikladmi z tabulky.
  final examples = <String, (CardId, CardType)>{
    'intro:2026-10-29': (IntroCardId(date), CardType.intro),
    'ayah:2255': (AyahCardId(AyahId(2, 255)), CardType.ayah),
    'word:1043': (WordCardId(1043), CardType.word),
    'quiz:1043:ar2mean': (QuizCardId(1043, 'ar2mean'), CardType.quiz),
    'hadith:13': (HadithCardId(13), CardType.hadith),
    'dua:77': (DuaCardId(77), CardType.dua),
    'name:7': (NameCardId(7), CardType.name),
    'reflection:31': (ReflectionCardId(31), CardType.reflection),
    'event:jumuah:2026-10-30': (
      EventCardId('jumuah', LocalDate(2026, 10, 30)),
      CardType.event,
    ),
    'done:2026-10-29': (DoneCardId(date), CardType.done),
    'khatm:1': (KhatmCardId(1), CardType.khatm),
  };

  test('examples cover every CardType', () {
    expect(examples.values.map((e) => e.$2).toSet(), CardType.values.toSet());
  });

  for (final MapEntry(key: text, value: (id, type)) in examples.entries) {
    group(text, () {
      test('parse', () {
        final parsed = CardId.parse(text);
        expect(parsed, id);
        expect(parsed.type, type);
        expect(parsed.runtimeType, id.runtimeType);
        expect(parsed.hashCode, id.hashCode);
      });

      test('format', () {
        expect(id.format(), text);
        expect(id.toString(), text);
        expect(text.startsWith('${type.wire}:'), isTrue);
      });

      test('round trip', () {
        expect(CardId.parse(CardId.parse(text).format()).format(), text);
      });
    });
  }

  test('fields are exposed for exhaustive switch', () {
    String describe(CardId id) => switch (id) {
      IntroCardId(:final date) => 'intro $date',
      AyahCardId(:final ayahId) => 'ayah ${ayahId.surah}:${ayahId.ayah}',
      WordCardId(:final lemmaId) => 'word $lemmaId',
      QuizCardId(:final lemmaId, :final qtype) => 'quiz $lemmaId $qtype',
      HadithCardId(:final hadithId) => 'hadith $hadithId',
      DuaCardId(:final duaId) => 'dua $duaId',
      NameCardId(:final nameId) => 'name $nameId',
      ReflectionCardId(:final reflectionId) => 'reflection $reflectionId',
      EventCardId(:final eventId, :final date) => 'event $eventId $date',
      DoneCardId(:final date) => 'done $date',
      KhatmCardId(:final n) => 'khatm $n',
    };
    expect(examples.keys.map((k) => describe(CardId.parse(k))), [
      'intro 2026-10-29',
      'ayah 2:255',
      'word 1043',
      'quiz 1043 ar2mean',
      'hadith 13',
      'dua 77',
      'name 7',
      'reflection 31',
      'event jumuah 2026-10-30',
      'done 2026-10-29',
      'khatm 1',
    ]);
  });

  test('save and share rules follow docs/02 0.2', () {
    expect(CardType.values.where((t) => t.canSave).map((t) => t.wire), [
      'ayah',
      'hadith',
      'dua',
      'name',
      'reflection',
    ]);
    expect(CardType.values.where((t) => t.canShare).map((t) => t.wire), [
      'ayah',
      'word',
      'hadith',
      'dua',
      'name',
      'reflection',
    ]);
  });

  test('CardType.fromWire', () {
    for (final t in CardType.values) {
      expect(CardType.fromWire(t.wire), t);
    }
    expect(CardType.fromWire('nope'), isNull);
  });

  group('rejects invalid', () {
    for (final text in [
      '',
      'ayah',
      'ayah:',
      'ayah:0',
      'ayah:2287',
      'ayah:115001',
      'ayah:-5',
      'ayah:2255:1',
      'ayah:02255',
      'word:abc',
      'word:0',
      'quiz:1043',
      'quiz:1043:',
      'quiz:1043:Ar2Mean',
      'quiz:x:ar2mean',
      'name:100',
      'name:0',
      'intro:2026-02-30',
      'intro:26-10-29',
      'done:',
      'event:jumuah',
      'event:Jumuah:2026-10-30',
      'event:jumuah:2026-13-01',
      'khatm:0',
      'unknown:1',
      'AYAH:2255',
    ]) {
      test('"$text"', () {
        expect(() => CardId.parse(text), throwsFormatException);
        expect(CardId.tryParse(text), isNull);
      });
    }
  });

  group('constructors validate', () {
    test('ids must be positive', () {
      expect(() => WordCardId(0), throwsRangeError);
      expect(() => QuizCardId(0, 'x'), throwsRangeError);
      expect(() => HadithCardId(0), throwsRangeError);
      expect(() => DuaCardId(-1), throwsRangeError);
      expect(() => ReflectionCardId(0), throwsRangeError);
      expect(() => KhatmCardId(0), throwsRangeError);
      expect(() => NameCardId(100), throwsRangeError);
    });

    test('text keys must be [a-z0-9_]', () {
      expect(() => QuizCardId(1, 'a:b'), throwsArgumentError);
      expect(
        () => EventCardId('a b', LocalDate(2026, 1, 1)),
        throwsArgumentError,
      );
    });
  });

  test('equality is by formatted value', () {
    expect(CardId.parse('dua:77'), DuaCardId(77));
    expect(CardId.parse('dua:77') == HadithCardId(77), isFalse);
    expect({CardId.parse('name:7'), NameCardId(7)}, hasLength(1));
  });
}
