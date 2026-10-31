import 'package:meta/meta.dart';

/// Identifikator versa `surah * 1000 + ayah` (plan 5.1), napr. 2:255 = 2255.
///
/// Konstruktory overuju rozsah podla poctu versov v sure (Hafs, 6236 spolu).
@immutable
final class AyahId implements Comparable<AyahId> {
  /// Z cisla sury (1..114) a versa (1..pocet versov sury).
  factory AyahId(int surah, int ayah) {
    if (surah < 1 || surah > surahCount) {
      throw RangeError.range(surah, 1, surahCount, 'surah');
    }
    final count = ayahCount(surah);
    if (ayah < 1 || ayah > count) {
      throw RangeError.range(ayah, 1, count, 'ayah');
    }
    return AyahId._(surah * 1000 + ayah);
  }

  const AyahId._(this.value);

  /// Z hodnoty `surah * 1000 + ayah` (napr. z DB alebo `card_id`).
  factory AyahId.fromValue(int value) => AyahId(value ~/ 1000, value % 1000);

  /// Ako [AyahId.fromValue], ale pri neplatnej hodnote vrati null.
  static AyahId? tryFromValue(int value) =>
      isValid(value ~/ 1000, value % 1000) ? AyahId._(value) : null;

  /// Ci vers [surah]:[ayah] existuje.
  static bool isValid(int surah, int ayah) =>
      surah >= 1 &&
      surah <= surahCount &&
      ayah >= 1 &&
      ayah <= ayahCount(surah);

  static const surahCount = 114;
  static const totalAyahs = 6236;
  static const first = AyahId._(1001);
  static const last = AyahId._(114006);

  /// Pocet versov sury [surah] (1..114).
  static int ayahCount(int surah) => _ayahCounts[surah - 1];

  final int value;

  int get surah => value ~/ 1000;
  int get ayah => value % 1000;

  /// Nasledujuci vers v poradi citania; po 114:6 pokracuje 1:1.
  AyahId get next {
    if (ayah < ayahCount(surah)) return AyahId._(value + 1);
    return surah == surahCount ? first : AyahId._((surah + 1) * 1000 + 1);
  }

  @override
  int compareTo(AyahId other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is AyahId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// Tvar `surah:ayah`, napr. `2:255`.
  @override
  String toString() => '$surah:$ayah';
}

const _ayahCounts = <int>[
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, // 1-10
  123, 111, 43, 52, 99, 128, 111, 110, 98, 135, // 11-20
  112, 78, 118, 64, 77, 227, 93, 88, 69, 60, // 21-30
  34, 30, 73, 54, 45, 83, 182, 88, 75, 85, // 31-40
  54, 53, 89, 59, 37, 35, 38, 29, 18, 45, // 41-50
  60, 49, 62, 55, 78, 96, 29, 22, 24, 13, // 51-60
  14, 11, 11, 18, 12, 12, 30, 52, 52, 44, // 61-70
  28, 28, 20, 56, 40, 31, 50, 40, 46, 42, // 71-80
  29, 19, 36, 25, 22, 17, 19, 26, 30, 20, // 81-90
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11, // 91-100
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3, // 101-110
  5, 4, 5, 6, // 111-114
];
