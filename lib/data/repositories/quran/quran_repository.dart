import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/daos/quran_dao.dart';
import 'package:prosoche/data/db/user_db.dart' hide CardAction, CardContext;
import 'package:prosoche/data/repositories/infra/card_events.dart';
import 'package:prosoche/data/repositories/infra/curated_id.dart';
import 'package:prosoche/data/repositories/infra/reading_progress.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

export 'package:prosoche/data/db/daos/quran_dao.dart' show JuzStart, SearchHit;

/// Sura v zozname (A5.1).
@immutable
final class SurahInfo {
  const SurahInfo({
    required this.id,
    required this.nameAr,
    required this.nameTranslit,
    required this.revelationPlace,
    required this.ayahCount,
    required this.bismillahPre,
    this.nameMeaning,
    this.bismillahUthmani,
  });

  final int id;

  /// Arabsky nazov (zobrazovat cez `SkArabicText`).
  final String nameAr;
  final String nameTranslit;

  /// Preklad nazvu v jazyku obsahu (`surah_text`), null ak chyba.
  final String? nameMeaning;

  /// `meccan` / `medinan`.
  final String revelationPlace;
  final int ayahCount;

  /// Bismillah nad surou (false pre 1 a 9, D4).
  final bool bismillahPre;
  final String? bismillahUthmani;
}

/// Zdroj prekladu Koranu (A10.5, O1, A11).
@immutable
final class TranslationSource {
  const TranslationSource({
    required this.id,
    required this.lang,
    required this.name,
    required this.version,
    required this.attribution,
    required this.license,
  });

  /// `source.id` v content.db.
  final String id;
  final String lang;
  final String name;
  final String version;
  final String attribution;
  final String license;

  /// Hodnota `settings.translation.{lang}` (cislo, kontrakt 0.7).
  int get settingValue => curatedNumericId(id);
}

/// Preklad versa po fallbacku B0.6.
@immutable
final class TranslationText {
  const TranslationText({
    required this.text,
    required this.sourceId,
    required this.lang,
    this.footnotes,
    this.isFallback = false,
  });

  final String text;
  final String? footnotes;
  final String sourceId;
  final String lang;

  /// Preklad je v `en`, lebo jazyk obsahu ho nema (stitok "EN").
  final bool isFallback;
}

/// Vers na zobrazenie (A5.2, B2). [textUthmani] je bajtovo text z DB.
@immutable
final class AyahView {
  const AyahView({
    required this.id,
    required this.textUthmani,
    required this.juz,
    required this.page,
    this.sajda,
    this.translation,
  });

  final AyahId id;
  final String textUthmani;
  final int juz;
  final int page;

  /// `recommended` / `obligatory` alebo null.
  final String? sajda;

  /// null = bez prekladu (AR, alebo preklad neexistuje ani v `en`).
  final TranslationText? translation;

  int get number => id.ayah;
}

/// Rezim readera (A5.2).
enum ReaderMode { khatm, browse }

/// Vysledok [QuranRepository.markRead].
typedef ReadResult = ({bool newlySeen, bool moved, int? khatmCompleted});

/// Vysledok vyhladavania (A5.4).
@immutable
final class QuranSearchResult {
  QuranSearchResult({
    this.reference,
    List<SurahInfo> surahs = const [],
    List<SearchHit> hits = const [],
  }) : surahs = List.unmodifiable(surahs),
       hits = List.unmodifiable(hits);

  /// Vstup bol referencia `2:255` ("Go to 2:255").
  final AyahId? reference;

  /// Sury podla nazvu (translit, prefix).
  final List<SurahInfo> surahs;

  /// Fulltext, max 50; zhoda je medzi `SearchHit.matchStart`/`matchEnd`.
  final List<SearchHit> hits;

  bool get isEmpty => reference == null && surahs.isEmpty && hits.isEmpty;
}

/// Koran: sury, versy s prekladom, vyhladavanie a pozicia citania (A5).
abstract interface class QuranRepository {
  Future<List<SurahInfo>> surahs(String lang);

  Future<SurahInfo?> surah(int id, String lang);

  /// Prvy vers kazdeho juz (zalozka Juz).
  Future<List<JuzStart>> juzStarts();

  /// Versy sury s prekladom pre [lang] (fallback B0.6, AR bez prekladu).
  Future<List<AyahView>> ayahsOfSurah(int surahId, {required String lang});

