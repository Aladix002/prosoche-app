import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/core/logging/app_logger.dart';

part 'logger_provider.g.dart';

/// Predvoleny logger. Bootstrap ho prepise instanciou s globalnymi sinkami.
@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) =>
    AppLogger(sinks: [RingBufferLog()], clock: ref.watch(appClockProvider));
