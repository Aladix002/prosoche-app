import 'package:meta/meta.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/catalog/content_rules.dart';
import 'package:prosoche/domain/common/common.dart';

/// Prekladatel a rok vydania prekladu (atribucia na karte a obrazku,
/// "Translated by George Long").
@immutable
final class Translation {
  const Translation({required this.translator, this.year});

  final String translator;
  final int? year;

  @override
  bool operator ==(Object other) =>
      other is Translation &&
      other.translator == translator &&
      other.year == year;

  @override
  int get hashCode => Object.hash(translator, year);
}

/// Obsah karty na vykreslenie. Texty su doslovne z content.db v1
/// (kontrakt kap. 6); appka ich nemeni.
@immutable
sealed class CardContent {
  const CardContent(this.id);

  final CardId id;

  /// Zobrazovana referencia (`card.ref`, napr. "Meditations 2.1"), ak je.
  String? get reference => null;

  /// Suvisiaca sekcia v Library ("Read in context"), ak je.
  String? get sectionKey => null;

  /// Text, ktory sa zdiela a kopiruje.
  String? get shareText => null;
}

/// Uvodna karta dna (texty z ARB).
final class IntroContent extends CardContent {
  const IntroContent(IntroCardId super.id, {required this.date});

  final LocalDate date;
}

/// Citat (`quote`) alebo uryvok (`passage`): doslovny podretazec sekcie
/// diela s referenciou a prekladatelom.
final class QuoteContent extends CardContent {
  const QuoteContent(
    ContentCardId super.id, {
    required this.text,
    required this.author,
    required this.work,
    required this.sourceId,
    this.ref,
    this.workId,
    this.sectionKey,
    this.translation,
  });

  final String text;

  /// Meno autora, napr. "Marcus Aurelius".
  final String author;

  /// `work.short_ref`, napr. "Meditations".
  final String work;

  /// Kniha a sekcia, napr. `2.1` (`section.ref`).
  final String? ref;
  final String sourceId;
  final String? workId;

  @override
  final String? sectionKey;

  final Translation? translation;

  bool get isPassage => id.type == CardType.passage;

  /// "Meditations 2.1".
  @override
  String get reference => ref == null ? work : '$work $ref';

  @override
  String get shareText => text;
}

/// Cvicenie (`practice`): nadpis, kratky popis a postup (odstavce).
final class PracticeContent extends CardContent {
  const PracticeContent(
    ContentCardId super.id, {
    required this.title,
    required this.text,
    this.subtitle,
    this.ref,
    this.sectionKey,
    this.tags = const [],
  });

  final String title;
  final String? subtitle;
  final String text;
  final String? ref;
  final List<String> tags;

  @override
  final String? sectionKey;

  @override
  String? get reference => ref;

  /// Odstavce postupu (oddelene `\n\n`).
  List<String> get steps => paragraphs(text);

  @override
  String get shareText => '$title\n\n$text';
}

/// Otazka na zamyslenie (`prompt`).
final class PromptContent extends CardContent {
  const PromptContent(
    ContentCardId super.id, {
    required this.text,
    this.ref,
    this.sectionKey,
    this.tags = const [],
  });

  final String text;
  final String? ref;
  final List<String> tags;

  @override
  final String? sectionKey;

  @override
  String? get reference => ref;

  @override
  String get shareText => text;
}

/// Pojem (`concept`): nadpis, povodny termin s vyznamom a vysvetlenie.
final class ConceptContent extends CardContent {
  const ConceptContent(
    ContentCardId super.id, {
    required this.title,
    required this.text,
    this.subtitle,
    this.ref,
    this.sectionKey,
  });

  final String title;

  /// Napr. "prosoche - attention".
  final String? subtitle;
  final String text;
  final String? ref;

  @override
  final String? sectionKey;

  @override
  String? get reference => ref;

  @override
  String get shareText => '$title\n\n$text';
}

/// Uvod k autorovi (`author`).
final class AuthorContent extends CardContent {
  const AuthorContent(
    ContentCardId super.id, {
    required this.name,
    required this.text,
    this.authorId,
    this.lifespan,
    this.firstWorkId,
    this.firstWorkTitle,
  });

  final String name;
  final String text;
  final String? authorId;

  /// Napr. "AD 121-180".
  final String? lifespan;

