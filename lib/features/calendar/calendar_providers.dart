import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

/// Text eventu v jazyku obsahu; kalendar smie fallback na `en` (A9,
/// docs/03 7.3). Null = text chyba aj v `en` (event sa nezobrazi).
final FutureProviderFamily<EventText?, String> calendarEventTextProvider =
    FutureProvider.family<EventText?, String>((ref, eventId) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      return await ref
          .watch(calendarRepositoryProvider)
          .eventText(eventId, lang, allowEnFallback: true);
    }, name: 'calendarEventTextProvider');

/// Najblizsi event po hijri mesiaci `ym` (max 12 mesiacov dopredu) pre
/// prazdny mesiac (EMPTY-CAL-MONTH). Null = ziadny.
final FutureProviderFamily<({LocalDate date, String eventId})?, (int, int)>
nextCalendarEventProvider =
    FutureProvider.family<({LocalDate date, String eventId})?, (int, int)>((
      ref,
      ym,
    ) async {
      var (y, m) = ym;
      for (var i = 0; i < 12; i++) {
        (y, m) = m == 12 ? (y + 1, 1) : (y, m + 1);
        final month = await ref.watch(hijriMonthProvider((y, m)).future);
        for (final d in month.days) {
          if (d.eventIds.isNotEmpty) {
            return (date: d.date, eventId: d.eventIds.first);
          }
        }
      }
      return null;
    }, name: 'nextCalendarEventProvider');

/// Aktualny `hijri.offset` (-2..+2).
final FutureProvider<int> hijriOffsetProvider = FutureProvider<int>(
  (ref) async =>
      (await ref.watch(settingProvider(SettingsKeys.hijriOffset).future)
          as int?) ??
      0,
  name: 'hijriOffsetProvider',
);
