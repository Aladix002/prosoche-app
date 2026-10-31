import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/event_effect.dart';

/// Islamsky event aktivny v dany den (vystup EventResolver, E-01).
///
/// Pri kolizii vyhrava vyssia [priority] (docs/03 5.2). Texty eventu su
/// v `islamic_event_text`, tu je len identita a ucinok.
@immutable
final class ActiveEvent {
  const ActiveEvent({
    required this.id,
    required this.effect,
    this.priority = 0,
    this.mode,
  });

  /// `islamic_event.id` (TEXT, napr. `jumuah`, `white_days`).
  final String id;

  final EventEffect effect;

  final int priority;

  /// Specialny rezim appky (napr. `ramadan`), inak null.
  final String? mode;

  @override
  bool operator ==(Object other) =>
      other is ActiveEvent &&
      other.id == id &&
      other.priority == priority &&
      other.mode == mode &&
      other.effect == effect;

  @override
  int get hashCode => Object.hash(id, priority, mode, effect);

  @override
  String toString() => 'ActiveEvent($id, priority: $priority, mode: $mode)';
}
