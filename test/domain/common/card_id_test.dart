import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';

void main() {
  final date = LocalDate(2026, 10, 29);

  final examples = <String, (CardId, CardType)>{
    'intro:2026-10-29': (IntroCardId(date), CardType.intro),
    'quote:q_0001': (ContentCardId.quote('q_0001'), CardType.quote),
    'passage:ench_1': (
      ContentCardId(CardType.passage, 'ench_1'),
      CardType.passage,
    ),
    'practice:morning': (
      ContentCardId(CardType.practice, 'morning'),
      CardType.practice,
    ),
    'prompt:p1': (ContentCardId(CardType.prompt, 'p1'), CardType.prompt),
    'concept:logos': (
      ContentCardId(CardType.concept, 'logos'),
      CardType.concept,
    ),
    'author:marcus': (
      ContentCardId(CardType.author, 'marcus'),
      CardType.author,
    ),
    'done:2026-10-29': (DoneCardId(date), CardType.done),
  };

  test('examples cover every CardType', () {
    expect(examples.values.map((e) => e.$2).toSet(), CardType.values.toSet());
  });

  for (final MapEntry(key: text, value: (id, type)) in examples.entries) {
    test('$text parse, format, round trip', () {
      final parsed = CardId.parse(text);
      expect(parsed, id);
      expect(parsed.type, type);
      expect(parsed.runtimeType, id.runtimeType);
      expect(parsed.hashCode, id.hashCode);
      expect(id.format(), text);
      expect(id.toString(), text);
      expect(CardId.parse(parsed.format()).format(), text);
    });
  }

  test('fields are exposed for exhaustive switch', () {
    String describe(CardId id) => switch (id) {
      IntroCardId(:final date) => 'intro $date',
      DoneCardId(:final date) => 'done $date',
      ContentCardId(:final type, :final key) => '${type.wire} $key',
    };
    expect(describe(IntroCardId(date)), 'intro 2026-10-29');
    expect(describe(DoneCardId(date)), 'done 2026-10-29');
    expect(describe(ContentCardId.quote('a')), 'quote a');
  });

  test('content types and save/share flags', () {
    expect(CardType.intro.isContent, isFalse);
    expect(CardType.done.isContent, isFalse);
    for (final t in CardType.values.where((t) => t.isContent)) {
      expect(t.canSave, isTrue, reason: t.wire);
      expect(t.canShare, isTrue, reason: t.wire);
      expect(CardType.fromWire(t.wire), t);
    }
    expect(CardType.fromWire('ayah'), isNull);
  });

  for (final bad in [
    '',
    'quote',
    'quote:',
    'quote:Bad-Key',
    'unknown:1',
    'intro:2026-13-01',
    'done:x',
    'quote:${'a' * 65}',
  ]) {
    test('rejects "$bad"', () {
      expect(() => CardId.parse(bad), throwsFormatException);
      expect(CardId.tryParse(bad), isNull);
    });
  }

  test('constructor validates type and key', () {
    expect(() => ContentCardId(CardType.intro, 'x'), throwsArgumentError);
    expect(() => ContentCardId.quote('A'), throwsArgumentError);
  });

  test('slot maps to card type', () {
    for (final s in Slot.values) {
      expect(s.cardType.wire, s.wire);
      expect(Slot.fromWire(s.wire), s);
    }
    expect(Slot.fromWire('ayah'), isNull);
    for (final s in QuestSlot.values) {
      expect(QuestSlot.fromWire(s.wire), s);
    }
    expect(QuestSlot.fromWire('x'), isNull);
  });
}
