import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:prosoche/core/l10n/generated/app_localizations.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/home_widget/daily_quote.dart';

/// Pocet dni dopredu, ktore widget dostane: po polnoci si nativny widget
/// vyberie zaznam pre novy den sam, bez spustenia Fluttera. Ked appka
/// dlhsie nebezi, widget strieda tieto zaznamy podla datumu.
const widgetScheduleDays = 45;

/// Verzia formatu dat pre nativny widget (`DailyQuoteWidget.kt`).
const widgetPayloadVersion = 1;

/// Deep link widgetu: citacka na sekcii citatu so zvyraznenym textom
/// (`prosoche://reader/<work>?section=<key>&hl=<text>`), bez diela Today.
String widgetDeepLink(QuoteContent q) {
  final workId = q.workId;
  if (workId == null) return 'prosoche://today';
  return Uri(
    scheme: 'prosoche',
    host: 'reader',
    path: '/$workId',
    queryParameters: {
      if (q.sectionKey != null) 'section': q.sectionKey,
      'hl': q.text,
    },
  ).toString();
}

/// Data pre widget (JSON v `DailyQuoteWidget.kt`): popisky z ARB
/// a citat dna od vcerajska po [days] dni od [today].
Future<Map<String, Object?>?> buildWidgetPayload({
  required ContentDb db,
  required LocalDate today,
  required AppLocalizations l10n,
  Set<String> disabled = const {},
  int days = widgetScheduleDays,
}) async {
  final rows = await db.cardDao.allCards();
  final pool = widgetQuotePool([
    for (final r in rows)
      if (r.type == CardType.quote.wire) (id: r.id, text: r.textContent),
  ], disabled: disabled);
  final byId = {for (final r in rows) r.id: r};
  final cache = <String, Map<String, Object?>?>{};

  Future<Map<String, Object?>?> entry(String id) async {
    final row = byId[id];
    final cid = CardId.tryParse(id);
    if (row == null || cid is! ContentCardId) return null;
    final c = await contentFromRow(db, cid, row);
    if (c is! QuoteContent) return null;
    final t = c.translation;
    return {
      'card': id,
      'text': c.text.trim(),
      'reference': c.reference,
      'author': c.author,
      'translatedBy': t == null || t.translator.isEmpty
          ? null
          : t.year == null
          ? l10n.cardTranslatedBy(t.translator)
          : l10n.cardTranslatedByYear(t.translator, t.year!),
      'link': widgetDeepLink(c),
    };
  }

  final out = <Map<String, Object?>>[];
  // Od vcera: po zmene casovej zony na zapad widget ukaze ten isty citat
  // dna ako appka, nie nahradny zo striedania.
  for (var i = -1; i < days; i++) {
    final date = today.addDays(i);
    final id = dailyQuoteId(date, pool);
    if (id == null) break;
    final e = cache.containsKey(id) ? cache[id] : cache[id] = await entry(id);
    if (e != null) out.add({'date': '$date', ...e});
  }
  if (out.isEmpty) return null;
  return {
    'v': widgetPayloadVersion,
    'labels': {
      'eyebrow': l10n.widgetEyebrow,
      'readInContext': l10n.cardReadInContext,
      'openApp': l10n.widgetOpenApp,
    },
    'days': out,
  };
}

/// Kanal k nativnemu widgetu (`MainActivity.kt`, len hlavny engine).
class HomeWidgetChannel {
  const HomeWidgetChannel([this._channel = const MethodChannel(name)]);

  static const name = 'app.prosoche/widget';

  final MethodChannel _channel;

  /// Ulozi data widgetu a prekresli vsetky jeho instancie. false = platforma
  /// widget nema (testy, iOS).
  Future<bool> update(Map<String, Object?> payload) async {
    try {
      return await _channel.invokeMethod<bool>('update', jsonEncode(payload)) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }
}
