import 'package:sakina/domain/common/local_date.dart';

/// Jednoduchy zaznam postu v Ramadane (F-08, docs/04 1.4 bez dovodov).
///
/// Ziadne hodnotenie: vynechany post nie je zlyhanie a neovplyvnuje
/// streak. Dovod sa nepyta, [excused] je bez dalsich udajov.
enum FastEntry {
  fasted('fasted'),
  notFasted('not_fasted'),
  excused('excused');

  FastEntry(this.wire);

  /// Hodnota `fast_log.status`.
  final String wire;

  static FastEntry? tryParse(String? wire) {
    for (final e in values) {
      if (e.wire == wire) return e;
    }
    return null;
  }
}

/// Zaznamy postu (`fast_log`, `type = ramadan`).
abstract interface class FastLogRepository {
  /// Zaznam dna [date] a kazda jeho zmena; null = bez zaznamu.
  Stream<FastEntry?> watch(LocalDate date);

  /// Ulozi zaznam; null ho zmaze (spat).
  Future<void> set(LocalDate date, FastEntry? entry);
}
