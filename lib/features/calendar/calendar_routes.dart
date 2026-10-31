import 'package:go_router/go_router.dart';
import 'package:sakina/features/calendar/calendar_screen.dart';
import 'package:sakina/features/calendar/hijri_offset.dart';

export 'package:sakina/features/calendar/hijri_offset.dart'
    show HijriOffsetScreen;

/// Hijri kalendar `/calendar?month=YYYY-MM` alebo `?hm=1448-05`
/// (docs/02 C1). Vstup z tabu Prayer (docs/01 D1). Vlastnik: F-05.
abstract final class CalendarRoutes {
  static const root = '/calendar';

  /// `?hm=1448-05` -> (1448, 5); neplatne = null (aktualny mesiac, C2).
  static (int, int)? parseHijri(String? raw) =>
      _parse(raw, RegExp(r'^(\d{4})-(\d{2})$'), maxMonth: 12);

  /// `?month=2026-10` -> (2026, 10).
  static (int, int)? parseGregorian(String? raw) =>
      _parse(raw, RegExp(r'^(\d{4})-(\d{2})$'), maxMonth: 12);

  static (int, int)? _parse(String? raw, RegExp re, {required int maxMonth}) {
    final m = raw == null ? null : re.firstMatch(raw);
    if (m == null) return null;
    final month = int.parse(m[2]!);
    if (month < 1 || month > maxMonth) return null;
    return (int.parse(m[1]!), month);
  }
}

List<RouteBase> calendarRoutes() => [
  GoRoute(
    path: CalendarRoutes.root,
    name: 'calendar',
    builder: (context, state) => CalendarScreen(
      initialMonth: CalendarRoutes.parseHijri(state.uri.queryParameters['hm']),
      initialGregorian: CalendarRoutes.parseGregorian(
        state.uri.queryParameters['month'],
      ),
    ),
  ),
];

/// Obrazovka F-05 pre `/settings/calendar` (routa F-07).
abstract final class CalendarSettingsBuilders {
  static GoRouterWidgetBuilder get offset =>
      (context, state) => const HijriOffsetScreen();
}
