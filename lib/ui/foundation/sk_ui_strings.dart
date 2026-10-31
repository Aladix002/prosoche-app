import 'package:flutter/widgets.dart';

/// Genericke UI texty komponentov (nie obsah kariet).
///
/// Komponenty v `lib/ui` nezavisia od `AppLocalizations`; integracia vlozi
/// [SkUiStringsScope] s textami z ARB. Bez scope sa pouzije EN fallback
/// (PLAN 2.1: UI texty smu mat fallback na EN).
@immutable
class SkUiStrings {
  const SkUiStrings({
    required this.loading,
    required this.stillLoading,
    required this.tryAgain,
    required this.dismiss,
    required this.undo,
    required this.cancel,
    required this.done,
    required this.skippedForToday,
    required this.iDidIt,
    required this.freeReading,
    required this.dailyCards,
    required this.scrollForMore,
    required this.holdToConfirm,
    required this.contentUnavailableTitle,
    required this.contentUnavailableBody,
    required this.progressOf,
    this.translatedBy = _translatedBy,
  });

  static String _of(int n, int total) => '$n of $total';

  static String _translatedBy(String translator, int? year) =>
      year == null ? 'tr. $translator' : 'tr. $translator, $year';

  static const fallbackEn = SkUiStrings(
    loading: 'Loading',
    stillLoading: 'Still loading…',
    tryAgain: 'Try again',
    dismiss: 'Dismiss',
    undo: 'Undo',
    cancel: 'Cancel',
    done: 'Done',
    skippedForToday: 'Skipped for today',
    iDidIt: 'I did it',
    freeReading: 'Free reading',
    dailyCards: 'Daily cards',
    scrollForMore: 'Scroll for more',
    holdToConfirm: 'Press and hold to confirm',
    contentUnavailableTitle: 'This text can’t be shown',
    contentUnavailableBody:
        'Prosoche couldn’t verify this content. Please try again later.',
    progressOf: _of,
  );

  final String loading;
  final String stillLoading;
  final String tryAgain;
  final String dismiss;
  final String undo;
  final String cancel;
  final String done;
  final String skippedForToday;
  final String iDidIt;
  final String freeReading;
  final String dailyCards;
  final String scrollForMore;
  final String holdToConfirm;
  final String contentUnavailableTitle;
  final String contentUnavailableBody;

  /// "5 of 12" (cislice lokalizuje volajuci cez U-02 formatovanie).
  final String Function(int n, int total) progressOf;

  /// "tr. George Long, 1862" (docs/DESIGN.md 3.5).
  final String Function(String translator, int? year) translatedBy;

  static SkUiStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkUiStringsScope>()?.strings ??
      fallbackEn;
}

/// Poskytne [SkUiStrings] podstromu (integracia: z `AppLocalizations`).
class SkUiStringsScope extends InheritedWidget {
  const SkUiStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final SkUiStrings strings;

  @override
  bool updateShouldNotify(SkUiStringsScope oldWidget) =>
      oldWidget.strings != strings;
}
