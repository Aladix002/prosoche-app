import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/ui/ui.dart';

/// Odstavec textu s rozsahom zvyraznenia `[start, end)` v jeho suradniciach.
typedef ReaderParagraph = ({String text, int? start, int? end});

/// Rozdeli text sekcie na odstavce (presne `\n\n`, kontrakt kap. 4)
/// a vyznaci v nich vyskyt [highlight] (citat karty je doslovny podretazec
/// sekcie, kontrakt kap. 6). Uryvok moze prechadzat cez viac odstavcov.
List<ReaderParagraph> readerParagraphs(String text, String? highlight) {
  final at = highlight == null || highlight.isEmpty
      ? -1
      : text.indexOf(highlight);
  final hlEnd = at < 0 ? -1 : at + highlight!.length;
  final out = <ReaderParagraph>[];
  var offset = 0;
  for (final p in text.split('\n\n')) {
    final pStart = offset;
    final pEnd = offset + p.length;
    offset = pEnd + 2;
    if (p.trim().isEmpty) continue;
    if (at < 0 || hlEnd <= pStart || at >= pEnd) {
      out.add((text: p, start: null, end: null));
    } else {
      out.add((
        text: p,
        start: (at > pStart ? at : pStart) - pStart,
        end: (hlEnd < pEnd ? hlEnd : pEnd) - pStart,
      ));
    }
  }
  return out;
}

/// Jedna sekcia v citacke: nadpis knihy (pri prvej sekcii knihy),
/// referencia a nadpis kapitoly, odstavce (vyberatelne) a atribucia
/// prekladu. Bez motivu pod textom (docs/DESIGN.md 5.3).
class ReaderPage extends StatelessWidget {
  const ReaderPage({
    required this.section,
    required this.work,
    this.bookTitle,
    this.highlight,
    this.targeted = false,
    super.key,
  });

  final LibrarySection section;
  final LibraryWork work;
  final String? bookTitle;

  /// Text, ktory sa zvyrazni (citat z karty).
  final String? highlight;

  /// Sekcia je cielom navigacie (karta, vyhladavanie).
  final bool targeted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final style = sk.type.translationReader.copyWith(color: sk.colors.lead);
    final marked = style.copyWith(
      backgroundColor: sk.colors.primaryContainer,
      color: sk.colors.onPrimaryContainer,
    );
    final paragraphs = readerParagraphs(section.text, highlight);
    final year = work.editionYear;
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SkSpace.space24,
          SkSpace.space16,
          SkSpace.space24,
          SkSpace.space32,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bookTitle case final b?) ...[
                    Semantics(
                      header: true,
                      child: Text(b, style: sk.text.headlineSmall),
                    ),
                    const SizedBox(height: SkSpace.space24),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      section.reference,
                      style: sk.text.titleMedium!.copyWith(
                        color: targeted
                            ? sk.colors.primary
                            : sk.colors.accentText,
                      ),
                    ),
                  ),
                  if (section.title case final t?) ...[
                    const SizedBox(height: SkSpace.space4),
                    Text(t, style: sk.text.titleLarge),
                  ],
                  const SizedBox(height: SkSpace.space16),
                  for (final p in paragraphs) ...[
                    Text.rich(
                      p.start == null
                          ? TextSpan(text: p.text, style: style)
                          : TextSpan(
                              style: style,
                              children: [
                                TextSpan(text: p.text.substring(0, p.start)),
                                TextSpan(
                                  text: p.text.substring(p.start!, p.end),
                                  style: marked,
                                ),
                                TextSpan(text: p.text.substring(p.end!)),
                              ],
                            ),
                    ),
                    const SizedBox(height: SkSpace.space16),
                  ],
                  const SizedBox(height: SkSpace.space8),
                  Text(
                    [
                      work.author,
                      if (year == null)
                        l10n.cardTranslatedBy(work.translator)
                      else
                        l10n.cardTranslatedByYear(work.translator, year),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: sk.text.bodySmall!.copyWith(
                      color: sk.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Riadok zalozky alebo vysledku: referencia a nahlad.
class SectionRow extends StatelessWidget {
  const SectionRow({
    required this.reference,
    required this.preview,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final String reference;
  final Widget preview;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: SkSpace.minTouchTarget,
    title: Text(reference, style: context.sk.text.titleSmall),
    subtitle: preview,
    trailing: trailing,
    onTap: onTap,
  );
}
