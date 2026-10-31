/// Prevod textovych ID obsahu na cisla, ktore vyzaduje kontrakt `card_id`.
///
/// `content.db` ma `dua.id`, `reflection.id` a `source.id` ako TEXT
/// (napr. `dua.morning.sleep`, `refl.patience.001`, `quranenc_en_saheeh`),
/// ale `DuaCardId`, `ReflectionCardId` (docs/02 0.2) a `translation.{lang}`
/// (docs/02 0.7) su cele cisla. Kym sa kontrakt nezmeni (navrh v handoffe
/// D-02), cislo je stabilny hash textoveho ID: FNV-1a 32 bit zuzeny na
/// 1..999999999 (format `card_id` povoluje max 9 cifier).
///
/// Hash zavisi len od textoveho ID, ktore je kontrakt obsahu, takze ulozene
/// sady a ulozene karty prezijú aktualizaciu content.db. Kolizia je pri
/// stovkach poloziek nepravdepodobna; [CuratedIdIndex] ju odhali a kolidujuce
/// polozky vyradi (radsej nezobrazit nez zobrazit inu kartu).
int curatedNumericId(String textId) {
  var h = 0x811C9DC5;
  for (final unit in textId.codeUnits) {
    h ^= unit & 0xFF;
    h = (h * 0x01000193) & 0xFFFFFFFF;
    h ^= unit >> 8;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h % _maxId + 1;
}

const _maxId = 999999999;

/// Obojsmerna mapa textove ID <-> cislo pre jednu tabulku.
final class CuratedIdIndex {
  CuratedIdIndex(Iterable<String> textIds) {
    final collisions = <int>{};
    for (final id in textIds) {
      final n = curatedNumericId(id);
      final prev = _byNumber[n];
      if (prev != null && prev != id) collisions.add(n);
      _byNumber[n] = id;
    }
    collisions.forEach(_byNumber.remove);
    _collisions = collisions.length;
    for (final MapEntry(:key, :value) in _byNumber.entries) {
      _byText[value] = key;
    }
  }

  final _byNumber = <int, String>{};
  final _byText = <String, int>{};
  late final int _collisions;

  /// Pocet vyradenych cisel (kolizie hashu).
  int get collisions => _collisions;

  String? textId(int number) => _byNumber[number];

  int? number(String textId) => _byText[textId];

  Iterable<String> get textIds => _byText.keys;
}
