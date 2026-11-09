// Fake tyzdenneho prehladu (J-01). Obsah citatu je placeholder
// (PLAN_VYVOJA 5.5).
import 'package:prosoche/data/repositories/journey/week_repository.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';

/// Placeholder citat dlzky [weekQuoteMaxChars] (najhorsi pripad layoutu).
QuoteContent fakeWeekQuote({int length = weekQuoteMaxChars}) {
  const words = 'placeholder words of a short quote, ';
  final text = '[PLACEHOLDER] ${words * 8}'.substring(0, length).trimRight();
  return QuoteContent(
    ContentCardId.quote('q_week'),
    text: text,
    // Dlzka ako najdlhsia realna atribucia ("Seneca, On the Shortness
    // of Life 20").
    author: '[PH] author',
    work: '[PLACEHOLDER] work title',
    ref: '20',
    sourceId: 'fake',
    translation: const Translation(
      translator: '[PLACEHOLDER translator]',
      year: 1862,
    ),
  );
}

class FakeWeekRepository implements WeekRepository {
  FakeWeekRepository({this.activity = WeekActivity.empty, this.quoteContent});

  /// Aktivita, ktoru vrati [watch].
  WeekActivity activity;
  QuoteContent? quoteContent;

  /// Okna, ktore si obrazovka vyziadala.
  final windows = <WeekWindow>[];

  @override
  Stream<WeekActivity> watch(WeekWindow window) {
    windows.add(window);
    return Stream.value(activity);
  }

  @override
  Future<QuoteContent?> quote(LocalDate day, {int maxChars = 0}) async =>
      quoteContent;
}
