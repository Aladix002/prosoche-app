import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_states.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/i18n/prosoche_locales.dart';
import 'package:prosoche/ui/motif/sk_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Varianta karty (docs/01 3.2 `SkCardSurface`).
enum SkCardVariant {
  /// Feed (PageView): cela vyska, obsah scrolluje vnutri.
  full,

  /// Brana: ako full, bez bookmark/share (akcie doda volajuci).
  gate,

  /// V liste: `radiusMd`, bez hlavneho bloku (len referencia a nahlad).
  compact,
}

/// Kontajner kariet: eyebrow (referencia), akcie v hlavicke, hlavny blok,
/// text, atribucia a volitelna akcna oblast.
///
/// Hlavny blok nikdy nie je prekryty (ziadny gradient ani badge nad nim).
/// Pri preteceni obsah scrolluje vnutri karty a screen reader dostane
/// "Scroll for more".
class SkCardSurface extends StatelessWidget {
  const SkCardSurface({
    this.variant = SkCardVariant.full,
    this.eyebrow,
    this.eyebrowDetail,
    this.headerActions = const [],
    this.lead,
    this.translation,
    this.attribution,
    this.footer,
    this.loading = false,
    this.error,
    this.semanticLabel,
    this.onTap,
    super.key,
  }) : assert(
         variant != SkCardVariant.compact || lead == null,
         'Compact karta hlavny blok nezobrazuje (docs/01 3.2).',
       );

  final SkCardVariant variant;

  /// Napr. "QUOTE" (caption, textSecondary).
  final String? eyebrow;

  /// Referencia pod typom (napr. "Meditations 2.1"): plna karta ju ukaze
  /// vyraznejsie na druhom riadku hlavicky (D-05).
  final String? eyebrowDetail;

  /// Bookmark, share, audio (48x48 targety).
  final List<Widget> headerActions;

  /// Hlavny blok karty (nie v compact).
  final Widget? lead;

  /// Text karty (Text so stylom `context.sk.type.translation`).
  final Widget? translation;

  /// Atribucia, napr. "Marcus Aurelius, tr. George Long" (caption).
  final String? attribution;

  /// Akcia alebo oblast odpovede.
  final Widget? footer;

  /// Skeleton namiesto obsahu.
  final bool loading;

  /// `SkErrorState` vnutri karty (napr. so "Skip this card").
  final Widget? error;

  /// Napr. "Card 5 of 12, quote" (docs/01 8.1).
  final String? semanticLabel;

  /// Len pre compact (navigacia na detail). Plna karta nema ripple.
  final VoidCallback? onTap;

  bool get _compact => variant == SkCardVariant.compact;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final radius = BorderRadius.circular(_compact ? SkRadius.md : SkRadius.lg);
    final padding = _compact ? SkSpace.space16 : SkSpace.space24;
    // Rozostup pismen len mimo RTL jazykov (spojite pismo by sa rozpadlo).
    final locale = Localizations.maybeLocaleOf(context);
    final ltr = locale == null || !ProsocheLocales.isRtl(locale);

