import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakina/core/logging/logger_provider.dart';
import 'package:sakina/data/blocker/blocker_api.pigeon.dart';
import 'package:sakina/data/blocker/blocker_gateway.dart';
import 'package:sakina/data/blocker/pigeon_blocker_gateway.dart';

part 'blocker_gateway_provider.g.dart';

/// Nativny blocker. V testoch prepisat cez
/// `blockerGatewayProvider.overrideWithValue(FakeBlockerGateway(...))`.
@Riverpod(keepAlive: true)
BlockerGateway blockerGateway(Ref ref) =>
    PigeonBlockerGateway(BlockerHostApi(), ref.watch(appLoggerProvider));
