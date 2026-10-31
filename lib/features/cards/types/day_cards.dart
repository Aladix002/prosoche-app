import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Odhad dlzky sady: N x 30 s (docs/02 B1), zaokruhlene nahor na minuty.
int estimatedMinutes(int cards) => (cards * 30 / 60).ceil();

/// Nazov slotu questu pre uvodnu kartu (bez obsahu questu, docs/02 B1).
String questSlotLabel(BuildContext context, QuestSlot slot) => switch (slot) {
  QuestSlot.read => context.l10n.todayQuestSlotRead,
  QuestSlot.learn => context.l10n.todayQuestSlotLearn,
  QuestSlot.act => context.l10n.todayQuestSlotAct,
};

/// B1 uvodna karta: den, hijri a gregoriansky datum, event dna (text
/// z content.db), velkost sady, sloty questov a umysel pouzivatela.
class IntroCard extends StatelessWidget {
  const IntroCard({
    required this.content,
    required this.cardsCount,
    this.questSlots = const [],
    this.niyyah,
    this.semanticLabel,
    super.key,
  });

  final IntroContent content;
  final int cardsCount;
  final List<QuestSlot> questSlots;
  final String? niyyah;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final c = sk.colors;
    final event = content.event;
    final secondary = sk.text.bodyLarge!.copyWith(color: c.textSecondary);
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: context.weekdayLabel(content.date).toUpperCase(),
      // D-05: uvod dna ako titulna strana - medailon, hijri datum v strede,
      // pod ornamentom velkost sady a umysel.
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: SkMotifBadge(size: 80)),
          const SizedBox(height: SkSpace.space16),
          Text(
            context.hijriLabel(content.hijri),
            textAlign: TextAlign.center,
            style: sk.text.headlineSmall!.copyWith(color: c.accentText),
          ),
          const SizedBox(height: SkSpace.space4),
          Text(
            context.longDateLabel(content.date),
            textAlign: TextAlign.center,
            style: sk.text.titleMedium!.copyWith(color: c.textSecondary),
          ),
          if (event != null) ...[
            const SizedBox(height: SkSpace.space24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(SkRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(SkSpace.space16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(Icons.event_outlined, color: c.accentText),
                    ),
                    const SizedBox(width: SkSpace.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: sk.text.titleMedium),
                          if (event.body case final body? when body.isNotEmpty)
                            Text(body, style: sk.text.bodyMedium),
                          if (content.moreEvents > 0)
                            Text(
                              l10n.cardIntroMoreEvents(content.moreEvents),
                              style: sk.text.bodySmall!.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: SkSpace.space24),
          const SkOrnamentDivider(width: 96),
          const SizedBox(height: SkSpace.space24),
          Text(
            l10n.cardIntroEstimate(cardsCount, estimatedMinutes(cardsCount)),
            textAlign: TextAlign.center,
            style: sk.text.bodyLarge,
          ),
          if (questSlots.isNotEmpty)
            Text(
              l10n.cardIntroQuests(
                questSlots.map((s) => questSlotLabel(context, s)).join(' · '),
              ),
              textAlign: TextAlign.center,
              style: secondary,
            ),
          if (niyyah case final text? when text.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space16),
            Text(
              l10n.todayNiyyah(text),
              textAlign: TextAlign.center,
              style: sk.type.reflection.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// B9 eventova karta: nazov a text eventu z content.db, pri eventoch so
/// surou (al-Kahf) CTA na citanie celej sury. Neuklada sa, nezdiela sa.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.content,
    this.surah,
    this.onReadSurah,
    this.semanticLabel,
    super.key,
  });

  final EventContent content;

  /// Sura eventu (z `card_overrides_json`), ak ju event ma.
  final SurahInfo? surah;
  final VoidCallback? onReadSurah;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final text = content.text;
    final s = surah;
    final date = (content.id as EventCardId).date;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: (text?.title ?? l10n.cardTypeEvent).toUpperCase(),
      eyebrowDetail: context.weekdayLabel(date),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.event_outlined,
              size: 40,
              color: sk.colors.accentText,
            ),
          ),
          if (text?.body case final body? when body.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space16),
            Text(body, style: sk.type.translation),
          ],
          if (s != null) ...[
            const SizedBox(height: SkSpace.space24),
            Text(
              l10n.cardEventSurah(s.nameTranslit, s.ayahCount),
              style: sk.text.bodyLarge,
            ),
            if (onReadSurah != null) ...[
              const SizedBox(height: SkSpace.space16),
              SkButton.secondary(
                label: l10n.cardEventReadSurah(s.nameTranslit),
                onPressed: onReadSurah,
                expand: true,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// B12 khatm: osobny progres, neuklada sa, nezdiela sa.
class KhatmCard extends StatelessWidget {
  const KhatmCard({
    required this.content,
    this.onStartAgain,
    this.semanticLabel,
    super.key,
  });

  final KhatmContent content;
  final VoidCallback? onStartAgain;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.auto_stories_outlined,
              size: 40,
              color: sk.colors.goldDeco,
            ),
          ),
          const SizedBox(height: SkSpace.space16),
          Text(l10n.khatmTitle, style: sk.text.headlineSmall),
          const SizedBox(height: SkSpace.space8),
          Text(
            l10n.khatmNumber(content.n),
            style: sk.text.bodyLarge!.copyWith(color: sk.colors.textSecondary),
          ),
          if (onStartAgain != null) ...[
            const SizedBox(height: SkSpace.space24),
            SkButton.secondary(
              label: l10n.khatmStartAgain,
              onPressed: onStartAgain,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Udaje pre kartu "Dnes si hotovy" (B10).
@immutable
class DoneSummary {
  const DoneSummary({
    required this.cards,
    required this.verses,
    this.questsDone = 0,
    this.questsTotal = 0,
    this.openDeed,
    this.streak,
    this.nextPrayer,
    this.countedFor,
  });

  /// N obsahovych kariet.
  final int cards;
  final int verses;
  final int questsDone;
  final int questsTotal;

  /// Titulok otvoreneho ACT questu (z content.db).
  final String? openDeed;

  /// Streak; null v `simple_mode`.
  final int? streak;

  /// "Maghrib at 16:39"; null bez polohy.
  final ({String prayer, String time})? nextPrayer;

  /// Den, ku ktoremu sa sada pocita pri dokonceni po polnoci.
  final LocalDate? countedFor;
}

/// B10 "Dnes si hotovy": zaver dna, feed konci. Ziadne konfety, body ani
/// vyzvy na zdielanie (docs/01 1.4, 5.4).
class DoneCard extends StatelessWidget {
  const DoneCard({
    required this.summary,
    required this.onBack,
    this.onKeepReading,
    this.onDeedDone,
    this.semanticLabel,
    super.key,
  });

  final DoneSummary summary;
  final VoidCallback onBack;
  final VoidCallback? onKeepReading;

  /// "I did it" pri otvorenom ACT queste.
  final VoidCallback? onDeedDone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final c = sk.colors;
    final s = summary;
    final secondary = sk.text.bodyLarge!.copyWith(color: c.textSecondary);
    final stats = [
      l10n.doneSummary(s.cards, s.verses),
      if (s.questsTotal > 0) l10n.doneQuests(s.questsDone, s.questsTotal),
      if (s.streak case final streak? when streak > 0)
        Bidi.isolate(l10n.todayStreak(streak)),
    ];
    return SkCardSurface(
      semanticLabel: semanticLabel,
      // D-05: pokojne uzavretie dna - medailon sa pomaly dokresli
      // (`motion.calm`, pri reduce motion staticky), ziadne konfety.
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: SkMotifBadge(icon: Icons.check, size: 96, animate: true),
          ),
          const SizedBox(height: SkSpace.space16),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              l10n.doneTitle,
              textAlign: TextAlign.center,
              style: sk.text.headlineSmall,
            ),
          ),
          if (s.countedFor case final day?) ...[
            const SizedBox(height: SkSpace.space4),
            Text(
              l10n.doneCountedFor(context.weekdayLabel(day)),
              textAlign: TextAlign.center,
              style: secondary,
            ),
          ],
          const SizedBox(height: SkSpace.space24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(SkRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
                vertical: SkSpace.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in stats) _DoneStat(line),
                  if (s.nextPrayer case final p?)
                    _DoneStat(
                      l10n.doneNextPrayer(p.prayer, p.time),
                      icon: Icons.schedule,
                    ),
                ],
              ),
            ),
          ),
          if (s.openDeed case final deed?) ...[
            const SizedBox(height: SkSpace.space16),
            Text(l10n.doneOpenDeed(deed), style: sk.text.bodyLarge),
            if (onDeedDone != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SkButton.outlined(
                  label: SkUiStrings.of(context).iDidIt,
                  onPressed: onDeedDone,
                ),
              ),
          ],
          const SizedBox(height: SkSpace.space24),
          Text(l10n.doneClosed, textAlign: TextAlign.center, style: secondary),
          const SizedBox(height: SkSpace.space16),
          SkButton.primary(
            label: l10n.feedBackToToday,
            onPressed: onBack,
            expand: true,
          ),
          if (onKeepReading != null) ...[
            const SizedBox(height: SkSpace.space8),
            SkButton.tertiary(
              label: l10n.doneKeepReading,
              onPressed: onKeepReading,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Riadok suhrnu dna: maly ornament (alebo ikona) a text.
class _DoneStat extends StatelessWidget {
  const _DoneStat(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: SkSpace.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: SkSpace.space4),
            child: icon == null
                ? SkRosette(
                    size: 16,
                    ring: false,
                    strokeWidth: 1,
                    color: sk.colors.goldDeco,
                  )
                : ExcludeSemantics(
                    child: Icon(icon, size: 16, color: sk.colors.textSecondary),
                  ),
          ),
          const SizedBox(width: SkSpace.space12),
          Expanded(child: Text(text, style: sk.text.bodyLarge)),
        ],
      ),
    );
  }
}
