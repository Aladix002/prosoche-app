import 'package:meta/meta.dart';
import 'package:sakina/data/repositories/calendar/calendar_repository.dart';
import 'package:sakina/data/repositories/catalog/content_catalog.dart';
import 'package:sakina/data/repositories/quran/quran_repository.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/common.dart';

/// Obsah karty na vykreslenie (docs/02 B1-B12). Texty su doslovne z
/// content.db. Nabozensky text (hadis, dua, meno, zamyslenie) sa na `en`
/// nefallbackuje (docs/03 7.3, BF-01): bez prekladu v jazyku obsahu ostane
/// arabsky original a karta ukaze poznamku; v `ar` je original sam textom
/// (`arabicOnly`). EN fallback so stitkom ostava len pri preklade versa
/// (docs/02 B0.6, B2 AC).
@immutable
sealed class CardContent {
  const CardContent(this.id);

  final CardId id;
}

/// B1 uvodna karta.
final class IntroContent extends CardContent {
  const IntroContent(
    IntroCardId super.id, {
    required this.date,
    required this.hijri,
    this.event,
    this.moreEvents = 0,
  });

  final LocalDate date;
  final HijriDate hijri;

  /// Text eventu s najvyssou prioritou v jazyku obsahu; null = len datum.
  final EventText? event;

  /// Dalsie aktivne eventy ("+1 more").
  final int moreEvents;
}

/// B2 / B11 vers.
final class AyahContent extends CardContent {
  const AyahContent(
    AyahCardId super.id, {
    required this.ayah,
    required this.surah,
    this.arabicOnly = false,
  });

  final AyahView ayah;
  final SurahInfo surah;

  /// Jazyk obsahu je `ar`: preklad sa nezobrazuje ani nehlasi ako chybajuci.
  final bool arabicOnly;
}

/// B5 hadis (HadeethEnc).
final class HadithContent extends CardContent {
  const HadithContent(
    HadithCardId super.id, {
    required this.textAr,
    required this.grade,
    required this.collection,
    required this.sourceId,
    this.number,
    this.lang,
    this.title,
    this.text,
    this.attribution,
    this.gradeLabel,
    this.gradeAr,
    this.arabicOnly = false,
  });

  final String textAr;

  /// `sahih` / `hasan` (lokalizovat cez ARB).
  final String grade;

  /// Arabsky original stupna z HadeethEnc (`hadith.grade_ar`); zobrazuje
  /// sa len v AR UI (BF-02).
  final String? gradeAr;
  final String collection;
  final String? number;
  final String sourceId;

  /// Jazyk prekladu; null = bez prekladu.
  final String? lang;
  final String? title;
  final String? text;
  final String? attribution;
  final String? gradeLabel;

  /// Jazyk obsahu je `ar`: arabsky original bez prekladu a bez poznamky.
  final bool arabicOnly;
}

/// B6 dua.
final class DuaContent extends CardContent {
  const DuaContent(
    DuaCardId super.id, {
    required this.textAr,
    required this.sourceRef,
    required this.repeatCount,
    this.title,
    this.translit,
    this.lang,
    this.text,
    this.arabicOnly = false,
  });

  final String textAr;
  final String? title;
  final String? translit;
  final int repeatCount;
  final String sourceRef;
  final String? lang;
  final String? text;

  /// Jazyk obsahu je `ar`: arabsky original bez prekladu a bez poznamky.
  final bool arabicOnly;
}

/// B7 meno Allaha.
final class NameContent extends CardContent {
  const NameContent(
    NameCardId super.id, {
    required this.textAr,
    this.translit,
    this.refAyah,
    this.lang,
    this.meaning,
    this.shortNote,
    this.arabicOnly = false,
  });

  final String textAr;
  final String? translit;
  final AyahId? refAyah;
  final String? lang;
  final String? meaning;
  final String? shortNote;

  /// Jazyk obsahu je `ar`: meno bez vyznamu a bez poznamky.
  final bool arabicOnly;
}

/// B8 zamyslenie.
final class ReflectionContent extends CardContent {
  const ReflectionContent(
    ReflectionCardId super.id, {
    required this.lang,
    required this.text,
    this.question,
  });

  final String lang;
  final String text;
  final String? question;
}

/// B9 eventova karta.
final class EventContent extends CardContent {
  const EventContent(EventCardId super.id, {this.text});

  /// Text eventu v jazyku obsahu; null = karta bez textu (len nazov z ARB).
  final EventText? text;
}

/// B12 khatm.
final class KhatmContent extends CardContent {
  const KhatmContent(KhatmCardId super.id);

  int get n => (id as KhatmCardId).n;
}

/// Obsah kariet dennej sady a volneho citania (F-02).
abstract interface class CardContentRepository {
  /// Obsah karty v jazyku [lang]; null = obsah v content.db chyba (feed ju
  /// preskoci cez `DailySetRepository.markSkipped`). `word`/`quiz`/`done`
  /// tu nie su (slovicka su vypnute, done je UI karta).
  Future<CardContent?> load(CardId id, {required String lang});
}

