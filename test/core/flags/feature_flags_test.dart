import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/flavor/flavor.dart';

void main() {
  test('all flags are off without --dart-define', () {
    expect(FeatureFlags.fromEnvironment, FeatureFlags.none);
    expect(FeatureFlags.none.gate, isFalse);
  });

  test('lite edition never enables the gate', () {
    expect(FeatureFlags.all.forEdition(Edition.lite).gate, isFalse);
    expect(FeatureFlags.all.forEdition(Edition.full), FeatureFlags.all);
  });

  test('copyWith, equality, toString', () {
    final f = FeatureFlags.none.copyWith(gate: true);
    expect(f.copyWith(gate: false), FeatureFlags.none);
    expect(f.copyWith(), f);
    expect(f.hashCode, FeatureFlags.all.hashCode);
    expect(f, isNot(FeatureFlags.none));
    expect(f.toString(), contains('gate: true'));
  });

  test('provider follows edition', () {
    final lite = ProviderContainer();
    addTearDown(lite.dispose);
    expect(lite.read(featureFlagsProvider).gate, isFalse);

    final full = ProviderContainer(
      overrides: [editionProvider.overrideWithValue(Edition.full)],
    );
    addTearDown(full.dispose);
    expect(full.read(featureFlagsProvider), FeatureFlags.fromEnvironment);
  });

  test('flavor and edition from appFlavor', () {
    for (final (name, flavor, edition) in [
      ('devLite', Flavor.dev, Edition.lite),
      ('devFull', Flavor.dev, Edition.full),
      ('prodLite', Flavor.prod, Edition.lite),
      ('prodFull', Flavor.prod, Edition.full),
      (null, Flavor.dev, Edition.lite),
    ]) {
      expect(flavorFromName(name), flavor, reason: name);
      expect(editionFromName(name), edition, reason: name);
    }
    expect(Flavor.dev.isDev, isTrue);
    expect(Edition.full.isFull, isTrue);
  });
}
