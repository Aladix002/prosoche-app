@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/cards.dart';
import 'package:sakina/ui/gallery/gallery_samples.dart';
import 'package:sakina/ui/theme/sakina_theme.dart';

import '../../helpers/golden/golden.dart';

/// Goldeny kazdeho typu karty (PLAN_VYVOJA F-02 DoD): EN, AR, UR, BN x
/// svetla/tmava x textScale 1.0/1.5/2.0, ID a TR smoke. Obsah je
/// placeholder (pseudo-lokalizovany preklad, neutralne arabske ukazky).
///
///   flutter test --update-goldens test/features/cards/cards_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? SakinaTheme.dark() : SakinaTheme.light();

  final date = LocalDate(2026, 10, 30);
  void noop() {}
  final actions = CardActions(onToggleSave: noop, onShare: noop, onMore: noop);

  String text(BuildContext context, {int words = 14}) =>
      PseudoLocale.sentence(Localizations.localeOf(context), words: words);
  String lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// V AR UI je arabsky original sam textom (BF-01, docs/03 7.3).
  bool ar(BuildContext context) => lang(context) == 'ar';

  /// Karta na celu stranku feedu (360 x 640).
  void cardGolden(String name, Widget Function(BuildContext context) build) {
    goldenAllLocales(
      'card $name',
      fileName: 'card_$name',
      theme: theme,
      textScales: cardTextScales,
      builder: (context) => SizedBox(
        width: 360,
        height: 640,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: build(context),
        ),
      ),
    );
  }

  const surah = SurahInfo(
    id: 2,
    nameAr: GallerySamples.lemma,
    nameTranslit: 'Placeholder',
    nameMeaning: '[PLACEHOLDER]',
    revelationPlace: 'medinan',
    ayahCount: 286,
    bismillahPre: true,
  );

  cardGolden(
    'intro',
    (context) => IntroCard(
      content: IntroContent(
        IntroCardId(date),
        date: date,
        hijri: IslamicCalendar().hijriOf(date),
        event: EventText(
          eventId: 'example',
          lang: lang(context),
          title: text(context, words: 2),
          body: text(context, words: 10),
        ),
        moreEvents: 1,
      ),
      cardsCount: 10,
      questSlots: const [QuestSlot.read, QuestSlot.learn, QuestSlot.act],
      niyyah: text(context, words: 4),
    ),
  );

  cardGolden(
    'ayah',
    (context) => AyahCard(
      content: AyahContent(
        AyahCardId(AyahId(2, 12)),
        surah: surah,
        ayah: AyahView(
          id: AyahId(2, 12),
          textUthmani: GallerySamples.words,
          juz: 1,
          page: 3,
          translation: ar(context)
              ? null
              : TranslationText(
                  text: text(context, words: 24),
                  sourceId: 'fake',
                  lang: lang(context),
                ),
        ),
        arabicOnly: ar(context),
      ),
      translationSource: '[PLACEHOLDER] source',
      actions: actions,
      onReadInContext: noop,
    ),
  );

  cardGolden(
    'ayah_fallback',
    (context) => AyahCard(
      content: AyahContent(
        AyahCardId(AyahId(2, 12)),
        surah: surah,
        ayah: AyahView(
          id: AyahId(2, 12),
          textUthmani: GallerySamples.long,
          juz: 1,
          page: 3,
          translation: const TranslationText(
            text: '[PLACEHOLDER] English translation of meaning',
            sourceId: 'fake',
            lang: 'en',
            isFallback: true,
          ),
        ),
      ),
      translationSource: '[PLACEHOLDER] source',
      actions: actions,
    ),
  );

  cardGolden(
    'hadith',
    (context) => HadithCard(
      content: HadithContent(
        HadithCardId(1),
        textAr: GallerySamples.sentenceSimple,
        grade: 'sahih',
        collection: '[PLACEHOLDER] collection',
        number: '1',
        sourceId: 'fake',
        lang: ar(context) ? null : lang(context),
        text: ar(context) ? null : text(context, words: 20),
        attribution: '[PLACEHOLDER] attribution',
        arabicOnly: ar(context),
      ),
      actions: actions,
      onExplanation: ar(context) ? null : noop,
    ),
  );

  // BF-01: jazyk bez prekladu (napr. BN) - original + poznamka, bez EN;
  // balik vysvetliviek nie je stiahnuty.
  cardGolden(
    'hadith_missing',
    (context) => HadithCard(
      content: HadithContent(
        HadithCardId(1),
        textAr: GallerySamples.sentenceSimple,
        grade: 'sahih',
        collection: '[PLACEHOLDER] collection',
        number: '1',
        sourceId: 'fake',
      ),
      actions: actions,
      onDownloadExplanations: noop,
    ),
  );

  // BF-02: takhrij "muttafaq alayh" a stupen v jazyku UI (v AR arabsky
  // original), zlyhane stiahnutie vysvetliviek s Retry.
  cardGolden(
    'hadith_rc0',
    (context) => HadithCard(
      content: HadithContent(
        HadithCardId(1),
        textAr: GallerySamples.sentenceSimple,
        grade: 'sahih',
        gradeAr: GallerySamples.lemma,
        collection: hadithMuttafaqAlayh,
        sourceId: 'fake',
        lang: ar(context) ? null : lang(context),
        text: ar(context) ? null : text(context, words: 12),
        attribution: ar(context) ? null : '[PLACEHOLDER] attribution',
        arabicOnly: ar(context),
      ),
      actions: actions,
      explanationsFailed: true,
      onDownloadExplanations: noop,
    ),
  );

  // BF-01: znacky poznamok prekladatela QuranEnc ako horny index.
  cardGolden(
    'ayah_notes',
    (context) => AyahCard(
      content: AyahContent(
        AyahCardId(AyahId(1, 1)),
        surah: surah,
        ayah: AyahView(
          id: AyahId(1, 1),
          textUthmani: GallerySamples.words,
          juz: 1,
          page: 1,
          translation: TranslationText(
            text:
                '(1) ${text(context, words: 6)}[2] '
                '${text(context, words: 8)}[3]',
            footnotes: '[2]- [PLACEHOLDER]\n[3]- [PLACEHOLDER]',
            sourceId: 'fake',
            lang: lang(context),
          ),
        ),
      ),
      translationSource: '[PLACEHOLDER] source',
      actions: actions,
      onReadInContext: noop,
    ),
  );

  cardGolden(
    'dua',
    (context) => DuaCard(
      content: DuaContent(
        DuaCardId(1),
        textAr: GallerySamples.sentenceSimple,
        title: text(context, words: 1),
        translit: '[PLACEHOLDER] translit',
        sourceRef: '[PLACEHOLDER] 1',
        repeatCount: 3,
        lang: ar(context) ? null : lang(context),
        text: ar(context) ? null : text(context, words: 16),
        arabicOnly: ar(context),
      ),
      actions: actions,
    ),
  );

  cardGolden(
    'name',
    (context) => NameCard(
      content: NameContent(
        NameCardId(7),
        textAr: GallerySamples.lemma,
        translit: '[PLACEHOLDER] translit',
        refAyah: AyahId(59, 23),
        lang: ar(context) ? null : lang(context),
        meaning: ar(context) ? null : text(context, words: 3),
        shortNote: ar(context) ? null : text(context, words: 18),
        arabicOnly: ar(context),
      ),
      actions: actions,
      onOpenAyah: noop,
    ),
  );

  cardGolden(
    'reflection',
    (context) => ReflectionCard(
      content: ReflectionContent(
        ReflectionCardId(3),
        lang: lang(context),
        text: text(context, words: 30),
        question: text(context, words: 8),
      ),
      actions: actions,
    ),
  );

  cardGolden(
    'event',
    (context) => EventCard(
      content: EventContent(
        EventCardId('example', date),
        text: EventText(
          eventId: 'example',
          lang: lang(context),
          title: text(context, words: 1),
          body: text(context, words: 16),
        ),
      ),
      surah: surah,
      onReadSurah: noop,
    ),
  );

  cardGolden(
    'khatm',
    (context) =>
        KhatmCard(content: KhatmContent(KhatmCardId(1)), onStartAgain: noop),
  );

  cardGolden(
    'done',
    (context) => DoneCard(
      summary: DoneSummary(
        cards: 10,
        verses: 7,
        questsDone: 2,
        questsTotal: 3,
        openDeed: text(context, words: 4),
        streak: 6,
        nextPrayer: (prayer: 'Maghrib', time: '16:39'),
        countedFor: date,
      ),
      onBack: noop,
      onKeepReading: noop,
      onDeedDone: noop,
    ),
  );
}
