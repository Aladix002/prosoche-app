import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';

/// Nazov eventu s najvyssou prioritou pre chip na Dnes (text z content.db,
/// bez EN fallbacku nabozenskeho textu); null = ziadny event alebo text
/// v jazyku chyba.
final FutureProviderFamily<String?, LocalDate> todayEventTitleProvider =
    FutureProvider.family<String?, LocalDate>((ref, date) async {
      final events = [...await ref.watch(activeEventsProvider(date).future)]
        ..sort((a, b) => b.priority.compareTo(a.priority));
      if (events.isEmpty) return null;
      final lang = await ref.watch(contentLanguageProvider.future);
      final calendar = ref.watch(calendarRepositoryProvider);
      for (final e in events) {
        final text = await calendar.eventText(e.id, lang);
        if (text != null) return text.title;
      }
      return null;
    }, name: 'todayEventTitleProvider');
