import 'package:flutter/material.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/features/quran/quran_format.dart';
import 'package:sakina/ui/ui.dart';

/// Riadok sury v zozname (docs/02 A5.1): cislo, nazov, preklad nazvu,
/// miesto zjavenia, pocet versov, arabsky nazov a progres (len ak > 0).
class SurahTile extends StatelessWidget {
  const SurahTile({
    required this.surah,
    required this.readCount,
    required this.onTap,
    super.key,
  });

  final SurahInfo surah;
  final int readCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final secondary = sk.text.bodyMedium!.copyWith(
      color: sk.colors.textSecondary,
    );
    final progress = surah.ayahCount == 0
        ? 0.0
        : (readCount / surah.ayahCount).clamp(0.0, 1.0);
    final percent = context.quranFormats.number((progress * 100).floor());
    final meta =
        '${context.revelationLabel(surah)} · '
        '${l10n.quranAyahCount(surah.ayahCount)}';
    final label = [
      l10n.quranSurahNumber(context.quranNumber(surah.id)),
      surah.nameTranslit,
      ?surah.nameMeaning,
      meta,
      if (readCount > 0) l10n.quranProgressRead('$percent %'),
    ].join(', ');

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
                vertical: SkSpace.space12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      context.quranNumber(surah.id),
                      style: sk.text.titleMedium!.copyWith(
                        color: sk.colors.accentText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(surah.nameTranslit, style: sk.text.titleMedium),
                        if (surah.nameMeaning case final meaning?)
                          Text(meaning, style: secondary),
                        Text(meta, style: secondary),
                        if (readCount > 0) ...[
                          const SizedBox(height: SkSpace.space4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    SkRadius.full,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: SkSpace.space8),
                              Text('$percent %', style: secondary),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: SkSpace.space8),
                  // Nazov sury je arabcina mimo textu Koranu (Noto Naskh).
                  Flexible(
                    child: SkArabicText.text(
                      surah.nameAr,
                      textAlign: TextAlign.end,
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
