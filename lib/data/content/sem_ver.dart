import 'package:meta/meta.dart';

/// Verzia `X.Y.Z` (manifest `min_app_version`, remote config). Build cast
/// za `+` (napr. pubspec `0.1.0+1`) sa ignoruje.
@immutable
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch);

  static final _re = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  /// `null` pri inom tvare ako `X.Y.Z` (s volitelnym `+build`).
  static SemVer? tryParse(String? text) {
    if (text == null) return null;
    final core = text.split('+').first.trim();
    final m = _re.firstMatch(core);
    if (m == null) return null;
    return SemVer(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  /// Ako [tryParse], pri chybe [FormatException].
  static SemVer parse(String text) =>
      tryParse(text) ?? (throw FormatException('Not X.Y.Z', text));

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(SemVer other) => compareTo(other) < 0;
  bool operator >(SemVer other) => compareTo(other) > 0;
  bool operator <=(SemVer other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
