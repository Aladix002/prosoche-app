@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../helpers/golden/golden.dart';

/// Goldeny kazdeho typu karty (PLAN_VYVOJA F-02 DoD): EN x svetla/tmava
/// x textScale 1.0/1.5/2.0. Obsah je placeholder.
///
///   flutter test --update-goldens test/features/cards/cards_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  final date = LocalDate(2026, 10, 30);
  void noop() {}
  final actions = CardActions(onToggleSave: noop, onShare: noop, onMore: noop);

  /// Karta na celu stranku feedu (360 x 640).
  void cardGolden(String name, Widget Function(BuildContext context) build) {
    goldenAllLocales(
      'card $name',
      fileName: 'card_$name',
      theme: theme,
      textScales: cardTextScales,
      builder: (context) => SizedBox(
        width: 360,
        height: 640,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: build(context),
        ),
      ),
    );
  }

  cardGolden(
    'intro',
    (context) => IntroCard(
      content: IntroContent(IntroCardId(date), date: date),
      cardsCount: 12,
      questSlots: const [QuestSlot.read, QuestSlot.learn, QuestSlot.act],
      intention: '[PLACEHOLDER] intention',
    ),
  );

  cardGolden(
    'quote',
    (context) => QuoteCard(
      content: QuoteContent(
        ContentCardId.quote('q_0001'),
        text:
            '[PLACEHOLDER quote] A sample sentence that wraps over a few '
            'lines on the card and carries no meaning.',
        author: '[PLACEHOLDER] Author',
        work: '[PLACEHOLDER] Work',
        ref: '2.1',
        sourceId: 'fake',
        translation: const Translation(
          translator: '[PLACEHOLDER] Translator',
          year: 1862,
        ),
      ),
      actions: actions,
      onReadInContext: noop,
    ),
  );

  cardGolden(
    'passage',
    (context) => QuoteCard(
      content: QuoteContent(
        ContentCardId(CardType.passage, 'p1'),
        text:
            '[PLACEHOLDER passage] A longer sample paragraph that wraps '
            'over several lines and carries no meaning at all.\n\n'
            '[PLACEHOLDER] A second paragraph.',
        author: '[PLACEHOLDER] Author',
        work: '[PLACEHOLDER] Work',
        ref: '5',
        sourceId: 'fake',
      ),
      actions: actions,
    ),
  );

  cardGolden(
    'practice',
    (context) => PracticeCard(
      content: PracticeContent(
        ContentCardId(CardType.practice, 'x'),
        title: '[PLACEHOLDER] Practice',
        subtitle: '[PLACEHOLDER] subtitle',
        text: '[PLACEHOLDER] Step one.\n\n[PLACEHOLDER] Step two.',
        ref: '[PLACEHOLDER] Work 2.1',
        sectionKey: 'w.2.1',
      ),
      actions: actions,
      onOpen: noop,
    ),
  );

  cardGolden(
    'prompt',
    (context) => PromptCard(
      content: PromptContent(
        ContentCardId(CardType.prompt, 'x'),
        text: '[PLACEHOLDER] A question to reflect on?',
      ),
      actions: actions,
      onReflect: noop,
    ),
  );

  cardGolden(
    'concept',
    (context) => ConceptCard(
      content: ConceptContent(
        ContentCardId(CardType.concept, 'x'),
        title: '[PLACEHOLDER] Concept',
        subtitle: '[PLACEHOLDER] term - gloss',
        text: '[PLACEHOLDER] Explanation of the concept.',
      ),
      actions: actions,
    ),
  );

  cardGolden(
    'author',
    (context) => AuthorCard(
      content: AuthorContent(
        ContentCardId(CardType.author, 'x'),
        name: '[PLACEHOLDER] Author',
        lifespan: 'AD 1-2',
        text: '[PLACEHOLDER] A short introduction.',
        firstWorkId: 'w',
        firstWorkTitle: '[PLACEHOLDER] Work',
      ),
      actions: actions,
      onReadWork: noop,
    ),
  );

  cardGolden(
    'done',
    (context) => DoneCard(
      summary: DoneSummary(
        cards: 12,
        questsDone: 2,
        questsTotal: 3,
        openDeed: '[PLACEHOLDER] practice',
        streak: 6,
        countedFor: date,
      ),
      onBack: noop,
      onKeepReading: noop,
      onDeedDone: noop,
    ),
  );
}
