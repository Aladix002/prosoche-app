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

/// B1 uvodna karta: den, datum, velkost sady, sloty questov a umysel
/// pouzivatela.
class IntroCard extends StatelessWidget {
  const IntroCard({
    required this.content,
    required this.cardsCount,
    this.questSlots = const [],
    this.intention,
    this.semanticLabel,
    super.key,
  });

  final IntroContent content;
  final int cardsCount;
  final List<QuestSlot> questSlots;
  final String? intention;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final c = sk.colors;
    final secondary = sk.text.bodyLarge!.copyWith(color: c.textSecondary);
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: context.weekdayLabel(content.date).toUpperCase(),
      // D-01: uvod dna ako titulna strana - oblúk s bodom pozornosti,
      // datum (Cormorant), rimsa, velkost sady a umysel.
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: SkArch(size: 64)),
          const SizedBox(height: SkSpace.space16),
          Text(
            context.longDateLabel(content.date),
            textAlign: TextAlign.center,
            style: sk.text.headlineMedium,
          ),
          const SizedBox(height: SkSpace.space24),
          const Center(child: SkCornice(width: 96)),
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
          if (intention case final text? when text.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space16),
            Text(
              l10n.todayIntention(text),
              textAlign: TextAlign.center,
              style: sk.type.reflection.copyWith(color: c.textSecondary),
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
    this.questsDone = 0,
    this.questsTotal = 0,
    this.openDeed,
    this.streak,
    this.countedFor,
  });

  /// N kariet sady.
  final int cards;
  final int questsDone;
  final int questsTotal;

  /// Titulok otvoreneho ACT questu (z content.db).
  final String? openDeed;

  /// Streak; null v `simple_mode`.
  final int? streak;

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
      l10n.doneSummary(s.cards),
      if (s.questsTotal > 0) l10n.doneQuests(s.questsDone, s.questsTotal),
      if (s.streak case final streak? when streak > 0)
        Bidi.isolate(l10n.todayStreak(streak)),
    ];
    return SkCardSurface(
      semanticLabel: semanticLabel,
      // D-01: pokojne uzavretie dna - meander sa pomaly "vytesa"
      // (`motion.calm`, pri reduce motion staticky), portal ako znak.
      // Ziadne konfety ani odznaky.
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: SkPortalMark(size: 44)),
          const SizedBox(height: SkSpace.space16),
          const Center(
            child: SkMeanderBand(width: 180, framed: false, animate: true),
          ),
          const SizedBox(height: SkSpace.space24),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              l10n.doneTitle,
              textAlign: TextAlign.center,
              style: sk.text.headlineMedium,
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
                children: [for (final line in stats) _DoneStat(line)],
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

/// Riadok suhrnu dna: bod pozornosti a text.
class _DoneStat extends StatelessWidget {
  const _DoneStat(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: SkSpace.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: SkSpace.space4),
            child: SkAttentionMark(size: 12, ring: false),
          ),
          const SizedBox(width: SkSpace.space12),
          Expanded(child: Text(text, style: sk.text.bodyLarge)),
        ],
      ),
    );
  }
}
