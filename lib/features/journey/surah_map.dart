import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Percento precitanych versov [read] z [total], zaokruhlene nadol; aspon
/// 1, ked je precitany aspon 1 vers (0 % by zakrylo zaciatok).
int readPercent(int read, int total) {
  if (read <= 0 || total <= 0) return 0;
  if (read >= total) return 100;
  final p = read * 100 ~/ total;
  return p < 1 ? 1 : p;
}

/// Podiel precitanych versov celeho Koranu z `readCountsProvider`.
int quranReadPercent(Map<int, int> counts) =>
    readPercent(counts.values.fold(0, (a, b) => a + b), AyahId.totalAyahs);

/// Mapa 114 sur (A8.1): policko sa plni zdola podla podielu precitanych
/// versov (tvar, nie len farba); Semantics "Al-Baqarah, 43% read".
class SurahMap extends StatelessWidget {
  const SurahMap({
    required this.counts,
    required this.names,
    required this.onOpen,
    super.key,
  });

  /// Precitane versy podla sury.
  final Map<int, int> counts;

  /// Nazov sury (transliteracia) podla cisla; chybajuci = "Surah n".
  final Map<int, String> names;
  final ValueChanged<int> onOpen;

  /// Najmensia strana policka = dotykovy ciel (docs/01 8.4).
  static const double tile = SkSpace.minTouchTarget;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / tile).floor().clamp(1, 19);
      final side = constraints.maxWidth / columns;
      return Wrap(
        children: [
          for (var s = 1; s <= AyahId.surahCount; s++)
            SizedBox.square(
              dimension: side,
              child: _SurahTile(
                surah: s,
                name: names[s],
                percent: readPercent(counts[s] ?? 0, AyahId.ayahCount(s)),
                onTap: () => onOpen(s),
              ),
            ),
        ],
      );
    },
  );
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.name,
    required this.percent,
    required this.onTap,
  });

  final int surah;
  final String? name;
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.sk.colors;
    final formats = ProsocheFormats(Localizations.localeOf(context));
    final label = l10n.journeySurahProgress(
      name ?? l10n.journeySurahFallback(formats.number(surah)),
      formats.number(percent),
    );
    final full = percent >= 100;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SkRadius.xs),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SkSpace.space2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(SkRadius.xs),
              border: Border.all(
                color: full ? c.primary : c.outline,
                width: full ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SkRadius.xs),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (percent > 0)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        heightFactor: percent / 100,
                        child: ColoredBox(color: c.primaryContainer),
                      ),
                    ),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(
                          SkSpace.space2,
                        ),
                        child: Text(
                          formats.number(surah),
                          style: context.sk.text.labelSmall!.copyWith(
                            color: percent > 50
                                ? c.onPrimaryContainer
                                : c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