  /// Prve dielo autora v Library ("Read Meditations").
  final String? firstWorkId;
  final String? firstWorkTitle;

  @override
  String get shareText => '$name\n\n$text';
}

/// Odstavce textu z content.db (oddelene presne `\n\n`, kontrakt kap. 4).
List<String> paragraphs(String text) => [
  for (final p in text.split('\n\n'))
    if (p.trim().isNotEmpty) p.trim(),
];

/// Obsah kariet dennej sady.
abstract interface class CardContentRepository {
  /// Obsah karty v jazyku [lang]; null = obsah v content.db chyba (feed ju
  /// preskoci cez `DailySetRepository.markSkipped`). `done` tu nie je
  /// (UI karta).
  Future<CardContent?> load(CardId id, {required String lang});
}

/// [CardContentRepository] nad content.db v1 ([ContentCatalog.db]).
class ContentCardRepository implements CardContentRepository {
  ContentCardRepository({required this._catalog});

  final ContentCatalog _catalog;

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    switch (id) {
      case IntroCardId(:final date):
        return IntroContent(id, date: date);
      case DoneCardId():
        return null;
      case final ContentCardId cid:
        final db = await _catalog.db;
        final row = await db.cardDao.card(cid.format());
        if (row == null || row.type != cid.type.wire) return null;
        return await contentFromRow(db, cid, row);
    }
  }
}

/// Riadok `card` -> [CardContent] (doplni autora, dielo a prekladatela).
Future<CardContent?> contentFromRow(
  ContentDb db,
  ContentCardId id,
  CardRow row,
) async {
  final tags = stringList(row.tags);
  switch (id.type) {
    case CardType.quote || CardType.passage:
      final work = row.workId == null
          ? null
          : await db.libraryDao.workById(row.workId!);
      if (work == null) return null;
      final author = await _authorName(db, row.authorId ?? work.authorId);
      final source = await db.contentMetaDao.source(work.sourceId);
      final section = row.sectionKey == null
          ? null
          : await db.libraryDao.sectionByKey(row.sectionKey!);
      return QuoteContent(
        id,
        text: row.textContent,
        author: author ?? '',
        work: work.shortRef,
        ref: section?.ref ?? _locus(row.ref, work.shortRef),
        sourceId: work.sourceId,
        workId: work.id,
        sectionKey: row.sectionKey,
        translation: Translation(
          translator: work.translator,
          year: source?.editionYear,
        ),
      );
    case CardType.practice:
      return PracticeContent(
        id,
        title: row.title ?? '',
        subtitle: row.subtitle,
        text: row.textContent,
        ref: row.ref,
        sectionKey: row.sectionKey,
        tags: tags,
      );
    case CardType.prompt:
      return PromptContent(
        id,
        text: row.textContent,
        ref: row.ref,
        sectionKey: row.sectionKey,
        tags: tags,
      );
    case CardType.concept:
      return ConceptContent(
        id,
        title: row.title ?? '',
        subtitle: row.subtitle,
        text: row.textContent,
        ref: row.ref,
        sectionKey: row.sectionKey,
      );
    case CardType.author:
      final authorId = row.authorId;
      final works = [
        for (final w in await db.libraryDao.allWorks())
          if (w.authorId == authorId) w,
      ];
      final author = authorId == null
          ? null
          : (await db.libraryDao.allAuthors())
                .where((a) => a.id == authorId)
                .firstOrNull;
      return AuthorContent(
        id,
        name: row.title ?? author?.name ?? '',
        text: row.textContent,
        authorId: authorId,
        lifespan: author?.lifespan,
        firstWorkId: works.firstOrNull?.id,
        firstWorkTitle: works.firstOrNull?.title,
      );
    case CardType.intro || CardType.done:
      return null;
  }
}

Future<String?> _authorName(ContentDb db, String? id) async {
  if (id == null) return null;
  for (final a in await db.libraryDao.allAuthors()) {
    if (a.id == id) return a.name;
  }
  return null;
}

/// `card.ref` "On Anger 3.36" -> "3.36" (bez nazvu diela).
String? _locus(String? ref, String shortRef) {
  if (ref == null) return null;
  return ref.startsWith('$shortRef ')
      ? ref.substring(shortRef.length + 1)
      : ref;
}
