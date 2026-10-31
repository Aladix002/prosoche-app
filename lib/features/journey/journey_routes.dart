import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/features/journey/journey_day_screen.dart';
import 'package:sakina/features/journey/journey_screen.dart';
import 'package:sakina/features/journey/saved_screen.dart';

/// Tab Journey (docs/02 C1). Vlastnik: F-06.
abstract final class JourneyRoutes {
  static const String root = AppRoutes.journey;
  static const saved = '$root/saved';

  /// Nazvy rout = `screen_view` (docs/02 C2).
  static const dayName = 'journey_day';
  static const savedName = 'saved';

  /// `/journey/day/YYYY-MM-DD`
  static String day(LocalDate date) => '$root/day/$date';

  /// Datum detailu dna: platny a najviac dnes (docs/02 C2), inak null.
  static LocalDate? parseDay(String? raw, LocalDate today) {
    final date = LocalDate.tryParse(raw ?? '');
    return date == null || date.isAfter(today) ? null : date;
  }
}

List<RouteBase> journeyRoutes() => [
  GoRoute(
    path: JourneyRoutes.root,
    name: AppRouteNames.journey,
    builder: (context, state) => const JourneyScreen(),
    routes: [
      GoRoute(
        path: 'day/:date',
        name: JourneyRoutes.dayName,
        redirect: (context, state) {
          final today = ProviderScope.containerOf(
            context,
            listen: false,
          ).read(localDateProvider);
          return JourneyRoutes.parseDay(state.pathParameters['date'], today) ==
                  null
              ? JourneyRoutes.root
              : null;
        },
        builder: (context, state) => JourneyDayScreen(
          date: LocalDate.parse(state.pathParameters['date']!),
        ),
      ),
      GoRoute(
        path: 'saved',
        name: JourneyRoutes.savedName,
        builder: (context, state) => SavedCardsScreen(
          initialType: parseSavedType(state.uri.queryParameters['type']),
        ),
      ),
    ],
  ),
];
