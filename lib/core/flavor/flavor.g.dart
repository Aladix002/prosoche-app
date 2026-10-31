// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flavor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prepisane v bootstrape podla `appFlavor`.

@ProviderFor(flavor)
final flavorProvider = FlavorProvider._();

/// Prepisane v bootstrape podla `appFlavor`.

final class FlavorProvider extends $FunctionalProvider<Flavor, Flavor, Flavor>
    with $Provider<Flavor> {
  /// Prepisane v bootstrape podla `appFlavor`.
  FlavorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flavorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flavorHash();

  @$internal
  @override
  $ProviderElement<Flavor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Flavor create(Ref ref) {
    return flavor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Flavor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Flavor>(value),
    );
  }
}

String _$flavorHash() => r'4c5515ccce3aa6508b319114a9c63e840b3f9100';

/// Prepisane v bootstrape podla `appFlavor`.

@ProviderFor(edition)
final editionProvider = EditionProvider._();

/// Prepisane v bootstrape podla `appFlavor`.

final class EditionProvider
    extends $FunctionalProvider<Edition, Edition, Edition>
    with $Provider<Edition> {
  /// Prepisane v bootstrape podla `appFlavor`.
  EditionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editionHash();

  @$internal
  @override
  $ProviderElement<Edition> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Edition create(Ref ref) {
    return edition(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Edition value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Edition>(value),
    );
  }
}

String _$editionHash() => r'2826c6c5ab0aadc40e25bf774d210ad486369ce8';
