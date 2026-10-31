/// Golden a i18n harness (U-02). Pouzitie:
///
/// ```dart
/// goldenAllLocales(
///   'SkQuestItem',
///   fileName: 'sk_quest_item',
///   textScales: cardTextScales,
///   builder: (context) => const SkQuestItem(...),
/// );
/// ```
///
/// Aktualizacia obrazkov: `flutter test --update-goldens <subor>`.
library;

export 'golden_harness.dart';
export 'no_clipping.dart';