    Widget body;
    if (loading) {
      body = const SkSkeleton.card();
    } else if (error != null) {
      body = Center(child: _ScrollableContent(children: [error!]));
    } else {
      final row = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            if (eyebrow != null) ...[
              Expanded(
                child: Text(
                  _compact
                      ? [eyebrow!, ?eyebrowDetail].join(' \u00B7 ')
                      : (ltr ? eyebrow!.toUpperCase() : eyebrow!),
                  style: _compact
                      ? sk.text.bodySmall!.copyWith(
                          color: c.textSecondary,
                          letterSpacing: ltr ? 0.4 : 0,
                        )
                      // Typ karty: Inter verzalky v terakote (docs/DESIGN.md
                      // 3.3); rozostup len v latinke.
                      : sk.type.eyebrow.copyWith(letterSpacing: ltr ? null : 0),
                ),
              ),
            ] else
              const Spacer(),
            ...headerActions,
          ],
        ),
      );
      final detail = eyebrowDetail;
      // Plna karta: typ male zlatym pismom, referencia pod nim vyrazne
      // na celu sirku (nelame sa vedla akcii).
      final header = (eyebrow != null || headerActions.isNotEmpty)
          ? (_compact || detail == null
                ? row
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      row,
                      // Referencia diela "Meditations 2.1" (EB Garamond).
                      Text(detail, style: sk.type.reference),
                    ],
                  ))
          : null;
      final text = <Widget>[
        ?lead,
        if (translation != null) ...[
          if (lead != null)
            const Padding(
              // Spolu space32+ medzi hlavnym blokom a textom.
              padding: EdgeInsetsDirectional.symmetric(
                vertical: SkSpace.space24,
              ),
              child: SkOrnamentDivider(width: 96),
            )
          else
            const SizedBox(height: SkSpace.space8),
          DefaultTextStyle.merge(
            style: _compact ? sk.text.bodyMedium : sk.type.translation,
            child: translation!,
          ),
        ],
        if (attribution != null) ...[
          SizedBox(height: _compact ? SkSpace.space8 : SkSpace.space12),
          // Autor a dielo: EB Garamond italic (docs/DESIGN.md 3.5).
          Text(
            attribution!,
            style: _compact
                ? sk.text.bodySmall!.copyWith(color: c.textTertiary)
                : sk.type.attribution,
          ),
        ],
      ];
      if (_compact) {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?header,
            ...text,
            if (footer != null) ...[
              const SizedBox(height: SkSpace.space24),
              footer!,
            ],
          ],
        );
      } else {
        // Hlavicka hore, text v optickom strede, akcia dole. Ked sa obsah
        // nezmesti, vsetko ide pod seba a karta scrolluje (B0.5).
        // Hlavicka hore, obsah (text a akcia, pri uvode a zavere dna len
        // akcna oblast) v optickom strede zvysnej plochy. Ked sa obsah
        // nezmesti, scrolluje pod hlavickou (B0.5).
        final block = text.isEmpty
            ? <Widget>[?footer]
            : [
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: SkSpace.space16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: text,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: SkSpace.space8),
                  footer!,
                ],
              ];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Vlastny uzol: typ a referencia sa necitaju dvakrat v labeli
            // karty ("Card 5 of 12, ...").
            if (header != null)
              Semantics(container: true, child: header)
            else
              const SizedBox.shrink(),
            Flexible(child: _ScrollableContent(children: block)),
            // Protivaha hlavicky: obsah je v strede medzi nou a spodkom.
            const SizedBox.shrink(),
          ],
        );
      }
    }

    final Widget card;
    if (_compact) {
      card = Material(
        color: c.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsetsDirectional.all(padding),
            child: body,
          ),
        ),
      );
    } else {
      final dark = Theme.of(context).brightness == Brightness.dark;
      card = DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          // "List papiera": jemny tien len vo svetlej teme (docs/01 2.6).
          boxShadow: dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x121B2230),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            // Ramcek lezi v odsadeni karty, za obsahom (nikdy nad textom).
            painter: SkCardFramePainter(
              color: c.goldDeco.withValues(alpha: dark ? 0.35 : 0.45),
              radius: SkRadius.lg - 8,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(padding),
              child: body,
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      button: _compact && onTap != null,
      child: card,
    );
  }
}

/// Obsah plnej karty: ak sa nezmesti, scrolluje vnutri. Screen reader
/// dostane hint "Scroll for more"; vizualne ziadny gradient nad textom.
class _ScrollableContent extends StatefulWidget {
  const _ScrollableContent({required this.children});

  final List<Widget> children;

  @override
  State<_ScrollableContent> createState() => _ScrollableContentState();
}

class _ScrollableContentState extends State<_ScrollableContent> {
  bool _overflows = false;

  bool _onMetrics(ScrollMetricsNotification n) {
    final overflows = n.metrics.maxScrollExtent > 0;
    if (overflows != _overflows) setState(() => _overflows = overflows);
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: Semantics(
          hint: _overflows ? SkUiStrings.of(context).scrollForMore : null,
          // V neobmedzenej vyske sa velkost rovna obsahu (bez scrollu).
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: widget.children,
            ),
          ),
        ),
      );
}
