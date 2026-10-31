import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/quran/quran_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../../db/fixtures/content_fixture.dart';
import '../harness.dart';

void main() {
  late Harness h;
  final today = LocalDate(2026, 10, 29);

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  test('surahs with meaning and juz starts', () async {
    final surahs = await h.quran.surahs('en');
    expect(surahs.map((s) => s.id), [1, 2]);
    expect(surahs.first.nameMeaning, '[PLACEHOLDER meaning 1]');
    expect(surahs.first.bismillahPre, isFalse);
    expect((await h.quran.surahs('id')).first.nameMeaning, isNull);
    expect((await h.quran.surah(2, 'en'))!.ayahCount, 286);
    expect(await h.quran.surah(9, 'en'), isNull);
    expect((await h.quran.juzStarts()).first.firstAyahId, 1001);
  });

  test('ayah text is byte-identical to text_uthmani', () async {
    final ayahs = await h.quran.ayahsOfSurah(2, lang: 'en');
    expect(ayahs, hasLength(286));
    expect(ayahs[254].textUthmani, uthmaniOf(2, 255));
    expect(ayahs[254].number, 255);
    expect(ayahs[254].translation!.text, contains(fixtureTranslationToken));
    expect(ayahs[254].translation!.isFallback, isFalse);
  });

  test('translation fallback B0.6: other source, en, none for ar', () async {
    // fx-en-b nema texty: zvoleny zdroj bez prekladu -> iny zdroj v en.
    final en = await h.quran.translationSources('en');
    expect(en.map((s) => s.id), ['fx-en-a', 'fx-en-b']);
    await h.quran.selectTranslation('en', en[1]);
    expect((await h.quran.selectedTranslation('en'))!.id, 'fx-en-b');
    expect(
      await h.settings.get(SettingsKeys.translation('en')),
      en[1].settingValue,
    );
    final viaOther = await h.quran.ayahs([AyahId(1, 1)], lang: 'en');
    expect(viaOther.single.translation!.sourceId, 'fx-en-a');

    final id1 = await h.quran.ayahs([AyahId(1, 2)], lang: 'id');
    expect(id1.single.translation!.lang, 'id');
    final id2 = await h.quran.ayahs([AyahId(2, 2)], lang: 'id');
    expect(id2.single.translation!.lang, 'en');
    expect(id2.single.translation!.isFallback, isTrue);

    final ar = await h.quran.ayahs([AyahId(1, 1)], lang: 'ar');
    expect(ar.single.translation, isNull);
    expect(await h.quran.translationSources('ar'), isEmpty);
    expect(await h.quran.ayahs(const [], lang: 'en'), isEmpty);
  });

  test('search: reference, arabic, translation and surah name', () async {
    var r = await h.quran.search('2:255', lang: 'en');
    expect(r.reference, AyahId(2, 255));
    r = await h.quran.search('2:999', lang: 'en');
    expect(r.reference, isNull);
    expect(r.isEmpty, isTrue);
    expect((await h.quran.search('a', lang: 'en')).isEmpty, isTrue);

    r = await h.quran.search(fixtureTranslationToken, lang: 'en');
    expect(r.hits.single.ayahId, 2255);
    expect(r.hits.single.snippet, contains(SearchHit.matchStart));

    r = await h.quran.search('placeholder 2', lang: 'en');
    expect(r.surahs.map((s) => s.id), [2]);

    r = await h.quran.search('ال', lang: 'en');
    expect(r.hits, isEmpty);
  });

  test('reader khatm mode moves position by exactly one verse', () async {
    final positions = h.quran.watchReadingPosition();
    expect(await positions.first, isNull);
    var r = await h.quran.markRead(
      AyahId(1, 1),
      mode: ReaderMode.khatm,
      date: today,
    );
    expect(r.newlySeen, isTrue);
    expect(r.moved, isTrue);
    r = await h.quran.markRead(
      AyahId(1, 3),
      mode: ReaderMode.khatm,
      date: today,
    );
    expect(r.moved, isFalse, reason: 'skipping does not move');
    r = await h.quran.markRead(
      AyahId(1, 1),
      mode: ReaderMode.khatm,
      date: today,
    );
    expect(r.newlySeen, isFalse);
    expect(await h.quran.watchReadingPosition().first, AyahId(1, 1));
    expect(await h.quran.watchReadCounts().first, {1: 2});
  });

  test('reading 114:6 completes a khatm', () async {
    await h.user.readingDao.setReadingPosition(114005, DateTime.utc(2026));
    final r = await h.quran.markRead(
      AyahId.last,
      mode: ReaderMode.khatm,
      date: today,
    );
    expect(r.khatmCompleted, 1);
    expect(await h.quran.completedKhatms(), 1);
    expect(await h.quran.watchReadingPosition().first, isNull);
  });

  test('browse mode stores last opened verse only', () async {
    final r = await h.quran.markRead(
      AyahId(2, 12),
      mode: ReaderMode.browse,
      date: today,
    );
    expect(r.moved, isFalse);
    expect(await h.settings.get(SettingsKeys.readerLastAyahId), 2012);
    expect(await h.user.readingDao.readingPosition(), 0);
  });
}
