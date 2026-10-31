import 'package:flutter/services.dart';
import 'package:sakina/bootstrap.dart';
import 'package:sakina/core/flavor/flavor.dart';

/// Jediny entrypoint. Flavor sa cita z `flutter run/build --flavor X`,
/// X = devLite, devFull, prodLite, prodFull (Flutter `appFlavor`).
Future<void> main() =>
    bootstrap(flavorFromName(appFlavor), edition: editionFromName(appFlavor));
