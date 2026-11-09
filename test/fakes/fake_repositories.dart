// Fake repozitare D-02 pre widget testy obrazoviek (F-01, F-02, F-06,
// F-07). Drzia stav v pamati, zmeny posielaju do streamov a zaznamenavaju
// volania. Obsah je len placeholder (PLAN_VYVOJA 5.5).
//
//   await tester.pumpWidget(ProviderScope(
//     overrides: fakeRepositoryOverrides(today: LocalDate(2026, 10, 29)),
//     retry: (_, _) => null,
//     child: ...,
//   ));
import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/repositories/journey/week_repository.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/domain/streak/streak.dart';

import 'fake_library_repositories.dart';
import 'fake_week_repository.dart';
import 'in_memory_settings_repository.dart';

export 'fake_library_repositories.dart';
export 'fake_week_repository.dart';

/// Hodnota, ktora sa da sledovat (posledna hodnota + zmeny).
class _Watched<T> {
  _Watched(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast(sync: true);

  T get value => _value;
  set value(T v) {
    _value = v;
    _changes.add(v);
  }

  Stream<T> watch() async* {
    yield _value;
    yield* _changes.stream;
  }
}

/// `quote:q_NNNN` pre testy.
ContentCardId fakeQuoteId(int n) =>
    ContentCardId.quote('q_${n.toString().padLeft(4, '0')}');

/// Jednoducha sada s N placeholder kartami (intro + citaty).
DailySet fakeDailySet(LocalDate date, {int n = 10}) => DailySet(
  date: date,
  phase: DayPhase.morning,
  cards: [
    DailySetCard(pos: 1, cardId: IntroCardId(date), slot: Slot.intro),
    for (var i = 2; i <= n; i++)
      DailySetCard(pos: i, cardId: fakeQuoteId(i), slot: Slot.quote),
  ],
);

class FakeDailySetRepository implements DailySetRepository {
  FakeDailySetRepository({DailySet Function(LocalDate date)? build})
    : _build = build ?? fakeDailySet;

  final DailySet Function(LocalDate) _build;
  final _sets = <LocalDate, _Watched<DailySetState?>>{};

  /// Nastav na chybu generovania (stav error na Dnes).
  Exception? ensureError;
  final seen = <(LocalDate, CardId, CardContext)>[];
  final skipped = <CardId>[];

  _Watched<DailySetState?> _slot(LocalDate d) =>
      _sets.putIfAbsent(d, () => _Watched(null));

  /// Pripravi ulozenu sadu (napr. rozpracovanu alebo dokoncenu).
  // ignore: use_setters_to_change_properties
  void put(DailySetState state) => _slot(state.date).value = state;

  @override
  Future<LocalDate> activeSetDate(LocalDate localDate) async {
    final latest = _sets.entries
        .where((e) => e.value.value != null)
        .map((e) => e.key)
        .fold<LocalDate?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return latest != null && latest.isAfter(localDate) ? latest : localDate;
  }

  @override
  Future<DailySetState> ensure(
    LocalDate date, {
    bool shorterSet = false,
  }) async {
    if (ensureError case final e?) throw e;
    return _slot(date).value ??= DailySetState(set: _build(date), cursor: 0);
  }

  @override
  Future<DailySetState?> get(LocalDate date) async => _slot(date).value;

  @override
  Stream<DailySetState?> watch(LocalDate date) => _slot(date).watch();

  @override
  Future<int> inactiveDays(LocalDate date) async => 0;

  @override
  Future<SeenResult> markSeen(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  }) async {
    final newly = !seen.any((s) => s.$1 == date && s.$2 == card.cardId);
    seen.add((date, card.cardId, context));
    return _advance(date, card, newly: newly);
  }

  @override
  Future<SeenResult> markSkipped(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  }) async {
    skipped.add(card.cardId);
    return _advance(date, card, newly: true);
  }

  SeenResult _advance(
    LocalDate date,
    DailySetCard card, {
    required bool newly,
  }) {
    final s = _slot(date).value!;
    final cursor = card.pos == s.cursor + 1 ? card.pos : s.cursor;
    final last = s.set.contentCards.last.pos;
    final completedNow = !s.isCompleted && cursor >= last;
    _slot(date).value = DailySetState(
      set: s.set,
      cursor: cursor,
      startedAt: s.startedAt ?? DateTime(date.year, date.month, date.day, 9),
      completedAt: completedNow
          ? DateTime(date.year, date.month, date.day, 9, 10)
          : s.completedAt,
    );
    return SeenResult(
      newlySeen: newly,
      cursor: cursor,
      completedNow: completedNow,
    );
  }

  @override
  Future<void> markDoneShown(LocalDate date) async {}
}

class FakeQuestRepository implements QuestRepository {
  FakeQuestRepository({List<QuestView> Function(LocalDate date)? build})
    : _build = build ?? _defaults;

