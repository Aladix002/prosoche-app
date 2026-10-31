// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hadith_extra_pack_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Balik `hadith_extra.db` (D-05). UI vola `download()` a `delete()`.

@ProviderFor(hadithExtraPackService)
final hadithExtraPackServiceProvider = HadithExtraPackServiceProvider._();

/// Balik `hadith_extra.db` (D-05). UI vola `download()` a `delete()`.

final class HadithExtraPackServiceProvider
    extends
        $FunctionalProvider<
          HadithExtraPackService,
          HadithExtraPackService,
          HadithExtraPackService
        >
    with $Provider<HadithExtraPackService> {
  /// Balik `hadith_extra.db` (D-05). UI vola `download()` a `delete()`.
  HadithExtraPackServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hadithExtraPackServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hadithExtraPackServiceHash();

  @$internal
  @override
  $ProviderElement<HadithExtraPackService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HadithExtraPackService create(Ref ref) {
    return hadithExtraPackService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HadithExtraPackService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HadithExtraPackService>(value),
    );
  }
}

String _$hadithExtraPackServiceHash() =>
    r'd54e15197d3673ce937ab9af411741df2d353a3e';

/// Stav balika vratane priebehu stahovania.

@ProviderFor(hadithExtraPackStatus)
final hadithExtraPackStatusProvider = HadithExtraPackStatusProvider._();

/// Stav balika vratane priebehu stahovania.

final class HadithExtraPackStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<HadithExtraPackStatus>,
          HadithExtraPackStatus,
          Stream<HadithExtraPackStatus>
        >
    with
        $FutureModifier<HadithExtraPackStatus>,
        $StreamProvider<HadithExtraPackStatus> {
  /// Stav balika vratane priebehu stahovania.
  HadithExtraPackStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hadithExtraPackStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hadithExtraPackStatusHash();

  @$internal
  @override
  $StreamProviderElement<HadithExtraPackStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<HadithExtraPackStatus> create(Ref ref) {
    return hadithExtraPackStatus(ref);
  }
}

String _$hadithExtraPackStatusHash() =>
    r'9116ca7faa9cf64ee8355711f928e6708b3b67be';

/// Repozitar vysvetliviek nad balikom; vracia `null`, kym balik nie je
/// [HadithExtraReady]. Prestavi sa pri zmene pripravenosti, takze
/// zavisle providery (`hadithExtraProvider`) sa prepocitaju.

@ProviderFor(hadithExtraPackRepository)
final hadithExtraPackRepositoryProvider = HadithExtraPackRepositoryProvider._();

/// Repozitar vysvetliviek nad balikom; vracia `null`, kym balik nie je
/// [HadithExtraReady]. Prestavi sa pri zmene pripravenosti, takze
/// zavisle providery (`hadithExtraProvider`) sa prepocitaju.

final class HadithExtraPackRepositoryProvider
    extends
        $FunctionalProvider<
          db.HadithExtraRepository,
          db.HadithExtraRepository,
          db.HadithExtraRepository
        >
    with $Provider<db.HadithExtraRepository> {
  /// Repozitar vysvetliviek nad balikom; vracia `null`, kym balik nie je
  /// [HadithExtraReady]. Prestavi sa pri zmene pripravenosti, takze
  /// zavisle providery (`hadithExtraProvider`) sa prepocitaju.
  HadithExtraPackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hadithExtraPackRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hadithExtraPackRepositoryHash();

  @$internal
  @override
  $ProviderElement<db.HadithExtraRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  db.HadithExtraRepository create(Ref ref) {
    return hadithExtraPackRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(db.HadithExtraRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<db.HadithExtraRepository>(value),
    );
  }
}

String _$hadithExtraPackRepositoryHash() =>
    r'bb39aa80a52ca14f6e09d0ed3aa6a05035258fa1';
