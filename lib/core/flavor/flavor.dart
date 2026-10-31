import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flavor.g.dart';

/// Prostredie (plan 16.1), Android dimenzia `env`.
enum Flavor {
  dev,
  prod;

  bool get isDev => this == Flavor.dev;
}

/// Edicia, Android dimenzia `edition`. `lite` = produkcia B bez brany,
/// `full` = s nativnym blockerom (PLAN_VYVOJA 0, S-01b).
enum Edition {
  lite,
  full;

  bool get isFull => this == Edition.full;
}

/// Prepisane v bootstrape podla `appFlavor`.
@Riverpod(keepAlive: true)
Flavor flavor(Ref ref) => Flavor.dev;

/// Prepisane v bootstrape podla `appFlavor`.
@Riverpod(keepAlive: true)
Edition edition(Ref ref) => Edition.lite;

/// Prostredie z `--flavor` (`devLite`, `prodFull`, ...). Bez flavoru `dev`.
Flavor flavorFromName(String? name) =>
    (name ?? '').toLowerCase().startsWith('prod') ? Flavor.prod : Flavor.dev;

/// Edicia z `--flavor` (`devLite`, `prodFull`, ...). Bez flavoru `lite`.
Edition editionFromName(String? name) =>
    (name ?? '').toLowerCase().endsWith('full') ? Edition.full : Edition.lite;
