/// Pravidla RTL lintu (docs/04 5.2, docs/01 8.6 a D13, PLAN_VYVOJA U-02).
enum SakinaRule {
  edgeInsetsLeftRight(
    'sakina_edge_insets_left_right',
    'EdgeInsets.only(left/right) -> EdgeInsetsDirectional.only(start/end)',
  ),
  alignmentLeftRight(
    'sakina_alignment_left_right',
    'Alignment.*Left/*Right -> AlignmentDirectional.*Start/*End',
  ),
  hardcodedTextDirection(
    'sakina_hardcoded_text_direction',
    'TextDirection.ltr natvrdo -> Directionality.of(context) alebo '
        'textDirectionForLanguage() z lib/ui/i18n',
  ),
  positionedLeftRight(
    'sakina_positioned_left_right',
    'Positioned(left/right) -> PositionedDirectional(start/end)',
  ),
  textAlignLeftRight(
    'sakina_text_align_left_right',
    'TextAlign.left/right -> TextAlign.start/end',
  ),
  borderRadiusLeftRight(
    'sakina_border_radius_left_right',
    'BorderRadius.only/horizontal(left/right) -> BorderRadiusDirectional',
  ),
  arabicTextOutsideSkArabicText(
    'sakina_arabic_text_outside_sk_arabic_text',
    'Arabsky text len cez SkArabicText (docs/01 D13)',
  );

  SakinaRule(this.code, this.message);

  /// Kod pre vystup a ignore komentar.
  final String code;

  /// Co pouzit namiesto.
  final String message;

  static SakinaRule? byCode(String code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Jedno porusenie pravidla.
final class LintViolation {
  const LintViolation({
    required this.rule,
    required this.path,
    required this.line,
    required this.column,
    required this.snippet,
  });

  final SakinaRule rule;
  final String path;

  /// 1-based.
  final int line;

  /// 1-based.
  final int column;
  final String snippet;

  @override
  String toString() =>
      '$path:$line:$column ${rule.code}: ${rule.message} [$snippet]';
}
