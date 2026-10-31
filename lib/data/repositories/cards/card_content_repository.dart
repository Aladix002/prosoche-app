import 'package:meta/meta.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/domain/common/common.dart';

/// Obsah karty na vykreslenie. Texty su doslovne z content.db.
///
/// S-01 pozna len [IntroContent] a [QuoteContent]. F-01 prida podtriedy pre
/// `passage`, `practice`, `prompt`, `concept` a `author` (a ich vykreslenie
/// v `lib/features/cards/types/`).
@immutable
sealed class CardContent {
  const CardContent(this.id);

  final CardId id;
}

/// Uvodna karta dna (texty z ARB).
final class IntroContent extends CardContent {
  const IntroContent(IntroCardId super.id, {required this.date});

  final LocalDate date;
}

/// Kratky citat s referenciou na dielo.
final class QuoteContent extends CardContent {
  const QuoteContent(
    ContentCardId super.id, {
    required this.text,
    required this.author,
    required this.work,
    required this.sourceId,
    this.ref,
  });

  final String text;
  final String author;
  final String work;

  /// Kniha a sekcia, napr. `2.1`.
  final String? ref;
  final String sourceId;

  /// "Meditations 2.1".
  String get reference => ref == null ? work : '$work $ref';
}

/// Obsah kariet dennej sady (F-02).
abstract interface class CardContentRepository {
  /// Obsah karty v jazyku [lang]; null = obsah v content.db chyba (feed ju
  /// preskoci cez `DailySetRepository.markSkipped`). `done` tu nie je
  /// (UI karta).
  Future<CardContent?> load(CardId id, {required String lang});
}

/// [CardContentRepository] nad content.db ([ContentCatalog.db]).
class ContentCardRepository implements CardContentRepository {
  ContentCardRepository({required this._catalog});

  final ContentCatalog _catalog;

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    switch (id) {
      case IntroCardId(:final date):
        return IntroContent(id, date: date);
      case ContentCardId(type: CardType.quote, :final key):
        final q = await (await _catalog.db).curatedDao.quote(key);
        if (q == null) return null;
        return QuoteContent(
          id,
          text: q.textContent,
          author: q.author,
          work: q.work,
          ref: q.ref,
          sourceId: q.sourceId,
        );
      case ContentCardId() || DoneCardId():
        // Dalsie typy dodá F-01.
        return null;
    }
  }
}
