import 'dart:async';

import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/ramadan/ramadan.dart';

/// Fake [FastLogRepository] pre widget testy (bez databazy).
class FakeFastLogRepository implements FastLogRepository {
  final entries = <LocalDate, FastEntry>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<FastEntry?> watch(LocalDate date) async* {
    yield entries[date];
    await for (final _ in _changes.stream) {
      yield entries[date];
    }
  }

  @override
  Future<void> set(LocalDate date, FastEntry? entry) async {
    if (entry == null) {
      entries.remove(date);
    } else {
      entries[date] = entry;
    }
    _changes.add(null);
  }
}
