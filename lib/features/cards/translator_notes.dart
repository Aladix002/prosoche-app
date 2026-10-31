import 'package:flutter/material.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/features/cards/card_parts.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Znacka poznamky prekladatela QuranEnc v texte prekladu, napr. `[2]`.
final RegExp translatorNoteMarker = RegExp(r'\[(\d+)\]');

/// Riadok poznamky v `translation.footnotes`: `[2]- text` alebo `[2] text`.
final RegExp _noteLine = RegExp(r'^\s*\[(\d+)\]\s*-?\s*');

/// Poznamky prekladatela z `translation.footnotes` (rovnaky zdroj ako
/// "Translator's notes" v citacke F-04) podla cisla znacky. Riadok bez
/// znacky pokracuje predchadzajucu poznamku. Text poznamky je doslovny.
Map<int, String> parseTranslatorNotes(String? footnotes) {
  final out = <int, String>{};
  if (footnotes == null || footnotes.trim().isEmpty) return out;
  int? current;
  for (final line in footnotes.split('\n')) {
    final m = _noteLine.firstMatch(line);
    if (m != null) {
      current = int.parse(m[1]!);
      out[current] = line.substring(m.end).trim();
    } else if (current != null && line.trim().isNotEmpty) {
      out[current] = '${out[current]}\n${line.trim()}';
    }
  }
  return out;
}

/// Cast textu prekladu: obycajny text alebo znacka `[n]` s poznamkou.
typedef TranslationPart = ({String text, int? note});

/// Rozdeli [text] na casti; znacka bez poznamky v [notes] ostane textom.
/// Spojenie vsetkych `text` je vzdy povodny [text] (podmienky QuranEnc:
/// preklad sa nemeni, docs/09 2.2).
List<TranslationPart> splitTranslation(String text, Map<int, String> notes) {
  final parts = <TranslationPart>[];
  var start = 0;
  var plain = StringBuffer();
  for (final m in translatorNoteMarker.allMatches(text)) {
    final n = int.parse(m[1]!);
    if (!notes.containsKey(n)) continue;
    plain.write(text.substring(start, m.start));
    if (plain.isNotEmpty) parts.add((text: plain.toString(), note: null));
    plain = StringBuffer();
    parts.add((text: m[0]!, note: n));
    start = m.end;
  }
  plain.write(text.substring(start));
  if (plain.isNotEmpty) parts.add((text: plain.toString(), note: null));
  return parts;
}

/// Cisla poznamok z [notes], na ktore v [text] ukazuje aspon jedna znacka.
Set<int> referencedTranslatorNotes(String text, Map<int, String> notes) => {
  for (final m in translatorNoteMarker.allMatches(text))
    if (notes.containsKey(int.parse(m[1]!))) int.parse(m[1]!),
};

/// Preklad versa so znackami poznamok ako tapnutelny horny index (BF-01).
/// Znaky textu ostavaju bez zmeny (aj `(1)` na zaciatku), meni sa len styl
/// znacky. Bez poznamok vrati null (karta pouzije obycajny text).
///
/// [interactive] = false (nahlad v Moja cesta, BF-02): znacka je len horny
/// index bez tapu a mimo stromu pristupnosti.
InlineSpan? translationWithNotes(
  BuildContext context, {
  required String text,
  required String? footnotes,
  required String lang,
  TextStyle? style,
  bool interactive = true,
}) {
  final notes = parseTranslatorNotes(footnotes);
  if (notes.isEmpty) return null;
  final parts = splitTranslation(text, notes);
  if (parts.every((p) => p.note == null)) return null;
  return TextSpan(
    children: [
      for (final p in parts)
        if (p.note case final n?)
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: TranslatorNoteMarker(
              marker: p.text,
              number: n,
              note: notes[n]!,
              lang: lang,
              style: style,
              interactive: interactive,
            ),
          )
        else
          TextSpan(text: p.text),
    ],
  );
}

/// Znacka `[n]` ako horny index; tap otvori sheet s poznamkou.
class TranslatorNoteMarker extends StatelessWidget {
  const TranslatorNoteMarker({
    required this.marker,
    required this.number,
    required this.note,
    required this.lang,
    this.style,
    this.interactive = true,
    super.key,
  });

  /// Doslovna znacka z textu prekladu, napr. `[2]`.
  final String marker;
  final int number;
  final String note;
  final String lang;
  final TextStyle? style;

  /// false = len horny index (nahlad), bez tapu a bez Semantics.
  final bool interactive;

  Future<void> _open(BuildContext context) => showSkInfoSheet<void>(
    context,
    title: context.l10n.cardTranslatorNoteTitle,
    closeLabel: SkUiStrings.of(context).cancel,
    child: Directionality(
      textDirection: textDirectionForLanguage(lang),
      child: Text(note, locale: Locale(lang)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final base = style ?? DefaultTextStyle.of(context).style;
    final size = (base.fontSize ?? 16) * 0.65;
    final label = Text(
      marker,
      style: base.copyWith(
        fontSize: size,
        height: 1,
        color: sk.colors.accentText,
        fontWeight: FontWeight.w600,
      ),
    );
    if (!interactive) {
      return ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
          child: label,
        ),
      );
    }
    return Semantics(
      button: true,
      label: context.l10n.cardTranslatorNoteA11y(
        localizeDigits('$number', context.formats.digits),
      ),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Padding(
          // Vacsia plocha pre tap bez posunu textu v riadku.
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
          child: label,
        ),
      ),
    );
  }
}