  /// Versy podla ID (karty), v poradi ID; chybajuce sa vynechaju.
  Future<List<AyahView>> ayahs(Iterable<AyahId> ids, {required String lang});

  /// Zdroje prekladu pre [lang] (prazdne pre `ar`).
  Future<List<TranslationSource>> translationSources(String lang);

  /// Zvoleny zdroj (`translation.{lang}`), inak prvy pre jazyk.
  Future<TranslationSource?> selectedTranslation(String lang);

  Future<void> selectTranslation(String lang, TranslationSource source);

  /// Referencia, nazov sury alebo fulltext (A5.4); min 2 znaky.
  Future<QuranSearchResult> search(String query, {required String lang});

  /// Posledny precitany vers v khatm poradi; null = pred 1:1.
  Stream<AyahId?> watchReadingPosition();

  /// Precitane versy podla sury (`surah` -> pocet), progres sur.
  Stream<Map<int, int>> watchReadCounts();

  /// Pocet dokoncenych khatmov (`khatm_log`).
  Future<int> completedKhatms();

  /// Vers [ayah] bol precitany v readeri (>= 60 % viditelny 2,5 s):
  /// `card_event{seen, context=reader}` pre [date] (localDate), v
  /// [ReaderMode.khatm] posun `reading_position` o presne jeden vers a po
  /// 114:6 zapis khatmu; v [ReaderMode.browse] `reader.last_ayah_id`.
  Future<ReadResult> markRead(
    AyahId ayah, {
    required ReaderMode mode,
    required LocalDate date,
  });
}

class DriftQuranRepository implements QuranRepository {
  DriftQuranRepository({
    required this._content,
    required this._userDb,
    required this._settings,
    required this._clock,
  });

  final Future<ContentDb> _content;
  final UserDb _userDb;
  final SettingsRepository _settings;
  final Clock _clock;

  static final _reference = RegExp(r'^(\d{1,3})[:\s.](\d{1,3})$');
  static final _arabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');

  Future<QuranDao> get _quran async => (await _content).quranDao;

  @override
  Future<List<SurahInfo>> surahs(String lang) async {
    final dao = await _quran;
    final meanings = await dao.surahNameMeanings(lang);
    return [for (final r in await dao.allSurahs()) _surah(r, meanings[r.id])];
  }

  @override
  Future<SurahInfo?> surah(int id, String lang) async {
    final dao = await _quran;
    final row = await dao.surah(id);
    if (row == null) return null;
    return _surah(row, (await dao.surahNameMeanings(lang))[id]);
  }

  static SurahInfo _surah(SurahRow r, String? meaning) => SurahInfo(
    id: r.id,
    nameAr: r.nameAr,
    nameTranslit: r.nameTranslit,
    nameMeaning: meaning,
    revelationPlace: r.revelationPlace,
    ayahCount: r.ayahCount,
    bismillahPre: r.bismillahPre,
    bismillahUthmani: r.bismillahUthmani,
  );

  @override
  Future<List<JuzStart>> juzStarts() async => await (await _quran).juzStarts();

  @override
  Future<List<AyahView>> ayahsOfSurah(
    int surahId, {
    required String lang,
  }) async => await _views(await (await _quran).ayahsOfSurah(surahId), lang);

  @override
  Future<List<AyahView>> ayahs(
    Iterable<AyahId> ids, {
    required String lang,
  }) async => await _views(
    await (await _quran).ayahsByIds([for (final id in ids) id.value]),
    lang,
  );

  Future<List<AyahView>> _views(List<AyahRow> rows, String lang) async {
    final translations = await _translations([
      for (final r in rows) r.id,
    ], lang);
    return [
      for (final r in rows)
        if (AyahId.tryFromValue(r.id) case final id?)
          AyahView(
            id: id,
            textUthmani: r.textUthmani,
            juz: r.juz,
            page: r.page,
            sajda: r.sajda,
            translation: translations[r.id],
          ),
    ];
  }

