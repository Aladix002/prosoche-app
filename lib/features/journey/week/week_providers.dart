import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/repositories/journey/week_repository.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Aktivita poslednych 7 dni (J-01). autoDispose: pri kazdom otvoreni
/// Journey sa nacita znova (zapisy brany z jej izolatu drift tejto
/// instancii nehlasi).
final StreamProvider<WeekActivity> weekActivityProvider =
    StreamProvider.autoDispose<WeekActivity>((ref) {
      final today = ref.watch(localDateProvider);
      return ref
          .watch(weekRepositoryProvider)
          .watch(WeekWindow.endingOn(today));
    }, name: 'weekActivityProvider');

/// Tyzdenny prehlad: aktivita + brana (edicia a zapnutie) + streak
/// (skryty v `simple_mode`). Lokalne, nikdy do analytiky.
final Provider<AsyncValue<WeekSummary>> weekSummaryProvider =
    Provider.autoDispose<AsyncValue<WeekSummary>>((ref) {
      final today = ref.watch(localDateProvider);
      final activity = ref.watch(weekActivityProvider);
      final gateFlag = ref.watch(featureFlagsProvider).gate;
      final blockerOn =
          ref.watch(settingOf(SettingsKeys.blockerEnabled)).value ?? false;
      final simple =
          ref.watch(settingOf(SettingsKeys.simpleMode)).value != false;
      final streak = ref.watch(streakProvider).value?.current;
      return activity.whenData(
        (a) => WeekSummary.compute(
          window: WeekWindow.endingOn(today),
          activity: a,
          gateAvailable: gateFlag && blockerOn,
          streak: simple ? null : streak,
        ),
      );
    }, name: 'weekSummaryProvider');

/// Citat tyzdna pre zdielany obrazok (nacita sa az pri zdielani).
final FutureProvider<QuoteContent?> weekQuoteProvider =
    FutureProvider.autoDispose<QuoteContent?>((ref) {
      final today = ref.watch(localDateProvider);
      return ref.watch(weekRepositoryProvider).quote(today);
    }, name: 'weekQuoteProvider');
