/// Ranna priprava alebo vecerna reflexia (Practice).
enum RoutineKind {
  morning('morning'),
  evening('evening');

  RoutineKind(this.tag);

  /// Tag kariet v content.db (`card.tags`).
  final String tag;
}

/// Otazky z textu cvicenia: vety, ktore koncia `?` (napr. vecerna
/// reflexia: "What did I do well?"). Text sa nemeni, len sa rozdeli.
List<String> questionsIn(String text) {
  final out = <String>[];
  for (final m in RegExp(r'[^.?!:\n]*\?').allMatches(text)) {
    final q = m[0]!.trim();
    if (q.length > 1) out.add(q);
  }
  return out;
}

/// Deterministicky vyber [count] otazok dna z [ids] (rotacia podla dna,
/// rovnaky den = rovnake otazky). [dayIndex] je pocet dni od epochy.
List<T> rotate<T>(List<T> ids, int dayIndex, int count) {
  if (ids.isEmpty || count <= 0) return const [];
  final n = count > ids.length ? ids.length : count;
  final start = (dayIndex * n) % ids.length;
  return [for (var i = 0; i < n; i++) ids[(start + i) % ids.length]];
}