  /// Fallback B0.6: zvoleny zdroj -> iny zdroj v jazyku -> `en` -> nic.
  Future<Map<int, TranslationText>> _translations(
    List<int> ids,
    String lang,
  ) async {
    final out = <int, TranslationText>{};
    if (ids.isEmpty || lang == 'ar') return out;
    final dao = await _quran;
    Future<void> fill(String l, {required bool fallback}) async {
      for (final source in await _orderedSources(l)) {
        final missing = [
          for (final id in ids)
            if (!out.containsKey(id)) id,
        ];
        if (missing.isEmpty) return;
        final rows = await dao.translationsFor(
          missing,
          lang: l,
          sourceId: source.id,
        );
        for (final MapEntry(:key, :value) in rows.entries) {
          out[key] = TranslationText(
            text: value.textContent,
            footnotes: value.footnotes,
            sourceId: value.sourceId,
            lang: l,
            isFallback: fallback,
          );
        }
      }
    }

    await fill(lang, fallback: false);
    if (lang != 'en' && out.length < ids.length) {
      await fill('en', fallback: true);
    }
    return out;
  }

  /// Zdroje jazyka, zvoleny prvy.
  Future<List<TranslationSource>> _orderedSources(String lang) async {
    final all = await translationSources(lang);
    final selected = await _settings.get(SettingsKeys.translation(lang));
    return [
      ...all.where((s) => s.settingValue == selected),
      ...all.where((s) => s.settingValue != selected),
    ];
  }

  @override
  Future<List<TranslationSource>> translationSources(String lang) async {
    if (lang == 'ar') return const [];
    final rows = await (await _content).contentMetaDao.translationSources(lang);
    return [
      for (final r in rows)
        TranslationSource(
          id: r.id,
          lang: lang,
          name: r.name,
          version: r.version,
          attribution: r.attribution,
          license: r.license,
        ),
    ];
  }

  @override
  Future<TranslationSource?> selectedTranslation(String lang) async =>
      (await _orderedSources(lang)).firstOrNull;

  @override
  Future<void> selectTranslation(String lang, TranslationSource source) =>
      _settings.set(SettingsKeys.translation(lang), source.settingValue);

  @override
  Future<QuranSearchResult> search(String query, {required String lang}) async {
    final q = query.trim();
    if (q.length < 2) return QuranSearchResult();
    final ref = _reference.firstMatch(q);
    if (ref != null) {
      final id = AyahId.isValid(int.parse(ref[1]!), int.parse(ref[2]!))
          ? AyahId(int.parse(ref[1]!), int.parse(ref[2]!))
          : null;
      return QuranSearchResult(reference: id);
    }
    final dao = await _quran;
    if (_arabic.hasMatch(q)) {
      return QuranSearchResult(hits: await dao.searchArabic(q));
    }
    final source = await selectedTranslation(lang);
    final hits = source == null
        ? const <SearchHit>[]
        : await dao.searchTranslation(q, lang: lang, sourceId: source.id);
    final needle = _normalize(q);
    final surahs = needle.isEmpty
        ? const <SurahInfo>[]
        : [
            for (final s in await this.surahs(lang))
              if (_nameMatches(s.nameTranslit, needle)) s,
          ];
    return QuranSearchResult(surahs: surahs, hits: hits);
  }

  static bool _nameMatches(String translit, String needle) {
    final name = _normalize(translit);
    if (name.startsWith(needle)) return true;
    // "Al-Baqarah" sa najde aj ako "baqarah".
    for (final prefix in const ['al', 'an', 'ar', 'as', 'at', 'ad', 'az']) {
      if (name.startsWith(prefix) && name.substring(2).startsWith(needle)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  @override
  Stream<AyahId?> watchReadingPosition() =>
      _userDb.readingDao.watchReadingPosition().map(readingPositionOf);

  @override
  Stream<Map<int, int>> watchReadCounts() =>
      _userDb.readingDao.watchReadCountsBySurah();

  @override
  Future<int> completedKhatms() => _userDb.readingDao.completedKhatmCount();

  @override
  Future<ReadResult> markRead(
    AyahId ayah, {
    required ReaderMode mode,
    required LocalDate date,
  }) async {
    final now = _clock.now();
    final newly = await logCardEvent(
      _userDb,
      date: date,
      card: AyahCardId(ayah),
      action: CardAction.seen,
      context: CardContext.reader,
      now: now,
    );
    switch (mode) {
      case ReaderMode.khatm:
        final advance = await advanceReadingPosition(
          _userDb,
          ayah,
          now,
          strict: true,
        );
        return (
          newlySeen: newly,
          moved: advance.moved,
          khatmCompleted: advance.khatmCompleted,
        );
      case ReaderMode.browse:
        await _settings.set(SettingsKeys.readerLastAyahId, ayah.value);
        return (newlySeen: newly, moved: false, khatmCompleted: null);
    }
  }
}
