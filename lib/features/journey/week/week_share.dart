import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/journey/week_repository.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/journey/week/week_card.dart';
import 'package:prosoche/features/journey/week/week_providers.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Obrazok tyzdna: 4:5 (1080 x 1350 pri pixelRatio 3). Najhorsi pripad
/// (vsetky riadky, appky, citat [weekQuoteMaxChars]) sa zmesti, overuje
/// test. Keby predsa nie (iny jazyk, ine fonty), pouzije sa 9:16 ako pri
/// karte; text sa nikdy neoreze.
const double weekImageHeight = ShareImageSize.minLogicalHeight;

/// Render obrazka tyzdna do PNG; null = nezmestil sa ani do 9:16.
/// Override v testoch.
final Provider<CardImageRenderer> weekImageRendererProvider =
    Provider<CardImageRenderer>(
      (ref) => renderWidgetToPng,
      name: 'weekImageRendererProvider',
    );

/// Co je na obrazku tyzdna: riadky prehladu, volitelne appky a jeden
/// kratky citat. Ziadne datumy, mena, dennik ani text pouzivatela.
@immutable
final class WeekShareContent {
  const WeekShareContent({
    required this.title,
    required this.stats,
    required this.numbers,
    this.apps,
    this.quote,
  });

  /// "My week".
  final String title;
  final List<WeekStat> stats;

  /// Naformatovane cisla k [stats].
  final List<String> numbers;

  /// "Most paused: ..." len po zapnuti prepinaca.
  final String? apps;
  final CardShareData? quote;
}

/// Zostavi obsah obrazka; [withApps] prida najcastejsie zastavene appky.
WeekShareContent weekShareContent(
  BuildContext context,
  WeekSummary summary, {
  QuoteContent? quote,
  bool withApps = false,
}) {
  final l10n = context.l10n;
  final formats = ProsocheFormats(Localizations.localeOf(context));
  final stats = [
    for (final s in weekStats(context, summary))
      if (s.value > 0) WeekStat(s.value, s.label),
  ];
  final apps = summary.gate?.topApps ?? const [];
  return WeekShareContent(
    title: l10n.journeyWeekImageTitle,
    stats: stats,
    numbers: [for (final s in stats) formats.number(s.value)],
    apps: withApps && apps.isNotEmpty
        ? l10n.journeyWeekImageApps(apps.join(', '))
        : null,
    quote: quote == null ? null : shareDataFor(context, quote),
  );
}

/// Text k obrazku (appky bez obrazkov): riadky prehladu, citat, "via".
String weekShareText(BuildContext context, WeekShareContent c) {
  final l10n = context.l10n;
  final lines = [
    c.title,
    for (final (i, s) in c.stats.indexed) '${c.numbers[i]} ${s.label}',
    ?c.apps,
  ].join('\n');
  final quote = c.quote;
  return [
    lines,
    if (quote != null)
      buildShareText(quote, via: l10n.cardShareVia(l10n.appTitle))
    else
      l10n.cardShareVia(l10n.appTitle),
  ].join('\n\n');
}

/// Obrazok tyzdna v style obrazka karty (docs/DESIGN.md 7.9): meander
/// hore a dole, eyebrow, prehlad, citat s referenciou a prekladatelom,
/// v paticke znacka a nazov appky. Svetla aj tmava tema podla appky.
class WeekShareImage extends StatelessWidget {
  const WeekShareImage({
    required this.content,
    required this.appName,
    super.key,
  });

