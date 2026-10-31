import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show ComparableExpr;
import 'package:meta/meta.dart';
import 'package:prosoche/data/db/user_db.dart' as db;
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/infra/card_events.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Quest dna na zobrazenie (A2, SkQuestItem).
@immutable
final class QuestView {
  const QuestView({
    required this.quest,
    required this.status,
    this.doneAt,
    this.progress,
    this.title,
    this.body,
  });

  final DailyQuest quest;
  final QuestStatus status;

  /// Lokalny cas splnenia.
  final DateTime? doneAt;

  /// Progres `read`/`learn` z `card_event`; null pre `act`.
  final QuestProgress? progress;

  /// Text sablony (`quest_text`) v jazyku obsahu; null pre [GenericQuest]
  /// (UI pouzije `generic.arbKey` s parametrom `count` = [genericCount]).
  final String? title;
  final String? body;

  QuestSlot get slot => quest.slot;
  GenericQuest? get generic => quest.generic;
  int? get genericCount => quest.generic == null ? null : quest.target;
  bool get isDone => status == QuestStatus.done;
}

/// Denne questy (plan 7.2, A2): vyber raz za den, auto-splnenie z
/// `card_event`, self report `act`.
abstract interface class QuestRepository {
  /// Questy dna [date]; pri prvom volani ich vyberie a ulozi do
  /// `quest_log` (dalsie zmeny nastaveni ich uz nemenia, A10.8).
  Future<List<QuestView>> ensure(LocalDate date);

  /// Ako [ensure] a potom kazda zmena (quest_log, card_event).
  Stream<List<QuestView>> watch(LocalDate date);

  /// Oznaci splnene auto questy (`done_at` = cas udalosti, ktora dosiahla
  /// ciel). Volat po zapise `card_event`.
  Future<void> syncAuto(LocalDate date);

  /// `act`: [QuestStatus.done] ("I did it"), [QuestStatus.skipped] alebo
  /// [QuestStatus.pending] (Undo).
  Future<void> setActStatus(LocalDate date, QuestStatus status);
}

class DriftQuestRepository implements QuestRepository {
  DriftQuestRepository({
    required db.UserDb userDb,
    required this._catalog,
    required this._installId,
    required this._language,
    required this._clock,
    this._engine = const QuestEngine(),
    this._ensureSet,
  }) : _db = userDb;

  final db.UserDb _db;
  final ContentCatalog _catalog;
  final Future<String> Function() _installId;
  final Future<String> Function() _language;
  final Clock _clock;
  final QuestEngine _engine;

  /// Vytvori dennu sadu dna, ak este nie je (`DailySetRepository.ensure`).
  /// Vola sa pred prvym vyberom, aby ciel generickeho "Read {count} cards"
  /// ([GenericQuest.countFor]) vznikol uz zo sady a pocas dna sa nemenil
  /// (P-01). Chyba sa ignoruje (ciel potom default, kym sada nie je).
  final Future<void> Function(LocalDate date)? _ensureSet;

  final _inFlight = <LocalDate, Future<void>>{};

  Future<List<DailyQuest>> _select(LocalDate date, String lang) async {
    final history = await (_db.select(
      _db.questLogs,
    )..where((t) => t.date.isSmallerThanValue(date.toString()))).get();
    return _engine.select(
      QuestSelectionInput(
        date: date,
        seed: QuestEngine.daySeed(await _installId(), date),
        lang: lang,
        templates: await _catalog.questTemplates(),
        history: [
          for (final r in history)
            QuestLogEntry(
              date: r.date,
              slot: QuestSlot.fromWire(r.slot.wire)!,
              questId: r.questId,
              status: _status(r.status),
            ),
        ],
        setCards: await _setCards(date),
      ),
    );
  }

  /// Citaty a uryvky v ulozenej dennej sade [date]; null, kym sada nie je.
  Future<int?> _setCards(LocalDate date) async {
    final row = await _db.dailySetDao.byDate(date);
    if (row == null) return null;
    try {
      return DailySet.decode(row.cardsJson, date: row.date).cards
          .where((c) => GenericQuest.readCards.types.contains(c.cardId.type))
          .length;
    } on FormatException {
      return null;
    }
  }

  Future<void> _assign(LocalDate date) => _inFlight[date] ??= () async {
    try {
      if ((await _db.questLogDao.forDate(date)).isNotEmpty) return;
      await _ensureSetQuietly(date);
      final quests = await _select(date, await _language());
      await _db.questLogDao.assignIfAbsent(date, {
        for (final q in quests)
          db.QuestSlotKind.values.byName(q.slot.wire): q.questId,
      });
    } finally {
      unawaited(_inFlight.remove(date));
    }
  }();

  Future<void> _ensureSetQuietly(LocalDate date) async {
    final ensureSet = _ensureSet;
    if (ensureSet == null) return;
    try {
      await ensureSet(date);
    } on Object {
      // Napr. starsi den nez posledna sada (StateError) alebo chyba obsahu:
      // quest sa vyberie bez sady, settled() drzi ciel po splneni.
    }
  }

