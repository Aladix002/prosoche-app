import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_provider.g.dart';

/// Predvoleny logger. Bootstrap ho prepise instanciou s globalnymi sinkami.
@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) =>
    AppLogger(sinks: [RingBufferLog()], clock: ref.watch(appClockProvider));
