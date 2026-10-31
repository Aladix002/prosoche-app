// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Flagy platne pre beziacu appku. V testoch prepisat cez
/// `featureFlagsProvider.overrideWithValue(...)`.

@ProviderFor(featureFlags)
final featureFlagsProvider = FeatureFlagsProvider._();

/// Flagy platne pre beziacu appku. V testoch prepisat cez
/// `featureFlagsProvider.overrideWithValue(...)`.

final class FeatureFlagsProvider
    extends $FunctionalProvider<FeatureFlags, FeatureFlags, FeatureFlags>
    with $Provider<FeatureFlags> {
  /// Flagy platne pre beziacu appku. V testoch prepisat cez
  /// `featureFlagsProvider.overrideWithValue(...)`.
  FeatureFlagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagsHash();

  @$internal
  @override
  $ProviderElement<FeatureFlags> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeatureFlags create(Ref ref) {
    return featureFlags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureFlags value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureFlags>(value),
    );
  }
}

String _$featureFlagsHash() => r'168be9f02c238574524b92ff1e995c000b8859a4';
