/// Referencia na zobrazenie: `"{short_ref} {ref}"`, napr.
/// "Meditations 2.1", "Enchiridion 5" (kontrakt content.db kap. 3).
String displayReference(String shortRef, String? locus) =>
    locus == null || locus.isEmpty ? shortRef : '$shortRef $locus';

/// Pozicia citania ako podiel 0..1 z poradia sekcie v diele.
///
/// [index] je poradie sekcie (0 = prva), [count] pocet sekcii diela,
/// [offset] posun v ramci sekcie (0..1).
double readingProgress(int index, int count, {double offset = 0}) {
  if (count <= 0 || index < 0) return 0;
  final o = offset.isNaN ? 0.0 : offset.clamp(0.0, 1.0);
  final v = (index + o) / count;
  return v.clamp(0.0, 1.0);
}

/// Index sekcie [key] v [keys]; neznamy kluc (sekcia zanikla) = 0.
int sectionIndex(List<String> keys, String? key) {
  if (key == null) return 0;
  final i = keys.indexOf(key);
  return i < 0 ? 0 : i;
}
