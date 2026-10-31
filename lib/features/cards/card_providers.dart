import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';

/// Zdroj prekladu `(lang, sourceId)` pre atribuciu versa (docs/02 B0.4);
/// null = zdroj nie je v content.db.
final FutureProviderFamily<TranslationSource?, (String, String)>
translationSourceProvider =
    FutureProvider.family<TranslationSource?, (String, String)>((
      ref,
      key,
    ) async {
      final sources = await ref
          .watch(quranRepositoryProvider)
          .translationSources(key.$1);
      for (final s in sources) {
        if (s.id == key.$2) return s;
      }
      return null;
    }, name: 'translationSourceProvider');

/// Atribucia zdroja obsahu karty z tabulky `source` v content.db
/// (docs/09: HadeethEnc vyzaduje "HadeethEnc.com" a cislo verzie).
@immutable
final class CardSourceInfo {
  const CardSourceInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.attribution,
  });

  /// `source.id`, napr. `hadeethenc-en`.
  final String id;
  final String name;

  /// `source.version`, napr. `snapshot-2026-10-29`.
  final String version;

  /// `source.attribution`, text pre obrazovku Zdroje (doslovne z DB).
  final String attribution;
}

/// Zdroj `source.id` z content.db; null = riadok chyba.
final FutureProviderFamily<CardSourceInfo?, String> cardSourceProvider =
    FutureProvider.family<CardSourceInfo?, String>((ref, id) async {
      final db = await ref.watch(contentDbProvider.future);
      final row = await db.contentMetaDao.source(id);
      if (row == null) return null;
      return CardSourceInfo(
        id: row.id,
        name: row.name,
        version: row.version,
        attribution: row.attribution,
      );
    }, name: 'cardSourceProvider');

/// Sura v jazyku obsahu (nazov pre eventovu kartu).
final FutureProviderFamily<SurahInfo?, int> surahInfoProvider =
    FutureProvider.family<SurahInfo?, int>((ref, surah) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      return await ref.watch(quranRepositoryProvider).surah(surah, lang);
    }, name: 'surahInfoProvider');

/// Sura eventovej karty z `card_overrides_json` (napr. al-Kahf v piatok);
/// null = event bez sury.
final FutureProviderFamily<int?, EventCardId> eventSurahProvider =
    FutureProvider.family<int?, EventCardId>((ref, id) async {
      final events = await ref.watch(activeEventsProvider(id.date).future);
      for (final e in events) {
        if (e.id == id.eventId) return e.effect.surah;
      }
      return null;
    }, name: 'eventSurahProvider');
