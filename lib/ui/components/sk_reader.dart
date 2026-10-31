import 'package:flutter/material.dart';
import 'package:prosoche/ui/motif/sk_greek_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Velkost pisma citacky (Nastavenia > Display > Reading size,
/// docs/DESIGN.md 3.3). Nasobi sa so systemovym `TextScaler`.
enum SkReaderSize {
  s(0.9),
  m(1),
  l(1.15),
  xl(1.3);

  SkReaderSize(this.factor);

  final double factor;
}

/// Max. sirka riadku citacky (~36 em pri velkosti M).
const double skReaderMaxWidth = 600;

/// Jeden odstavec dlheho textu v citacke (docs/DESIGN.md 3.6). Cislo
/// sekcie je na zaciatku odstavca (nie na okraji, aby sa zmestilo aj pri
/// textScale 2.0). Vyber textu zabezpeci rodic (`SelectionArea`).
class SkReaderText extends StatelessWidget {
  const SkReaderText({
    required this.text,
    this.sectionNumber,
    this.highlighted = false,
    this.size = SkReaderSize.m,
    this.semanticsPrefix,
    super.key,
  });

  final String text;

  /// Napr. "1" (Meditations 2.1).
  final String? sectionNumber;

  /// Zalozka alebo ciel vyhladavania: tonalne pozadie, nie farba textu.
  final bool highlighted;
  final SkReaderSize size;

  /// Pre screen reader, napr. "Section 1"; default cislo sekcie.
  final String? semanticsPrefix;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final base = sk.type.reader;
    final style = base.copyWith(fontSize: base.fontSize! * size.factor);
    final number = sectionNumber;
    final paragraph = Text.rich(
      TextSpan(
        children: [
          if (number != null)
            TextSpan(
              text: '$number ',
              style: sk.type.numeral.copyWith(
                fontSize: sk.type.numeral.fontSize! * size.factor,
              ),
              semanticsLabel: semanticsPrefix ?? number,
            ),
          TextSpan(text: text),
        ],
      ),
      style: style,
      textAlign: TextAlign.start,
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: SkSpace.space16 * size.factor,
      ),
      child: highlighted
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(SkRadius.xs),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SkSpace.space8,
                  vertical: SkSpace.space4,
                ),
                child: paragraph,
              ),
            )
          : paragraph,
    );
  }
}

/// Nadpis knihy v citacke ("Book II") s rimsou nad nim.
class SkReaderHeading extends StatelessWidget {
  const SkReaderHeading({required this.title, this.subtitle, super.key});

  final String title;

  /// Napr. "Among the Quadi, at the Granua".
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: SkSpace.space32,
        bottom: SkSpace.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkCornice(),
          const SizedBox(height: SkSpace.space16),
          Semantics(
            header: true,
            child: Text(title, style: sk.text.headlineSmall),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: SkSpace.space4),
            Text(subtitle!, style: sk.type.attribution),
          ],
        ],
      ),
    );
  }
}

/// Pozicia citania: tenka linka 2 dp (`primary` na `outline`), bez
/// percent v texte; Semantics nesie hodnotu.
class SkReadingProgress extends StatelessWidget {
  const SkReadingProgress({
    required this.value,
    required this.label,
    this.valueLabel,
    super.key,
  });

  /// 0..1.
  final double value;

  /// Napr. "Reading position".
  final String label;

  /// Napr. "40 percent"; default "{n} %".
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: valueLabel ?? '${(v * 100).round()} %',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 2,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.outline)),
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: box.maxWidth * v,
                  child: ColoredBox(color: c.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
