// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Verzia appky pre `min_app_version` a kill-switch. Bootstrap ju prepise
/// skutocnou verziou (`--dart-define=APP_VERSION=...` alebo
/// package_info), default zodpoveda pubspec.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// Verzia appky pre `min_app_version` a kill-switch. Bootstrap ju prepise
/// skutocnou verziou (`--dart-define=APP_VERSION=...` alebo
/// package_info), default zodpoveda pubspec.

final class AppVersionProvider
    extends $FunctionalProvider<SemVer, SemVer, SemVer>
    with $Provider<SemVer> {
  /// Verzia appky pre `min_app_version` a kill-switch. Bootstrap ju prepise
  /// skutocnou verziou (`--dart-define=APP_VERSION=...` alebo
  /// package_info), default zodpoveda pubspec.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $ProviderElement<SemVer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SemVer create(Ref ref) {
    return appVersion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SemVer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SemVer>(value),
    );
  }
}

String _$appVersionHash() => r'2ccf5b03cdf3ec223cbefcaecb6ee2bb278d8e87';

/// `<application support>/content`.

@ProviderFor(contentDirectory)
final contentDirectoryProvider = ContentDirectoryProvider._();

/// `<application support>/content`.

final class ContentDirectoryProvider
    extends
        $FunctionalProvider<
          Future<Directory> Function(),
          Future<Directory> Function(),
          Future<Directory> Function()
        >
    with $Provider<Future<Directory> Function()> {
  /// `<application support>/content`.
  ContentDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentDirectoryHash();

  @$internal
  @override
  $ProviderElement<Future<Directory> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<Directory> Function() create(Ref ref) {
    return contentDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<Directory> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<Directory> Function()>(value),
    );
  }
}

String _$contentDirectoryHash() => r'6518663f1cf4cfb58ca81064d69096b06cc92c1e';

@ProviderFor(bundledContentSource)
final bundledContentSourceProvider = BundledContentSourceProvider._();

final class BundledContentSourceProvider
    extends
        $FunctionalProvider<
          BundledContentSource,
          BundledContentSource,
          BundledContentSource
        >
    with $Provider<BundledContentSource> {
  BundledContentSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bundledContentSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bundledContentSourceHash();

  @$internal
  @override
  $ProviderElement<BundledContentSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BundledContentSource create(Ref ref) {
    return bundledContentSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BundledContentSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BundledContentSource>(value),
    );
  }
}

String _$bundledContentSourceHash() =>
    r'0bc3eaba417807baa8010dcc2660566b592dbf39';

@ProviderFor(contentHttpClient)
final contentHttpClientProvider = ContentHttpClientProvider._();

final class ContentHttpClientProvider
    extends
        $FunctionalProvider<
          ContentHttpClient,
          ContentHttpClient,
          ContentHttpClient
        >
    with $Provider<ContentHttpClient> {
  ContentHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentHttpClientHash();

  @$internal
  @override
  $ProviderElement<ContentHttpClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentHttpClient create(Ref ref) {
    return contentHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentHttpClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentHttpClient>(value),
    );
  }
}

String _$contentHttpClientHash() => r'd23c9c8cdf9dd4d241f353cb6353d0129b3aabaf';

@ProviderFor(contentEndpoints)
final contentEndpointsProvider = ContentEndpointsProvider._();

final class ContentEndpointsProvider
    extends
        $FunctionalProvider<
          ContentEndpoints,
          ContentEndpoints,
          ContentEndpoints
        >
    with $Provider<ContentEndpoints> {
  ContentEndpointsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentEndpointsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentEndpointsHash();

  @$internal
  @override
  $ProviderElement<ContentEndpoints> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContentEndpoints create(Ref ref) {
    return contentEndpoints(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentEndpoints value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentEndpoints>(value),
    );
  }
}

String _$contentEndpointsHash() => r'f028283662d03ae300e5017c614e0c9ca9350e5a';

/// Zapecene kluce; flavor `dev` doveruje aj lokalnemu `content-dev`.

@ProviderFor(trustedKeys)
final trustedKeysProvider = TrustedKeysProvider._();

/// Zapecene kluce; flavor `dev` doveruje aj lokalnemu `content-dev`.

final class TrustedKeysProvider
    extends $FunctionalProvider<TrustedKeySet, TrustedKeySet, TrustedKeySet>
    with $Provider<TrustedKeySet> {
  /// Zapecene kluce; flavor `dev` doveruje aj lokalnemu `content-dev`.
  TrustedKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trustedKeysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trustedKeysHash();

  @$internal
  @override
  $ProviderElement<TrustedKeySet> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrustedKeySet create(Ref ref) {
    return trustedKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrustedKeySet value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrustedKeySet>(value),
    );
  }
}

String _$trustedKeysHash() => r'47b3be1041cb00d7803f9a410045e361cb6ebbfe';

/// V `dev` sa prijme aj vyvojovy obsah (`meta.dev_content = 1`).

@ProviderFor(contentIntegrityChecker)
final contentIntegrityCheckerProvider = ContentIntegrityCheckerProvider._();

/// V `dev` sa prijme aj vyvojovy obsah (`meta.dev_content = 1`).

final class ContentIntegrityCheckerProvider
    extends
        $FunctionalProvider<
          ContentIntegrityChecker,
          ContentIntegrityChecker,
          ContentIntegrityChecker
        >
    with $Provider<ContentIntegrityChecker> {
  /// V `dev` sa prijme aj vyvojovy obsah (`meta.dev_content = 1`).
  ContentIntegrityCheckerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentIntegrityCheckerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentIntegrityCheckerHash();

  @$internal
  @override
  $ProviderElement<ContentIntegrityChecker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentIntegrityChecker create(Ref ref) {
    return contentIntegrityChecker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentIntegrityChecker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentIntegrityChecker>(value),
    );
  }
}

