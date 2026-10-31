import 'package:drift/drift.dart';
import 'package:prosoche/domain/common/common.dart';

/// Enum s textovou hodnotou v DB (`wire`), napr. `on_time`.
abstract interface class WireEnum {
  String get wire;
}

/// Mapuje [WireEnum] na TEXT stlpec. Neznama hodnota je chyba DB (CHECK).
///
/// Vsetky konvertory pouzivaju rovnaky tvar aj v JSON (`toJson` data tried,
/// export F-09): `wire`, ISO datum, ms od epochy UTC.
class WireEnumConverter<T extends WireEnum> extends TypeConverter<T, String>
    with JsonTypeConverter<T, String> {
  const WireEnumConverter(this.values);

  final List<T> values;

  @override
  T fromSql(String fromDb) => values.firstWhere(
    (v) => v.wire == fromDb,
    orElse: () => throw StateError('Unknown enum value in DB: $fromDb'),
  );

  @override
  String toSql(T value) => value.wire;
}

/// [CardType] z `lib/domain/common` ako TEXT (`card_event.type`).
class CardTypeConverter extends TypeConverter<CardType, String>
    with JsonTypeConverter<CardType, String> {
  const CardTypeConverter();

  @override
  CardType fromSql(String fromDb) =>
      CardType.fromWire(fromDb) ??
      (throw StateError('Unknown card type in DB: $fromDb'));

  @override
  String toSql(CardType value) => value.wire;
}

/// [LocalDate] ako ISO TEXT `YYYY-MM-DD` (triedi sa lexikograficky).
class LocalDateConverter extends TypeConverter<LocalDate, String>
    with JsonTypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toString();
}

/// Okamih ako INTEGER milisekundy od epochy (UTC). Citanie vracia UTC.
class UtcMillisConverter extends TypeConverter<DateTime, int>
    with JsonTypeConverter<DateTime, int> {
  const UtcMillisConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}
