import 'package:meta/meta.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Text eventu (`islamic_event_text`, docs/02 D2).
@immutable
final class EventText {
  const EventText({
    required this.eventId,
    required this.lang,
    required this.title,
    this.body,
  });

  final String eventId;

  /// Jazyk textu; pri fallbacku `en` sa lisi od pozadovaneho (stitok "EN").
  final String lang;
  final String title;
  final String? body;
}

/// Den v mesacnom pohlade kalendara (A9).
@immutable
final class CalendarDay {
  CalendarDay({
    required this.date,
    required this.hijri,
    required List<String> eventIds,
  }) : eventIds = List.unmodifiable(eventIds);

  final LocalDate date;
  final HijriDate hijri;

  /// Aktivne eventy dna podla priority (vratane `optional`/`info`).
  final List<String> eventIds;
}

/// Hijri mesiac s eventmi (A9).
@immutable
final class CalendarMonth {
  CalendarMonth({
    required this.year,
    required this.month,
    required List<CalendarDay> days,
  }) : days = List.unmodifiable(days);

  final int year;
  final int month;
  final List<CalendarDay> days;

  /// Eventy mesiaca v poradi prveho vyskytu.
  List<String> get eventIds => {for (final d in days) ...d.eventIds}.toList();
}

/// Hijri datum a islamske eventy (E-01 nad content.db a `hijri.offset`).
abstract interface class CalendarRepository {
  /// Kalendar s aktualnym `settings.hijri.offset`.
  Future<IslamicCalendar> calendar();

  Future<HijriDate> hijriDate(LocalDate date);

  /// Aktivne eventy dna a ich ucinok (sloty, questy, intro).
  Future<EventResolution> resolve(LocalDate date);

  /// Dni hijri mesiaca [year]/[month] s eventmi.
  Future<CalendarMonth> month(int year, int month);

  /// Text eventu v [lang]. [allowEnFallback]: kalendar A9 smie ukazat `en`
  /// (so stitkom), karty v sade nie (docs/03 7.3).
  Future<EventText?> eventText(
    String eventId,
    String lang, {
    bool allowEnFallback = false,
  });
}

/// [CalendarRepository] nad [ContentCatalog] a nastaveniami.
class ContentCalendarRepository implements CalendarRepository {
  ContentCalendarRepository({required this._catalog, required this._settings});

  final ContentCatalog _catalog;
  final SettingsRepository _settings;

  EventResolver? _resolver;
  List<EventRule>? _resolverRules;

  @override
  Future<IslamicCalendar> calendar() async =>
      IslamicCalendar(offset: await _settings.get(SettingsKeys.hijriOffset));

  Future<EventResolver> _resolverFor(IslamicCalendar calendar) async {
    final rules = await _catalog.eventRules();
    final cached = _resolver;
    if (cached != null &&
        identical(_resolverRules, rules) &&
        cached.calendar == calendar) {
      return cached;
    }
    _resolverRules = rules;
    return _resolver = EventResolver(rules, calendar);
  }

  @override
  Future<HijriDate> hijriDate(LocalDate date) async =>
      (await calendar()).hijriOf(date);

  @override
  Future<EventResolution> resolve(LocalDate date) async =>
      (await _resolverFor(await calendar())).resolve(date);

  @override
  Future<CalendarMonth> month(int year, int month) async {
    final resolver = await _resolverFor(await calendar());
    return CalendarMonth(
      year: year,
      month: month,
      days: [
        for (final d in resolver.calendar.daysOfMonth(year, month))
          CalendarDay(
            date: d,
            hijri: resolver.calendar.hijriOf(d),
            eventIds: [for (final e in resolver.resolve(d).active) e.id],
          ),
      ],
    );
  }

  @override
  Future<EventText?> eventText(
    String eventId,
    String lang, {
    bool allowEnFallback = false,
  }) async {
    final dao = (await _catalog.db).curatedDao;
    for (final l in [lang, if (allowEnFallback && lang != 'en') 'en']) {
      final row = (await dao.eventTextsFor(l))[eventId];
      if (row != null) {
        return EventText(
          eventId: eventId,
          lang: l,
          title: row.title,
          body: row.body,
        );
      }
    }
    return null;
  }
}
