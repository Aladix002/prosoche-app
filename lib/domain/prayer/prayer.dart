import 'package:adhan_dart/adhan_dart.dart' as adhan;

/// Casy dna v poradi. [sunrise] nie je modlitba, ale konci cas fajr.
///
/// [name] je zhodny s klucmi `prayer.adjust` a `notif.prayer.{p}`.
enum Prayer {
  fajr(adhan.Prayer.fajr),
  sunrise(adhan.Prayer.sunrise),
  dhuhr(adhan.Prayer.dhuhr),
  asr(adhan.Prayer.asr),
  maghrib(adhan.Prayer.maghrib),
  isha(adhan.Prayer.isha);

  Prayer(this.adhanPrayer);

  final adhan.Prayer adhanPrayer;

  /// Jedna z piatich povinnych modlitieb (nie [sunrise]).
  bool get isSalah => this != sunrise;

  static const List<Prayer> salah = [fajr, dhuhr, asr, maghrib, isha];
}
