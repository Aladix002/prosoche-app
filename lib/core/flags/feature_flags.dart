import 'package:meta/meta.dart';
import 'package:prosoche/core/flavor/flavor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_flags.g.dart';

/// Compile-time flagy nedokoncenych funkcii (docs/06 A.2).
///
/// ```sh
/// flutter run --flavor devFull --dart-define=FEATURE_GATE=true
/// ```
/// Vsetky su predvolene vypnute. Brana ide len v edicii `full`
/// ([forEdition]), lebo `lite` nema nativny blocker ani povolenia.
@immutable
final class FeatureFlags {
  const FeatureFlags({
    this.gate = false,
    this.words = false,
    this.audio = false,
    this.ramadanLight = false,
  });

  const FeatureFlags._environment()
    : gate = const bool.fromEnvironment('FEATURE_GATE'),
      words = const bool.fromEnvironment('FEATURE_WORDS'),
      audio = const bool.fromEnvironment('FEATURE_AUDIO'),
      ramadanLight = const bool.fromEnvironment('FEATURE_RAMADAN_LIGHT');

  /// Hodnoty z `--dart-define`.
  static const fromEnvironment = FeatureFlags._environment();

  /// Vsetko vypnute (ako `lite` produkcia bez `--dart-define`).
  static const none = FeatureFlags();

  /// Vsetko zapnute (testy, galeria).
  static const all = FeatureFlags(
    gate: true,
    words: true,
    audio: true,
    ramadanLight: true,
  );

  /// `FEATURE_GATE`: brana pred appkami (`/gate`, nastavenia blokovania).
  final bool gate;

  /// `FEATURE_WORDS`: slovicka a SRS (`/words/**`, sloty 5 a 8).
  final bool words;

  /// `FEATURE_AUDIO`: prehravanie recitacie.
  final bool audio;

  /// `FEATURE_RAMADAN_LIGHT`: Ramadan light (F-08).
  final bool ramadanLight;

  /// Flagy upravene pre ediciu: v `lite` je brana vzdy vypnuta.
  FeatureFlags forEdition(Edition edition) =>
      edition.isFull ? this : copyWith(gate: false);

  FeatureFlags copyWith({
    bool? gate,
    bool? words,
    bool? audio,
    bool? ramadanLight,
  }) => FeatureFlags(
    gate: gate ?? this.gate,
    words: words ?? this.words,
    audio: audio ?? this.audio,
    ramadanLight: ramadanLight ?? this.ramadanLight,
  );

  @override
  bool operator ==(Object other) =>
      other is FeatureFlags &&
      other.gate == gate &&
      other.words == words &&
      other.audio == audio &&
      other.ramadanLight == ramadanLight;

  @override
  int get hashCode => Object.hash(gate, words, audio, ramadanLight);

  @override
  String toString() =>
      'FeatureFlags(gate: $gate, words: $words, audio: $audio, '
      'ramadanLight: $ramadanLight)';
}

/// Flagy platne pre beziacu appku. V testoch prepisat cez
/// `featureFlagsProvider.overrideWithValue(...)`.
@Riverpod(keepAlive: true)
FeatureFlags featureFlags(Ref ref) =>
    FeatureFlags.fromEnvironment.forEdition(ref.watch(editionProvider));