  @override
  Future<List<QuestView>> ensure(LocalDate date) async {
    await _assign(date);
    return await _views(
      date,
      await _db.questLogDao.forDate(date),
      await _db.cardEventDao.forDate(date),
    );
  }

  @override
  Stream<List<QuestView>> watch(LocalDate date) async* {
    await _assign(date);
    final events = (_db.select(
      _db.cardEvents,
    )..where((t) => t.date.equalsValue(date))).watch();
    final logs = _db.questLogDao.watchForDate(date);
    List<db.QuestLogRow>? lastLogs;
    List<db.CardEventRow>? lastEvents;
    final controller =
        StreamController<(List<db.QuestLogRow>, List<db.CardEventRow>)>();
    final subs = [
      logs.listen((l) {
        lastLogs = l;
        if (lastEvents != null) controller.add((l, lastEvents!));
      }, onError: controller.addError),
      events.listen((e) {
        lastEvents = e;
        if (lastLogs != null) controller.add((lastLogs!, e));
      }, onError: controller.addError),
    ];
    try {
      await for (final (l, e) in controller.stream) {
        final views = await _views(date, l, e);
        yield views;
        // Ciel sa moze znizit az po vygenerovani sady (setCards), bez
        // noveho card_event: splneny quest sa zapise aj tu.
        await _markDone(date, views);
      }
    } finally {
      for (final s in subs) {
        await s.cancel();
      }
      await controller.close();
    }
  }

  Future<List<QuestView>> _views(
    LocalDate date,
    List<db.QuestLogRow> rows,
    List<db.CardEventRow> events,
  ) async {
    if (rows.isEmpty) return const [];
    final lang = await _language();
    final selected = {for (final q in await _select(date, lang)) q.slot: q};
    final setCards = await _setCards(date);
    final templates = {
      for (final t in await _catalog.questTemplates()) t.id: t,
    };
    final texts = await (await _catalog.db).curatedDao.questTextsFor(
      rows.map((r) => r.questId),
      lang,
    );
    final activities = cardActivities(events);
    final out = <QuestView>[];
    for (final r in rows) {
      final slot = QuestSlot.fromWire(r.slot.wire)!;
      final doneAt = r.status == db.QuestStatus.done
          ? r.doneAt?.toLocal()
          : null;
      final quest = _engine.settled(
        _quest(date, slot, r.questId, selected[slot], templates, setCards),
        doneAt: doneAt,
        events: activities,
      );
      final text = texts[r.questId];
      out.add(
        QuestView(
          quest: quest,
          status: _status(r.status),
          doneAt: r.doneAt?.toLocal(),
          progress: _engine.progress(quest, activities),
          title: quest.generic == null ? text?.title : null,
          body: quest.generic == null ? text?.body : null,
        ),
      );
    }
    out.sort((a, b) => a.slot.index.compareTo(b.slot.index));
    return out;
  }

  /// Ulozeny quest: ak sa zhoduje s dnesnym vyberom, ma jeho parametre;
  /// inak (zmeneny obsah) sa poskladá zo sablony s prvou volbou parametrov.
  DailyQuest _quest(
    LocalDate date,
    QuestSlot slot,
    String questId,
    DailyQuest? selected,
    Map<String, QuestTemplate> templates,
    int? setCards,
  ) {
    if (selected != null && selected.questId == questId) return selected;
    final generic = GenericQuest.fromId(questId);
    if (generic != null) {
      return DailyQuest(
        date: date,
        slot: slot,
        questId: questId,
        origin: QuestOrigin.generic,
        rule: generic.rule(generic.countFor(setCards: setCards)),
      );
    }
    final t = templates[questId];
    return DailyQuest(
      date: date,
      slot: slot,
      questId: questId,
      origin: QuestOrigin.weighted,
      rule: t?.rule,
      params: {
        if (t != null)
          for (final MapEntry(:key, :value) in t.params.entries)
            key: value.first,
      },
    );
  }

  @override
  Future<void> syncAuto(LocalDate date) async =>
      await _markDone(date, await ensure(date));

  Future<void> _markDone(LocalDate date, List<QuestView> views) async {
    for (final v in views) {
      final done = v.progress?.completedAt;
      if (done != null && v.status == QuestStatus.pending) {
        await _db.questLogDao.setStatus(
          date,
          db.QuestSlotKind.values.byName(v.slot.wire),
          db.QuestStatus.done,
          at: done.toUtc(),
        );
      }
    }
  }

  @override
  Future<void> setActStatus(LocalDate date, QuestStatus status) async {
    await _assign(date);
    await _db.questLogDao.setStatus(
      date,
      db.QuestSlotKind.act,
      switch (status) {
        QuestStatus.pending => db.QuestStatus.open,
        QuestStatus.done => db.QuestStatus.done,
        QuestStatus.skipped => db.QuestStatus.skipped,
      },
      at: _clock.now().toUtc(),
    );
  }

  static QuestStatus _status(db.QuestStatus s) => switch (s) {
    db.QuestStatus.open => QuestStatus.pending,
    db.QuestStatus.done => QuestStatus.done,
    db.QuestStatus.skipped => QuestStatus.skipped,
  };
}