  final List<QuestView> Function(LocalDate) _build;
  final _quests = <LocalDate, _Watched<List<QuestView>>>{};
  final actChanges = <QuestStatus>[];

  static List<QuestView> _defaults(LocalDate date) => [
    QuestView(
      quest: DailyQuest(
        date: date,
        slot: QuestSlot.read,
        questId: GenericQuest.readCards.id,
        origin: QuestOrigin.generic,
        rule: GenericQuest.readCards.rule(5),
      ),
      status: QuestStatus.pending,
      progress: const QuestProgress(current: 0, target: 5),
    ),
    QuestView(
      quest: DailyQuest(
        date: date,
        slot: QuestSlot.learn,
        questId: GenericQuest.learnIdea.id,
        origin: QuestOrigin.generic,
        rule: GenericQuest.learnIdea.rule(1),
      ),
      status: QuestStatus.pending,
      progress: const QuestProgress(current: 0, target: 1),
    ),
    QuestView(
      quest: DailyQuest(
        date: date,
        slot: QuestSlot.act,
        questId: 'act.fake.placeholder',
        origin: QuestOrigin.weighted,
      ),
      status: QuestStatus.pending,
      title: '[PLACEHOLDER act quest]',
    ),
  ];

  _Watched<List<QuestView>> _slot(LocalDate d) =>
      _quests.putIfAbsent(d, () => _Watched(_build(d)));

  void put(LocalDate date, List<QuestView> quests) =>
      _slot(date).value = quests;

  @override
  Future<List<QuestView>> ensure(LocalDate date) async => _slot(date).value;

  @override
  Stream<List<QuestView>> watch(LocalDate date) => _slot(date).watch();

  @override
  Future<void> syncAuto(LocalDate date) async {}

  @override
  Future<void> setActStatus(LocalDate date, QuestStatus status) async {
    actChanges.add(status);
    _slot(date).value = [
      for (final q in _slot(date).value) _withAct(q, status, date),
    ];
  }
}

QuestView _withAct(QuestView q, QuestStatus status, LocalDate date) {
  if (q.slot != QuestSlot.act) return q;
  return QuestView(
    quest: q.quest,
    status: status,
    doneAt: status == QuestStatus.done
        ? DateTime(date.year, date.month, date.day, 12)
        : null,
    title: q.title,
    body: q.body,
  );
}

class FakeStreakRepository implements StreakRepository {
  FakeStreakRepository({StreakSummary? summary, List<DayLogEntry>? days})
    : _summary = _Watched(
        summary ??
            StreakSummary(
              state: StreakState(
                current: 5,
                longest: 9,
                graceLeft: 2,
                lastEvaluatedDate: LocalDate(2026, 10, 28),
              ),
              todayDone: false,
            ),
      ),
      _days = days ?? const [];

  final _Watched<StreakSummary> _summary;
  final List<DayLogEntry> _days;

  StreakSummary get summary => _summary.value;
  set summary(StreakSummary s) => _summary.value = s;

  @override
  Future<StreakSummary> evaluate(LocalDate today) async => _summary.value;

  @override
  Stream<StreakSummary> watch(LocalDate today) => _summary.watch();

  @override
  Stream<List<DayLogEntry>> watchDayLog(LocalDate from, LocalDate to) =>
      Stream.value([
        for (final d in _days)
          if (!d.date.isBefore(from) && !d.date.isAfter(to)) d,
      ]);
}

/// Obsah kariet: placeholder pre kazdy typ; [missing] vrati null.
class FakeCardContentRepository implements CardContentRepository {
  FakeCardContentRepository({this.missing = const {}});

  final Set<CardId> missing;

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    if (missing.contains(id)) return null;
    return switch (id) {
      IntroCardId(:final date) => IntroContent(id, date: date),
      ContentCardId(type: CardType.quote, :final key) => QuoteContent(
        id,
        text: '[PLACEHOLDER quote $key]',
        author: '[PLACEHOLDER author]',
        work: '[PLACEHOLDER work]',
        ref: '1.1',
        sourceId: 'fake',
        workId: 'fake-books',
        sectionKey: 'fake-books.1.1',
        translation: const Translation(
          translator: '[PLACEHOLDER translator]',
          year: 1862,
        ),
      ),
      ContentCardId(type: CardType.passage, :final key) => QuoteContent(
        id,
        text: '[PLACEHOLDER passage $key]',
        author: '[PLACEHOLDER author]',
        work: '[PLACEHOLDER work]',
        ref: '2.1',
        sourceId: 'fake',
      ),
      ContentCardId(type: CardType.practice, :final key) => PracticeContent(
        id,
        title: '[PLACEHOLDER practice $key]',
        text: '[PLACEHOLDER] step',
        sectionKey: 'fake-books.1.1',
      ),
      ContentCardId(type: CardType.prompt, :final key) => PromptContent(
        id,
        text: '[PLACEHOLDER prompt $key]?',
      ),
      ContentCardId(type: CardType.concept, :final key) => ConceptContent(
        id,
        title: '[PLACEHOLDER concept $key]',
        subtitle: 'term - gloss',
        text: '[PLACEHOLDER] explanation',
      ),
      ContentCardId(type: CardType.author, :final key) => AuthorContent(
        id,
        name: '[PLACEHOLDER author $key]',
        text: '[PLACEHOLDER] intro',
        firstWorkId: 'fake-books',
        firstWorkTitle: '[PLACEHOLDER] Work',
      ),
      ContentCardId() || DoneCardId() => null,
    };
  }
}

