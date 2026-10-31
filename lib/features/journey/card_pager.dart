import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/cards/cards.dart' show CardSurface, CardView;
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Otvori karty na celu obrazovku nad shellom (A8.2 "View cards", A8.3).
Future<void> openJourneyCards(
  BuildContext context, {
  required List<CardId> cards,
  required LocalDate date,
  int initialIndex = 0,
  int? cardsCount,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => JourneyCardPager(
      cards: cards,
      date: date,
      initialIndex: initialIndex,
      cardsCount: cardsCount,
    ),
  ),
);

/// Karty jedna po druhej (swipe do stran) cez renderer z B s
/// `context=saved`: bez zapisu `seen` a posunu progresu.
class JourneyCardPager extends StatefulWidget {
  const JourneyCardPager({
    required this.cards,
    required this.date,
    this.initialIndex = 0,
    this.cardsCount,
    super.key,
  });

  final List<CardId> cards;

  /// Den, ku ktoremu sa zapisu akcie na karte (ulozit, zdielat).
  final LocalDate date;
  final int initialIndex;

  /// N pre uvodnu kartu sady.
  final int? cardsCount;

  @override
  State<JourneyCardPager> createState() => _JourneyCardPagerState();
}

class _JourneyCardPagerState extends State<JourneyCardPager> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formats = ProsocheFormats(Localizations.localeOf(context));
    final total = widget.cards.length;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: SkIconButton(
          icon: Icons.close,
          tooltip: l10n.journeyClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Semantics(
          liveRegion: true,
          child: Text(
            l10n.journeyCardPosition(
              formats.number(_page + 1),
              formats.number(total),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: PageView.builder(
          controller: _controller,
          itemCount: total,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsetsDirectional.all(SkSpace.space16),
            child: CardView(
              cardId: widget.cards[i],
              date: widget.date,
              surface: CardSurface.saved,
              pos: i + 1,
              total: total,
              cardsCount: widget.cardsCount,
            ),
          ),
        ),
      ),
    );
  }
}
