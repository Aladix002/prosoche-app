import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide Bidi;
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Kde sa karta vykresluje (docs/02 B0.2).
enum CardSurface {
  /// Denna sada (A3): zapisuje `seen`, plna akcna lista.
  feed(CardContext.feed),

  /// Brana (A4): bez odkazov mimo branu.
  gate(CardContext.gate),

  /// Ulozene a prehlad dna (A8.2, A8.3): bez posunu progresu.
  saved(CardContext.saved);

  CardSurface(this.context);

  /// Hodnota `card_event.context` pre akcie na karte.
  final CardContext context;

  bool get showReadInContext => this != gate;
}

/// Akcie v hlavicke karty (ulozit, zdielat, dalsie moznosti). Null
/// callback = akcia sa nezobrazi (napr. typ, ktory sa neda ulozit, 0.2).
@immutable
class CardActions {
  const CardActions({
    this.saved = false,
    this.onToggleSave,
    this.onShare,
    this.onMore,
  });

  static const none = CardActions();

  final bool saved;
  final VoidCallback? onToggleSave;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  List<Widget> build(BuildContext context) {
    final l10n = context.l10n;
    return [
      if (onToggleSave != null)
        SkIconButton(
          icon: Icons.bookmark_border,
          selectedIcon: Icons.bookmark,
          selected: saved,
          tooltip: saved ? l10n.cardUnsave : l10n.cardSave,
          onPressed: onToggleSave,
        ),
      if (onShare != null)
        SkIconButton(
          icon: Icons.ios_share,
          tooltip: l10n.cardShare,
          onPressed: onShare,
        ),
      if (onMore != null)
        SkIconButton(
          icon: Icons.more_vert,
          tooltip: l10n.cardMore,
          onPressed: onMore,
        ),
    ];
  }
}

/// Text karty (docs/02 B0.6, docs/03 7.3): text v jazyku obsahu; pri
/// fallbacku na iny jazyk so stitkom; bez textu nenapadna poznamka. Smer
/// textu podla jazyka textu, nie UI. [textSpan] nahradi obycajny text.
class CardTranslation extends StatelessWidget {
  const CardTranslation({
    required this.text,
    this.lang,
    this.isFallback = false,
    this.style,
    this.textSpan,
    super.key,
  });

  final String? text;
  final String? lang;
  final bool isFallback;
  final TextStyle? style;
  final InlineSpan? textSpan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final value = text;
    if (value == null || value.isEmpty) {
      return Text(
        l10n.cardTranslationNotYetAvailable,
        style: sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary),
      );
    }
    final span = textSpan;
    final body = Directionality(
      textDirection: lang == null
          ? Directionality.of(context)
          : textDirectionForLanguage(lang!),
      child: span == null
          ? Text(value, style: style)
          : Text.rich(span, style: style),
    );
    if (!isFallback) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.cardFallbackA11y,
          child: ExcludeSemantics(child: SkTag(label: l10n.cardFallbackTag)),
        ),
        const SizedBox(height: SkSpace.space8),
        body,
      ],
    );
  }
}

/// Sekundarny riadok karty (zdroj, stupen, poznamka).
class CardMeta extends StatelessWidget {
  const CardMeta(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: SkSpace.space8),
    child: Text(
      text,
      style: context.sk.text.bodyMedium!.copyWith(
        color: context.sk.colors.textSecondary,
      ),
    ),
  );
}

/// Nenapadny riadok so zdrojom textu a jeho verziou (atribucia licencie,
/// docs/09), pod textom karty.
class CardSourceNote extends StatelessWidget {
  const CardSourceNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: SkSpace.space8),
    child: Text(
      text,
      style: context.sk.text.bodySmall!.copyWith(
        color: context.sk.colors.textSecondary,
      ),
    ),
  );
}

/// Formaty pre karty a Dnes v jazyku UI (cislice podla U-02).
extension CardFormatsX on BuildContext {
  ProsocheFormats get formats => ProsocheFormats(Localizations.localeOf(this));

  /// Den v tyzdni, napr. "Thursday".
  String weekdayLabel(LocalDate date) => localizeDigits(
    DateFormat.EEEE(Localizations.localeOf(this).toString())
        .format(date.toLocalDateTime()),
    formats.digits,
  );

  /// Gregoriansky datum, napr. "29 October 2026".
  String longDateLabel(LocalDate date) => localizeDigits(
    DateFormat.yMMMMd(Localizations.localeOf(this).toString())
        .format(date.toLocalDateTime()),
    formats.digits,
  );
}

/// Double tap na karte bez ucasti v gesture arene: tlacidla na karte
/// reaguju hned (bez cakania na double-tap timeout, docs/02 B0.3 pozn.).
class CardDoubleTap extends StatefulWidget {
  const CardDoubleTap({required this.child, this.onDoubleTap, super.key});

  final Widget child;
  final VoidCallback? onDoubleTap;

  @override
  State<CardDoubleTap> createState() => _CardDoubleTapState();
}

class _CardDoubleTapState extends State<CardDoubleTap> {
  Offset? _downAt;
  Duration? _downTime;
  Offset? _lastUpAt;
  Duration? _lastUpTime;

  void _down(PointerDownEvent e) {
    _downAt = e.position;
    _downTime = e.timeStamp;
  }

  void _up(PointerUpEvent e) {
    final downAt = _downAt;
    final downTime = _downTime;
    _downAt = null;
    if (downAt == null || downTime == null) return;
    final isTap =
        (e.position - downAt).distance < kTouchSlop &&
        e.timeStamp - downTime < kLongPressTimeout;
    if (!isTap) {
      _lastUpTime = null;
      return;
    }
    final lastTime = _lastUpTime;
    final lastAt = _lastUpAt;
    if (lastTime != null &&
        lastAt != null &&
        e.timeStamp - lastTime <= kDoubleTapTimeout &&
        (e.position - lastAt).distance < kDoubleTapSlop) {
      _lastUpTime = null;
      widget.onDoubleTap?.call();
      return;
    }
    _lastUpTime = e.timeStamp;
    _lastUpAt = e.position;
  }

  @override
  Widget build(BuildContext context) => widget.onDoubleTap == null
      ? widget.child
      : Listener(
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: (_) => _downAt = null,
          child: widget.child,
        );
}
