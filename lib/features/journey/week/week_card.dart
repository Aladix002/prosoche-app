import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/journey/week_summary.dart';
import 'package:prosoche/features/journey/week/week_providers.dart';
import 'package:prosoche/features/journey/week/week_share.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Karta "This week" na Journey (J-01). Pri chybe alebo pocas nacitania
/// sa nezobrazi nic (Journey ma vlastny stav chyby a nacitania).
class JourneyWeekCard extends ConsumerStatefulWidget {
  const JourneyWeekCard({super.key});

  @override
  ConsumerState<JourneyWeekCard> createState() => _JourneyWeekCardState();
}

class _JourneyWeekCardState extends ConsumerState<JourneyWeekCard> {
  // Brana zapisuje gate_session zo svojho izolatu; drift hlavnej appky
  // o tom nevie. Po navrate do appky sa tyzden nacita znova.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(weekActivityProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(weekSummaryProvider).value;
    if (summary == null) return const SizedBox.shrink();
    return WeekSummaryCard(
      summary: summary,
      onShare: summary.isEmpty
          ? null
          : () => unawaited(showWeekShareSheet(context, summary)),
    );
  }
}

/// Jeden riadok prehladu: cislo, popis a volitelny detail.
@immutable
final class WeekStat {
  const WeekStat(this.value, this.label, {this.detail});

  final int value;
  final String label;
  final String? detail;
}

/// Riadky prehladu v poradi zobrazenia (karta, obrazok, text zdielania).
/// Brana len ak existuje, streak len mimo simple mode.
List<WeekStat> weekStats(BuildContext context, WeekSummary s) {
  final l10n = context.l10n;
  final formats = ProsocheFormats(Localizations.localeOf(context));
  return [
    if (s.gate case final g?) ...[
      WeekStat(g.paused, l10n.journeyWeekPaused(g.paused)),
      WeekStat(g.notOpened, l10n.journeyWeekNotOpened(g.notOpened)),
    ],
    WeekStat(s.cardsRead, l10n.journeyWeekCards(s.cardsRead)),
    WeekStat(
      s.practiceDays,
      l10n.journeyWeekPracticeDays(s.practiceDays),
      detail: s.practiceDays == 0
          ? null
          : l10n.journeyWeekPracticeDetail(
              formats.number(s.morningDays),
              formats.number(s.eveningDays),
            ),
    ),
    if (s.streak case final n? when n > 0)
      WeekStat(n, l10n.journeyWeekStreak(n)),
  ];
}

/// "Nov 3 – Nov 9" alebo v prvom tyzdni "Since Nov 6".
String weekRangeLabel(BuildContext context, WeekSummary s) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context);
  final formats = ProsocheFormats(locale);
  String day(DateTime d) => localizeDigits(
    DateFormat.MMMd(locale.toLanguageTag()).format(d),
    formats.digits,
  );
  return s.isPartial
      ? l10n.journeyWeekSince(day(s.since.toLocalDateTime()))
      : l10n.journeyWeekRange(
          day(s.window.start.toLocalDateTime()),
          day(s.window.end.toLocalDateTime()),
        );
}

/// Ciste zobrazenie karty (goldeny, galeria).
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({required this.summary, this.onShare, super.key});

  final WeekSummary summary;

  /// null = bez tlacidla (prazdny tyzden).
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final l10n = context.l10n;
    final formats = ProsocheFormats(Localizations.localeOf(context));
    final title = Semantics(
      header: true,
      child: Text(l10n.journeyWeekTitle.toUpperCase(), style: sk.type.eyebrow),
    );
    final range = Text(
      Bidi.isolate(weekRangeLabel(context, summary)),
      style: sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary),
    );
    final children = <Widget>[
      Wrap(
        spacing: SkSpace.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [title, range],
      ),
      const SizedBox(height: SkSpace.space12),
      if (summary.isEmpty)
        Text(
          l10n.journeyWeekEmpty,
          style: sk.text.bodyMedium!.copyWith(color: sk.colors.textSecondary),
        )
      else ...[
        for (final (i, s) in weekStats(context, summary).indexed) ...[
          if (i > 0) const SizedBox(height: SkSpace.space8),
          _StatRow(stat: s, number: formats.number(s.value)),
        ],
        if (onShare != null) ...[
          const SizedBox(height: SkSpace.space16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkButton.outlined(
              key: const ValueKey('week:share'),
              label: l10n.journeyWeekShare,
              icon: Icons.ios_share,
              onPressed: onShare,
            ),
          ),
        ],
      ],
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sk.colors.surface,
        borderRadius: BorderRadius.circular(SkRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(SkSpace.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, required this.number});

  final WeekStat stat;
  final String number;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              number,
              style: sk.text.titleLarge!.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: SkSpace.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.label, style: sk.text.bodyLarge),
                if (stat.detail case final d?)
                  Text(
                    Bidi.isolate(d),
                    style: sk.text.bodySmall!.copyWith(
                      color: sk.colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
