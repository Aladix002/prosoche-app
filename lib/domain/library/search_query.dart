/// FTS5 vyraz z textu pouzivatela (kontrakt content.db kap. 7).
///
/// Kazde slovo sa obali do `"..."` (bez operatorov FTS5) a posledne slovo
/// dostane prefix `*`, aby vysledky pribudali uz pocas pisania. Slova sa
/// spajaju implicitnym AND. Prazdny vstup = null (nehladat).
String? ftsQuery(String input, {bool prefixLast = true}) {
  final words = [
    for (final w in input.split(RegExp(r'\s+')))
      if (w.replaceAll('"', '').trim() case final t when t.isNotEmpty) t,
  ];
  if (words.isEmpty) return null;
  final parts = [for (final w in words) '"$w"'];
  if (prefixLast) parts[parts.length - 1] = '${parts.last}*';
  return parts.join(' ');
}

/// Uryvok z FTS5 `snippet(..., '[', ']', ...)` rozdeleny na casti
/// `(text, zvyraznene)`.
List<(String, bool)> snippetParts(String snippet) {
  final out = <(String, bool)>[];
  final re = RegExp(r'\[([^\[\]]*)\]');
  var at = 0;
  for (final m in re.allMatches(snippet)) {
    if (m.start > at) out.add((snippet.substring(at, m.start), false));
    out.add((m[1]!, true));
    at = m.end;
  }
  if (at < snippet.length) out.add((snippet.substring(at), false));
  return out;
}
