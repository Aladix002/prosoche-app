import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/library/library.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/ui/ui.dart';

// Widgety Library (F-01) zo standardnych Material/Sk prvkov. D-01 ich moze
// preskinovat (SkReaderText, SkReaderHeading, SkReadingProgress,
// docs/DESIGN.md 6.2, 7.3).

/// Meno autora nad jeho dielami (eyebrow, terakota).
class AuthorHeading extends StatelessWidget {
  const AuthorHeading({required this.name, this.lifespan, super.key});

  final String name;
  final String? lifespan;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space16,
        SkSpace.space16,
        SkSpace.space4,
      ),
      child: Semantics(
        header: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: name.toUpperCase(),
                style: sk.text.labelMedium!.copyWith(
                  color: sk.colors.accentText,
                  letterSpacing: 1.4,
                ),
              ),
              if (lifespan case final l? when l.isNotEmpty)
                TextSpan(
                  text: '  $l',
                  style: sk.text.bodySmall!.copyWith(
                    color: sk.colors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "12 books · Translated by George Long (1862)" / "52 sections · ...".
String workSubtitle(BuildContext context, LibraryWork w) {
  final l10n = context.l10n;
  final size = w.bookCount > 0
      ? l10n.libraryBooks(w.bookCount)
      : l10n.librarySections(w.sectionCount);
  final year = w.editionYear;
  final tr = year == null
      ? l10n.cardTranslatedBy(w.translator)
      : l10n.cardTranslatedByYear(w.translator, year);
  return '$size · $tr';
}

/// Riadok diela v zozname Library.
class WorkTile extends StatelessWidget {
  const WorkTile({
    required this.work,
    required this.onTap,
    this.position,
    super.key,
  });

  final LibraryWork work;
  final ReadingPosition? position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final pos = position;
    return ListTile(
      key: ValueKey('work:${work.id}'),
      minTileHeight: SkSpace.minTouchTarget,
      title: Text(work.title, style: sk.text.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workSubtitle(context, work),
            style: sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary),
          ),
          if (pos != null)
            Text(
              l10n.libraryContinueAt(
                displayReference(work.shortRef, refOfSection(pos.sectionKey)),
              ),
              style: sk.text.bodySmall!.copyWith(color: sk.colors.primary),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// `section.ref` z kluca (`meditations.2.1` -> `2.1`); stabilne kluce
/// kontraktu maju ref za prvou bodkou.
String refOfSection(String sectionKey) {
  final i = sectionKey.indexOf('.');
  return i < 0 ? '' : sectionKey.substring(i + 1);
}

/// "Continue reading: Meditations 2.1" (Library aj Today).
class ContinueReadingTile extends StatelessWidget {
  const ContinueReadingTile({
    required this.work,
    required this.position,
    super.key,
  });

  final LibraryWork work;
  final ReadingPosition position;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final reference = displayReference(
      work.shortRef,
      refOfSection(position.sectionKey),
    );
    return Material(
      color: sk.colors.surface,
      borderRadius: BorderRadius.circular(SkRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('library:continue'),
        onTap: () => unawaited(
          openReader(
            context,
            workId: position.workId,
            section: position.sectionKey,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: sk.colors.primary,
                ),
              ),
              const SizedBox(width: SkSpace.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.todayCtaKeepReading, style: sk.text.titleMedium),
                    Text(
                      // "Meditations 4.24"; nazov z prekladu len ak sa
                      // lisi ("To Marcia, On Consolation" · "To Marcia 10").
                      work.title == work.shortRef
                          ? reference
                          : '${work.title} \u00B7 $reference',
                      style: sk.text.bodyMedium!.copyWith(
                        color: sk.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uryvok vysledku vyhladavania so zvyraznenymi slovami.
class SnippetText extends StatelessWidget {
  const SnippetText(this.snippet, {super.key});

  final String snippet;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final base = sk.text.bodyMedium!;
    return Text.rich(
      TextSpan(
        children: [
          for (final (text, hit) in snippetParts(snippet))
            TextSpan(
              text: text,
              style: hit
                  ? base.copyWith(
                      fontWeight: FontWeight.w600,
                      backgroundColor: sk.colors.primaryContainer,
                      color: sk.colors.onPrimaryContainer,
                    )
                  : base,
            ),
        ],
      ),
    );
  }
}