  final WeekShareContent content;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final quote = content.quote;
    final meta = sk.text.bodySmall!.copyWith(color: c.textSecondary);
    final number = sk.text.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: c.lead,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final label = sk.text.bodyMedium!.copyWith(color: c.textPrimary);
    final body = <Widget>[
      Text(content.title.toUpperCase(), style: sk.type.eyebrow),
      const SizedBox(height: SkSpace.space8),
      for (final (i, s) in content.stats.indexed)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 36,
                child: Text(content.numbers[i], style: number),
              ),
              const SizedBox(width: SkSpace.space8),
              Expanded(child: Text(s.label, style: label)),
            ],
          ),
        ),
      if (content.apps case final apps?) ...[
        const SizedBox(height: SkSpace.space4),
        // Nazvy appiek (nie text filozofa) smu byt skratene.
        Text(apps, style: meta, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      if (quote != null) ...[
        const SizedBox(height: SkSpace.space12),
        Directionality(
          textDirection: textDirectionForLanguage(quote.textLang ?? 'en'),
          child: Text(quote.text ?? '', style: sk.type.passage),
        ),
        const SizedBox(height: SkSpace.space4),
        // Autor a referencia v jednom riadku, prekladatel pod nimi.
        Text(
          [?quote.attribution, quote.reference].join(', '),
          style: sk.type.attribution,
        ),
        if (quote.source case final s?) Text(s, style: meta),
      ],
    ];
    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SkPortalMark(size: 16),
        const SizedBox(width: SkSpace.space8),
        Text(
          appName,
          style: sk.text.labelLarge!.copyWith(color: c.textSecondary),
        ),
      ],
    );
    const band = Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: SkSpace.space24),
      child: SkMeanderBand(opacity: 0.55),
    );
    return ColoredBox(
      color: c.bg,
      child: SizedBox(
        width: ShareImageSize.logicalWidth,
        child: LayoutBuilder(
          builder: (context, box) {
            final fixed = box.minHeight > 0 && box.minHeight.isFinite;
            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: SkSpace.space12),
                band,
                const SizedBox(height: SkSpace.space12),
                if (fixed) const Spacer(),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: SkSpace.space32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: body,
                  ),
                ),
                if (fixed) const Spacer(),
                const SizedBox(height: SkSpace.space12),
                band,
                const SizedBox(height: SkSpace.space4),
                footer,
                const SizedBox(height: SkSpace.space12),
              ],
            );
            return fixed
                ? SizedBox(height: box.minHeight, child: column)
                : column;
          },
        ),
      ),
    );
  }
}

/// Sheet s nahladom obrazka, prepinacom mien appiek (default vypnuty)
/// a tlacidlom "Share image". Nic sa neloguje ani neposiela do analytiky.
Future<void> showWeekShareSheet(BuildContext context, WeekSummary summary) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WeekShareSheet(summary: summary),
    );

class WeekShareSheet extends ConsumerStatefulWidget {
  const WeekShareSheet({required this.summary, super.key});

  final WeekSummary summary;

  @override
  ConsumerState<WeekShareSheet> createState() => _WeekShareSheetState();
}

class _WeekShareSheetState extends ConsumerState<WeekShareSheet> {
  bool _withApps = false;
  bool _busy = false;

  WeekShareContent _content(QuoteContent? quote) => weekShareContent(
    context,
    widget.summary,
    quote: quote,
    withApps: _withApps,
  );

  Future<void> _share(QuoteContent? quote) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final content = _content(quote);
    final text = weekShareText(context, content);
    final png = await ref.read(weekImageRendererProvider)(
      context,
      WeekShareImage(content: content, appName: l10n.appTitle),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (png == null) {
      showSkSnackbar(context, message: l10n.journeyWeekShareFailed);
      return;
    }
    await ref.read(cardSharerProvider).shareImage(png, text: text);
    if (mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final quote = ref.watch(weekQuoteProvider);
    // Bez citatu (chyba content.db) sa zdiela aj tak, len bez neho.
    final q = quote.value;
    final ready = !quote.isLoading;
    final hasApps = widget.summary.gate?.topApps.isNotEmpty ?? false;
    final content = _content(q);
    return SkSheet(
      title: l10n.journeyWeekShareTitle,
      closeLabel: l10n.journeyWeekShareClose,
      actions: [
        SkButton.primary(
          label: l10n.journeyWeekShareImage,
          icon: Icons.ios_share,
          expand: true,
          loading: _busy || !ready,
          onPressed: ready && !_busy ? () => unawaited(_share(q)) : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Semantics(
              image: true,
              label: l10n.journeyWeekPreviewLabel,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: sk.colors.outline),
                  ),
                  child: ColoredBox(
                    color: sk.colors.bg,
                    child: SizedBox(
                      width: ShareImageSize.logicalWidth * 0.6,
                      height: weekImageHeight * 0.6,
                      // Prirodzena vyska zmensena do 4:5; PNG ma vzdy
                      // presne 4:5 (renderer), nahlad nikdy nepretecie.
                      child: FittedBox(
                        child: MediaQuery.withNoTextScaling(
                          child: WeekShareImage(
                            content: content,
                            appName: l10n.appTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SkSpace.space16),
          Text(
            l10n.journeyWeekShareBody,
            style: sk.text.bodyMedium!.copyWith(color: sk.colors.textSecondary),
          ),
          if (hasApps)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.journeyWeekShareApps),
              value: _withApps,
              onChanged: (v) => setState(() => _withApps = v),
            ),
        ],
      ),
    );
  }
}