class FakeCardActionsRepository implements CardActionsRepository {
  final logged = <(CardId, CardAction, CardContext)>[];
  final _saved = _Watched<List<SavedCard>>(const []);

  @override
  Future<void> log(
    LocalDate date,
    CardId card,
    CardAction action, {
    required CardContext context,
    int? pos,
    int? value,
  }) async => logged.add((card, action, context));

  @override
  Future<void> save(
    LocalDate date,
    CardId card, {
    required CardContext context,
  }) async {
    logged.add((card, CardAction.saved, context));
    _saved.value = [
      SavedCard(card, DateTime(date.year, date.month, date.day)),
      ..._saved.value.where((s) => s.cardId != card),
    ];
  }

  @override
  Future<void> unsave(
    LocalDate date,
    CardId card, {
    required CardContext context,
  }) async {
    logged.add((card, CardAction.unsaved, context));
    _saved.value = [..._saved.value.where((s) => s.cardId != card)];
  }

  @override
  Stream<bool> watchIsSaved(CardId card) =>
      _saved.watch().map((l) => l.any((s) => s.cardId == card));

  @override
  Stream<List<SavedCard>> watchSaved({CardType? type}) => _saved.watch().map(
    (l) => [
      for (final s in l)
        if (type == null || s.cardId.type == type) s,
    ],
  );
}

/// Fakes, ktore [fakeRepositoryOverrides] pouzil (na kontrolu v testoch).
class FakeRepositories {
  FakeRepositories({
    SettingsRepository? settings,
    FakeDailySetRepository? dailySets,
    FakeQuestRepository? quests,
    FakeStreakRepository? streak,
    FakeCardContentRepository? cards,
    FakeCardActionsRepository? actions,
    FakeLibraryRepository? library,
    FakePracticeRepository? practice,
    FakeWeekRepository? week,
  }) : week = week ?? FakeWeekRepository(),
       library = library ?? FakeLibraryRepository(),
       practice = practice ?? FakePracticeRepository(),
       settings = settings ?? InMemorySettingsRepository(),
       dailySets = dailySets ?? FakeDailySetRepository(),
       quests = quests ?? FakeQuestRepository(),
       streak = streak ?? FakeStreakRepository(),
       cards = cards ?? FakeCardContentRepository(),
       actions = actions ?? FakeCardActionsRepository();

  final SettingsRepository settings;
  final FakeDailySetRepository dailySets;
  final FakeQuestRepository quests;
  final FakeStreakRepository streak;
  final FakeCardContentRepository cards;
  final FakeCardActionsRepository actions;
  final FakeLibraryRepository library;
  final FakePracticeRepository practice;
  final FakeWeekRepository week;

  /// Override vsetkych repozitarov, hodin, zony a jazyka zariadenia.
  /// Ziadna databaza ani content.db sa neotvara.
  List<Override> overrides({
    required DateTime now,
    String timeZone = 'Europe/Bratislava',
    String deviceLanguage = 'en',
  }) => [
    appClockProvider.overrideWithValue(Clock.fixed(now)),
    deviceTimeZoneProvider.overrideWith((ref) async => timeZone),
    deviceLanguageProvider.overrideWithValue(deviceLanguage),
    settingsRepositoryProvider.overrideWithValue(settings),
    dailySetRepositoryProvider.overrideWithValue(dailySets),
    questRepositoryProvider.overrideWithValue(quests),
    streakRepositoryProvider.overrideWithValue(streak),
    cardContentRepositoryProvider.overrideWithValue(cards),
    cardActionsRepositoryProvider.overrideWithValue(actions),
    libraryRepositoryProvider.overrideWithValue(library),
    practiceRepositoryProvider.overrideWithValue(practice),
    weekRepositoryProvider.overrideWithValue(week),
  ];
}

/// Skratka: overrides s predvolenymi fakes a casom [now].
List<Override> fakeRepositoryOverrides({DateTime? now}) =>
    FakeRepositories().overrides(now: now ?? DateTime(2026, 10, 29, 9));
