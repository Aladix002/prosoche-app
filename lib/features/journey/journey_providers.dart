import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';

/// Ulozene karty, najnovsie prve; [CardType] null = vsetky (A8.3).
final StreamProviderFamily<List<SavedCard>, CardType?> savedCardsProvider =
    StreamProvider.family<List<SavedCard>, CardType?>(
      (ref, type) =>
          ref.watch(cardActionsRepositoryProvider).watchSaved(type: type),
      name: 'savedCardsProvider',
    );

/// Ulozena sada dna bez generovania (detail dna A8.2); null = sada nie je.
final StreamProviderFamily<DailySetState?, LocalDate> journeyDaySetProvider =
    StreamProvider.family<DailySetState?, LocalDate>(
      (ref, date) => ref.watch(dailySetRepositoryProvider).watch(date),
      name: 'journeyDaySetProvider',
    );
