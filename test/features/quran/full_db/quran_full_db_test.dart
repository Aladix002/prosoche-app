import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sqlite3/sqlite3.dart';

import '../full_db.dart';

/// F-04 DoD nad plnou content.db: zobrazovany text versa je bajtovo
/// `ayah.text_uthmani` a vyhladavanie trva < 100 ms. Bez db sa preskoci.
void main() {
  final path = fullContentDbPath();

  group('full content.db', skip: fullDbSkip, () {
    late ({DriftQuranRepository repo, dynamic content, dynamic user}) q;
    late Database raw;

    setUpAll(() {
      q = openFullQuran(path!);
      raw = sqlite3.open(path, mode: OpenMode.readOnly);
    });

    tearDownAll(() async {
      raw.close();
    });

    test('repository returns text_uthmani byte for byte', () async {
      for (final lang in ['en', 'ar', 'ur', 'bn']) {
        for (final surah in [1, 2, 9, 18, 112, 113, 114]) {
          final views = await q.repo.ayahsOfSurah(surah, lang: lang);
          final rows = raw.select(
            'SELECT number, text_uthmani FROM ayah WHERE surah_id = ? '
            'ORDER BY number',
            [surah],
          );
          expect(views.length, rows.length);
          for (final (i, r) in rows.indexed) {
            expect(views[i].number, r['number']);
            expect(
              views[i].textUthmani.codeUnits,
              (r['text_uthmani'] as String).codeUnits,
            );
          }
        }
      }
    });

    test('search answers in < 100 ms', () async {
      await q.repo.search('mercy', lang: 'en'); // zahriatie spojenia
      // Arabsky dotaz z db (prve slovo 1:1 v text_simple), nie literal.
      final arabicQuery =
          (raw
                      .select('SELECT text_simple FROM ayah WHERE id = 1001')
                      .first['text_simple']
                  as String)
              .split(' ')
              .first;
      for (final (query, lang) in [
        ('2:255', 'en'),
        ('mercy', 'en'),
        ('baqara', 'en'),
        ('the most merciful', 'en'),
        ('rahmat', 'id'),
        (arabicQuery, 'ar'),
      ]) {
        final sw = Stopwatch()..start();
        final r = await q.repo.search(query, lang: lang);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(100), reason: query);
        expect(r.isEmpty, isFalse, reason: query);
      }
    });

    test('reference search goes to Al-Baqarah 2:255', () async {
      final r = await q.repo.search('2:255', lang: 'en');
      expect(r.reference?.value, 2255);
    });
  });
}