class ContentCardRepository implements CardContentRepository {
  ContentCardRepository({
    required this._catalog,
    required this._quran,
    required this._calendar,
  });

  final ContentCatalog _catalog;
  final QuranRepository _quran;
  final CalendarRepository _calendar;

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    switch (id) {
      case IntroCardId(:final date):
        final resolution = await _calendar.resolve(date);
        final events = resolution.active;
        EventText? text;
        for (final e in events) {
          text = await _calendar.eventText(e.id, lang);
          if (text != null) break;
        }
        return IntroContent(
          id,
          date: date,
          hijri: resolution.hijri,
          event: text,
          moreEvents: events.isEmpty ? 0 : events.length - 1,
        );
      case AyahCardId(:final ayahId):
        final ayahs = await _quran.ayahs([ayahId], lang: lang);
        final surah = await _quran.surah(ayahId.surah, lang);
        if (ayahs.isEmpty || surah == null) return null;
        return AyahContent(
          id,
          ayah: ayahs.single,
          surah: surah,
          arabicOnly: lang == arabicLang,
        );
      case HadithCardId(:final hadithId):
        return await _hadith(id, hadithId, lang);
      case DuaCardId(:final duaId):
        return await _dua(id, duaId, lang);
      case NameCardId(:final nameId):
        return await _name(id, nameId, lang);
      case ReflectionCardId(:final reflectionId):
        return await _reflection(id, reflectionId, lang);
      case EventCardId(:final eventId):
        return EventContent(id, text: await _calendar.eventText(eventId, lang));
      case KhatmCardId():
        return KhatmContent(id);
      case WordCardId() || QuizCardId() || DoneCardId():
        return null;
    }
  }

  /// Jazyk obsahu, v ktorom je arabsky original sam textom karty.
  static const arabicLang = 'ar';

  Future<HadithContent?> _hadith(
    HadithCardId id,
    int hadithId,
    String lang,
  ) async {
    final dao = (await _catalog.db).hadithDao;
    final h = await dao.hadith(hadithId);
    if (h == null) return null;
    final arabicOnly = lang == arabicLang;
    // Len jazyk obsahu, nikdy `en` (docs/03 7.3).
    final t = arabicOnly ? null : await dao.hadithText(hadithId, lang);
    if (t != null) {
      return HadithContent(
        id,
        textAr: h.textAr,
        grade: h.grade,
        collection: h.collection,
        number: h.number,
        sourceId: t.sourceId,
        lang: lang,
        title: t.title,
        text: t.textContent,
        attribution: t.attribution,
        gradeLabel: t.gradeLabel,
        gradeAr: h.gradeAr,
      );
    }
    return HadithContent(
      id,
      textAr: h.textAr,
      grade: h.grade,
      collection: h.collection,
      number: h.number,
      sourceId: h.sourceId,
      gradeAr: h.gradeAr,
      arabicOnly: arabicOnly,
    );
  }

  Future<DuaContent?> _dua(DuaCardId id, int number, String lang) async {
    final textId = (await _catalog.duaIds()).textId(number);
    if (textId == null) return null;
    final dao = (await _catalog.db).curatedDao;
    final d = await dao.dua(textId);
    if (d == null) return null;
    final arabicOnly = lang == arabicLang;
    final t = arabicOnly ? null : await dao.duaText(textId, lang);
    return DuaContent(
      id,
      textAr: d.textAr,
      title: d.title,
      translit: d.translit,
      repeatCount: d.repeatCount,
      sourceRef: d.sourceRef,
      lang: t == null ? null : lang,
      text: t?.textContent,
      arabicOnly: arabicOnly,
    );
  }

  Future<NameContent?> _name(NameCardId id, int nameId, String lang) async {
    final dao = (await _catalog.db).curatedDao;
    final n = await dao.nameOfAllah(nameId);
    if (n == null) return null;
    final ref = n.refAyahId == null ? null : AyahId.tryFromValue(n.refAyahId!);
    final arabicOnly = lang == arabicLang;
    final t = arabicOnly ? null : await dao.nameText(nameId, lang);
    return NameContent(
      id,
      textAr: n.textAr,
      translit: n.translit,
      refAyah: ref,
      lang: t == null ? null : lang,
      meaning: t?.meaning,
      shortNote: t?.shortNote,
      arabicOnly: arabicOnly,
    );
  }

  Future<ReflectionContent?> _reflection(
    ReflectionCardId id,
    int number,
    String lang,
  ) async {
    final textId = (await _catalog.reflectionIds()).textId(number);
    if (textId == null) return null;
    final dao = (await _catalog.db).curatedDao;
    // Zamyslenie nema arabsky original: bez textu v jazyku obsahu sa karta
    // preskoci (feed `markSkipped`), bez `en` fallbacku (docs/03 7.3).
    final t = await dao.reflectionText(textId, lang);
    if (t == null) return null;
    return ReflectionContent(
      id,
      lang: lang,
      text: t.textContent,
      question: t.question,
    );
  }
}