String _$contentIntegrityCheckerHash() =>
    r'3b12fcbdf08ec2a5a3f3b0a85c1cef3bd3266932';

@ProviderFor(contentPackService)
final contentPackServiceProvider = ContentPackServiceProvider._();

final class ContentPackServiceProvider
    extends
        $FunctionalProvider<
          ContentPackService,
          ContentPackService,
          ContentPackService
        >
    with $Provider<ContentPackService> {
  ContentPackServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentPackServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentPackServiceHash();

  @$internal
  @override
  $ProviderElement<ContentPackService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentPackService create(Ref ref) {
    return contentPackService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentPackService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentPackService>(value),
    );
  }
}

String _$contentPackServiceHash() =>
    r'5b9ae0f47e263acb2e2b536f048fde507309587e';

/// Perzistentny stav obsahu, aktualizuje sa pri kazdej zmene.

@ProviderFor(contentPackState)
final contentPackStateProvider = ContentPackStateProvider._();

/// Perzistentny stav obsahu, aktualizuje sa pri kazdej zmene.

final class ContentPackStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentPackState>,
          ContentPackState,
          Stream<ContentPackState>
        >
    with $FutureModifier<ContentPackState>, $StreamProvider<ContentPackState> {
  /// Perzistentny stav obsahu, aktualizuje sa pri kazdej zmene.
  ContentPackStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentPackStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentPackStateHash();

  @$internal
  @override
  $StreamProviderElement<ContentPackState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ContentPackState> create(Ref ref) {
    return contentPackState(ref);
  }
}

String _$contentPackStateHash() => r'6ad25f2a54370693a6ac076d276e428fd3a285c1';

/// `card_id` vypnute cez `disabled_ids` (docs/03 7.4). FeedGenerator ich
/// vynecha; kym sa stav nenacita, prazdna mnozina.

@ProviderFor(disabledContentIds)
final disabledContentIdsProvider = DisabledContentIdsProvider._();

/// `card_id` vypnute cez `disabled_ids` (docs/03 7.4). FeedGenerator ich
/// vynecha; kym sa stav nenacita, prazdna mnozina.

final class DisabledContentIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// `card_id` vypnute cez `disabled_ids` (docs/03 7.4). FeedGenerator ich
  /// vynecha; kym sa stav nenacita, prazdna mnozina.
  DisabledContentIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'disabledContentIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$disabledContentIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return disabledContentIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$disabledContentIdsHash() =>
    r'49a408f2c11d676cecb621d83c646c7e9d690750';

/// Kill-switch (docs/06 A.7): funkcie, `updateRequired`, oznam. Obsah v1
/// nepublikuje `remote_config.json`: defaulty z kodu (vsetko zapnute).

@ProviderFor(remoteConfigPolicy)
final remoteConfigPolicyProvider = RemoteConfigPolicyProvider._();

/// Kill-switch (docs/06 A.7): funkcie, `updateRequired`, oznam. Obsah v1
/// nepublikuje `remote_config.json`: defaulty z kodu (vsetko zapnute).

final class RemoteConfigPolicyProvider
    extends
        $FunctionalProvider<
          RemoteConfigPolicy,
          RemoteConfigPolicy,
          RemoteConfigPolicy
        >
    with $Provider<RemoteConfigPolicy> {
  /// Kill-switch (docs/06 A.7): funkcie, `updateRequired`, oznam. Obsah v1
  /// nepublikuje `remote_config.json`: defaulty z kodu (vsetko zapnute).
  RemoteConfigPolicyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteConfigPolicyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteConfigPolicyHash();

  @$internal
  @override
  $ProviderElement<RemoteConfigPolicy> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoteConfigPolicy create(Ref ref) {
    return remoteConfigPolicy(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteConfigPolicy value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteConfigPolicy>(value),
    );
  }
}

String _$remoteConfigPolicyHash() =>
    r'a837405983215912336066bf6c71e452135a9e81';

/// Otvorena, overena content.db (read-only). Po aktualizacii obsahu sa
/// stare spojenie zavrie a otvori nove.
///
/// D-02 `contentDbProvider` sa na neho prepoji:
/// `ref.watch(contentDatabaseProvider.future)` v jeho tele, alebo override
/// `contentDbProvider.overrideWith((ref) => ref.watch(
/// contentDatabaseProvider.future))`.

@ProviderFor(contentDatabase)
final contentDatabaseProvider = ContentDatabaseProvider._();

/// Otvorena, overena content.db (read-only). Po aktualizacii obsahu sa
/// stare spojenie zavrie a otvori nove.
///
/// D-02 `contentDbProvider` sa na neho prepoji:
/// `ref.watch(contentDatabaseProvider.future)` v jeho tele, alebo override
/// `contentDbProvider.overrideWith((ref) => ref.watch(
/// contentDatabaseProvider.future))`.

final class ContentDatabaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentDb>,
          ContentDb,
          FutureOr<ContentDb>
        >
    with $FutureModifier<ContentDb>, $FutureProvider<ContentDb> {
  /// Otvorena, overena content.db (read-only). Po aktualizacii obsahu sa
  /// stare spojenie zavrie a otvori nove.
  ///
  /// D-02 `contentDbProvider` sa na neho prepoji:
  /// `ref.watch(contentDatabaseProvider.future)` v jeho tele, alebo override
  /// `contentDbProvider.overrideWith((ref) => ref.watch(
  /// contentDatabaseProvider.future))`.
  ContentDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'contentDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<ContentDb> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ContentDb> create(Ref ref) {
    return contentDatabase(ref);
  }
}

String _$contentDatabaseHash() => r'b469b6dc51ed775862c0157961afa9a97a3761fa';
