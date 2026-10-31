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
  const FeatureFlags({this.gate = false});

  const FeatureFlags._environment()
    : gate = const bool.fromEnvironment('FEATURE_GATE');

  /// Hodnoty z `--dart-define`.
  static const fromEnvironment = FeatureFlags._environment();

  /// Vsetko vypnute (ako `lite` produkcia bez `--dart-define`).
  static const none = FeatureFlags();

  /// Vsetko zapnute (testy, galeria).
  static const all = FeatureFlags(gate: true);

  /// `FEATURE_GATE`: brana pred appkami (`/gate`, nastavenia blokovania).
  final bool gate;

  /// Flagy upravene pre ediciu: v `lite` je brana vzdy vypnuta.
  FeatureFlags forEdition(Edition edition) =>
      edition.isFull ? this : copyWith(gate: false);

  FeatureFlags copyWith({bool? gate}) => FeatureFlags(gate: gate ?? this.gate);

  @override
  bool operator ==(Object other) => other is FeatureFlags && other.gate == gate;

  @override
  int get hashCode => gate.hashCode;

  @override
  String toString() => 'FeatureFlags(gate: $gate)';
}

/// Flagy platne pre beziacu appku. V testoch prepisat cez
/// `featureFlagsProvider.overrideWithValue(...)`.
@Riverpod(keepAlive: true)
FeatureFlags featureFlags(Ref ref) =>
    FeatureFlags.fromEnvironment.forEdition(ref.watch(editionProvider));
