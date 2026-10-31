// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocker_gateway_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Nativny blocker. V testoch prepisat cez
/// `blockerGatewayProvider.overrideWithValue(FakeBlockerGateway(...))`.

@ProviderFor(blockerGateway)
final blockerGatewayProvider = BlockerGatewayProvider._();

/// Nativny blocker. V testoch prepisat cez
/// `blockerGatewayProvider.overrideWithValue(FakeBlockerGateway(...))`.

final class BlockerGatewayProvider
    extends $FunctionalProvider<BlockerGateway, BlockerGateway, BlockerGateway>
    with $Provider<BlockerGateway> {
  /// Nativny blocker. V testoch prepisat cez
  /// `blockerGatewayProvider.overrideWithValue(FakeBlockerGateway(...))`.
  BlockerGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockerGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockerGatewayHash();

  @$internal
  @override
  $ProviderElement<BlockerGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BlockerGateway create(Ref ref) {
    return blockerGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlockerGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlockerGateway>(value),
    );
  }
}

String _$blockerGatewayHash() => r'46c89285d6320ce69f266acd2b424a514809ef74';
