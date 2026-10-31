import 'package:flutter/widgets.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

/// UI texty modlitieb a hijri datumu (len UI copy z ARB, ziadny
/// nabozensky obsah). Cislice podla jazyka UI ([ProsocheFormats]).
extension PrayerTextsX on BuildContext {
  ProsocheFormats get formats => ProsocheFormats(Localizations.localeOf(this));

  String prayerName(Prayer p) => l10n.prayerTimeName(p.name);

  String methodName(PrayerMethod m) => l10n.prayerMethodName(m.key);

  String asrShort(AsrMadhab a) => a == AsrMadhab.hanafi
      ? l10n.prayerAsrShortHanafi
      : l10n.prayerAsrShortShafi;

  String highLatName(HighLatRule r) => l10n.prayerHighLatName(r.key);

  /// Uhly metody, napr. "Fajr 18°, Isha 17°".
  String methodAngles(PrayerMethod m) {
    final p = CalcSettings(method: m).toAdhan();
    String deg(double v) => formats.number(v);
    final interval = p.ishaInterval ?? 0;
    return interval > 0
        ? l10n.prayerMethodInterval(deg(p.fajrAngle), formats.number(interval))
        : l10n.prayerMethodAngles(deg(p.fajrAngle), deg(p.ishaAngle));
  }

  /// "+2", "-5", "0" v cisliciach UI.
  String signedNumber(int v) =>
      v > 0 ? '+${formats.number(v)}' : formats.number(v);

  /// Cas do zaciatku modlitby, napr. "in 1 h 12 min".
  String untilLabel(Duration d) {
    // Zaokruhlenie nahor: 59,5 s pred casom je "in 1 min", nie "in 0 min".
    final total = (d.inSeconds + 59) ~/ 60;
    final h = total ~/ 60;
    final m = total % 60;
    final raw = h > 0
        ? l10n.prayerInHoursMinutes(h, m)
        : l10n.prayerInMinutes(m);
    return localizeDigits(raw, formats.digits);
  }

  String hijriMonthName(int month) => l10n.hijriMonthName('m$month');

  /// "17 Jumada al-Ula 1448".
  String hijriDateLabel(HijriDate d) => l10n.hijriDate(
    formats.number(d.day),
    hijriMonthName(d.month),
    _year(d.year),
  );

  /// "Jumada al-Ula 1448".
  String hijriMonthLabel(int year, int month) =>
      l10n.calendarMonthTitle(hijriMonthName(month), _year(year));

  /// Hijri offset "+1 day", "0 days", "−2 days".
  String hijriOffsetLabel(int offset) => localizeDigits(
    l10n.calendarOffsetDays(offset < 0 ? 'm${-offset}' : 'p$offset'),
    formats.digits,
  );

  // Rok bez oddelovaca tisicov (1448, nie 1,448).
  String _year(int y) => localizeDigits('$y', formats.digits);
}
