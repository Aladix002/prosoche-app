import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

/// Vysledok posunu `reading_position` (docs/02 B2, A5.2, D7).
typedef ReadingAdvance = ({bool moved, int? khatmCompleted});

/// Posunie poziciu citania (khatm) na [ayah].
///
/// [strict] (reader, A5.2): len ak [ayah] je presne dalsi vers po pozicii.
/// Inak (feed a brana, B2): ak je [ayah] za poziciou
/// (`reading_position = max(...)`). Po 114:6 zapise `khatm_log` a pozicia
/// je 0 (dalsi vers 1:1). Pri prvom posune zacne khatm.
Future<ReadingAdvance> advanceReadingPosition(
  UserDb db,
  AyahId ayah,
  DateTime now, {
  required bool strict,
}) => db.transaction(() async {
  final dao = db.readingDao;
  final pos = await dao.readingPosition();
  final expected = pos == 0
      ? AyahId.first
      : (AyahId.tryFromValue(pos) ?? AyahId.last).next;
  final ok = strict ? ayah == expected : ayah.value > pos;
  if (!ok) return (moved: false, khatmCompleted: null);
  await dao.startKhatmIfNone(now);
  if (ayah == AyahId.last) {
    return (moved: true, khatmCompleted: await dao.completeKhatm(now));
  }
  await dao.setReadingPosition(ayah.value, now);
  return (moved: true, khatmCompleted: null);
});

/// `reading_position` ako [AyahId]; null = pred 1:1.
AyahId? readingPositionOf(int raw) =>
    raw == 0 ? null : AyahId.tryFromValue(raw);
