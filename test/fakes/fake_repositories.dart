// Fake repozitare D-02 pre widget testy obrazoviek (F-01, F-02, F-04,
// F-05). Drzia stav v pamati, zmeny posielaju do streamov a zaznamenavaju
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
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/domain/streak/streak.dart';

import 'in_memory_settings_repository.dart';

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

/// Jednoducha sada s N placeholder kartami (intro + versy).
DailySet fakeDailySet(LocalDate date, {int n = 10}) => DailySet(
  date: date,
  phase: DayPhase.morning,
  cards: [
    DailySetCard(pos: 1, cardId: IntroCardId(date), slot: Slot.intro),
    for (var i = 2; i <= n; i++)
      DailySetCard(
        pos: i,
        cardId: AyahCardId(AyahId(2, i)),
        slot: Slot.ayah,
        khatm: true,
      ),
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
        questId: GenericQuest.readVerses.id,
        origin: QuestOrigin.generic,
        rule: GenericQuest.readVerses.rule(10),
      ),
      status: QuestStatus.pending,
      progress: const QuestProgress(current: 0, target: 10),
    ),
    QuestView(
      quest: DailyQuest(
        date: date,
        slot: QuestSlot.learn,
        questId: GenericQuest.learnCards.id,
        origin: QuestOrigin.generic,
        rule: GenericQuest.learnCards.rule(1),
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

/// Poloha Bratislava pre testy modlitieb.
final fakeBratislava = PrayerLocation(
  lat: 48.15,
  lng: 17.11,
  country: 'SK',
  tz: 'Europe/Bratislava',
  city: 'Bratislava',
);

class FakePrayerRepository implements PrayerRepository {
  FakePrayerRepository({PrayerLocation? location}) {
    ensureTimeZoneData();
    if (location != null) {
      _config.value = PrayerConfig(
        location,
        CalcSettings.resolve(lat: location.lat, country: location.country),
      );
    }
  }

  final _config = _Watched<PrayerConfig?>(null);
  final _logs = <LocalDate, _Watched<Map<Prayer, PrayerStatus>>>{};

  /// Pocet volani, ktore maju preplanovat notifikacie (F-05 DoD).
  int changes = 0;

  _Watched<Map<Prayer, PrayerStatus>> _log(LocalDate d) =>
      _logs.putIfAbsent(d, () => _Watched(const {}));

  void _update(CalcSettings Function(CalcSettings s) f) {
    final c = _config.value;
    if (c != null) _config.value = PrayerConfig(c.location, f(c.settings));
    changes++;
  }

  @override
  Future<PrayerConfig?> config() async => _config.value;

  @override
  Stream<PrayerConfig?> watchConfig() => _config.watch();

  @override
  Future<void> saveLocation(
    PrayerLocation location, {
    bool resetAsr = false,
  }) async {
    final s =
        _config.value?.settings ??
        CalcSettings.resolve(lat: location.lat, country: location.country);
    _config.value = PrayerConfig(location, s);
    changes++;
  }

  CalcSettings _with(
    CalcSettings s, {
    PrayerMethod? method,
    AsrMadhab? asr,
    HighLatRule? rule,
    Map<Prayer, int>? adjust,
  }) => CalcSettings(
    method: method ?? s.method,
    asr: asr ?? s.asr,
    highLatRule: rule ?? s.highLatRule,
    adjust: adjust ?? s.adjust,
  );

  @override
  Future<void> setMethod(PrayerMethod? method) async => _update(
    (s) => _with(
      s,
      method:
          method ??
          CalcSettings.resolve(
            lat: _config.value!.location.lat,
            country: _config.value!.location.country,
          ).method,
    ),
  );

  @override
  Future<void> setAsr(AsrMadhab asr) async =>
      _update((s) => _with(s, asr: asr));

  @override
  Future<void> setHighLatRule(HighLatRule? rule) async =>
      _update((s) => _with(s, rule: rule ?? HighLatRule.middleOfNight));

  @override
  Future<void> setAdjust(Prayer prayer, int minutes) async =>
      _update((s) => _with(s, adjust: {...s.adjust, prayer: minutes}));

  @override
  Stream<Map<Prayer, PrayerStatus>> watchLog(LocalDate date) =>
      _log(date).watch();

  @override
  Future<void> setStatus(
    LocalDate date,
    Prayer prayer,
    PrayerStatus status,
  ) async => _log(date).value = {..._log(date).value, prayer: status};

  @override
  Future<void> clearStatus(LocalDate date, Prayer prayer) async =>
      _log(date).value = {..._log(date).value}..remove(prayer);
}

class FakeCityRepository implements CityRepository {
  FakeCityRepository([List<City>? cities])
    : cities =
          cities ??
          const [
            City(
              id: 1,
              name: 'Bratislava',
              countryCode: 'SK',
              countryName: 'Slovakia',
              lat: 48.15,
              lng: 17.11,
              tz: 'Europe/Bratislava',
            ),
            City(
              id: 2,
              name: 'Sarajevo',
              countryCode: 'BA',
              countryName: 'Bosnia and Herzegovina',
              lat: 43.85,
              lng: 18.36,
              tz: 'Europe/Sarajevo',
            ),
          ];

  final List<City> cities;

  @override
  Future<List<City>> search(String prefix, {int limit = 30}) async {
    final p = prefix.trim().toLowerCase();
    if (p.isEmpty) return const [];
    return cities
        .where((c) => c.name.toLowerCase().startsWith(p))
        .take(limit)
        .toList();
  }

  @override
  Future<City?> nearest(double lat, double lng) async => cities.firstOrNull;
}

class FakeCalendarRepository implements CalendarRepository {
  FakeCalendarRepository({
    List<EventRule> rules = const [],
    this.texts = const {},
    this.offset = 0,
  }) : _rules = List.unmodifiable(rules);

  final List<EventRule> _rules;

  /// `event_id` -> titulok (len `en`).
  final Map<String, String> texts;
  int offset;

  EventResolver get _resolver =>
      EventResolver(_rules, IslamicCalendar(offset: offset));

  @override
  Future<IslamicCalendar> calendar() async => IslamicCalendar(offset: offset);

  @override
  Future<HijriDate> hijriDate(LocalDate date) async =>
      IslamicCalendar(offset: offset).hijriOf(date);

  @override
  Future<EventResolution> resolve(LocalDate date) async =>
      _resolver.resolve(date);

  @override
  Future<CalendarMonth> month(int year, int month) async {
    final r = _resolver;
    return CalendarMonth(
      year: year,
      month: month,
      days: [
        for (final d in r.calendar.daysOfMonth(year, month))
          CalendarDay(
            date: d,
            hijri: r.calendar.hijriOf(d),
            eventIds: [for (final e in r.resolve(d).active) e.id],
          ),
      ],
    );
  }

  @override
  Future<EventText?> eventText(
    String eventId,
    String lang, {
    bool allowEnFallback = false,
  }) async {
    final title = texts[eventId];
    if (title == null || (lang != 'en' && !allowEnFallback)) return null;
    return EventText(eventId: eventId, lang: 'en', title: title);
  }
}

/// Placeholder Koran: sury 1 a 2, preklad len `en`.
class FakeQuranRepository implements QuranRepository {
  final _position = _Watched<AyahId?>(null);
  final _counts = _Watched<Map<int, int>>(const {});
  final read = <(AyahId, ReaderMode)>[];
  final selected = <String, TranslationSource>{};

  static const sources = [
    TranslationSource(
      id: 'fake-en',
      lang: 'en',
      name: 'Fake translation',
      version: '1',
      attribution: '[PLACEHOLDER attribution]',
      license: 'test-only',
    ),
  ];

  static SurahInfo _surah(int id) => SurahInfo(
    id: id,
    nameAr: '[PLACEHOLDER name_ar $id]',
    nameTranslit: 'Placeholder $id',
    nameMeaning: '[PLACEHOLDER meaning $id]',
    revelationPlace: 'meccan',
    ayahCount: AyahId.ayahCount(id),
    bismillahPre: id != 1 && id != 9,
  );

  static AyahView _ayah(AyahId id, String lang) => AyahView(
    id: id,
    textUthmani: '[PLACEHOLDER uthmani ${id.surah}:${id.ayah}]',
    juz: 1,
    page: 1,
    translation: lang == 'ar'
        ? null
        : TranslationText(
            text: '[PLACEHOLDER translation ${id.surah}:${id.ayah}]',
            sourceId: 'fake-en',
            lang: 'en',
            isFallback: lang != 'en',
          ),
  );

  AyahId? get position => _position.value;
  set position(AyahId? id) => _position.value = id;

  @override
  Future<List<SurahInfo>> surahs(String lang) async => [_surah(1), _surah(2)];

  @override
  Future<SurahInfo?> surah(int id, String lang) async =>
      id >= 1 && id <= AyahId.surahCount ? _surah(id) : null;

  @override
  Future<List<JuzStart>> juzStarts() async => [(juz: 1, firstAyahId: 1001)];

  @override
  Future<List<AyahView>> ayahsOfSurah(
    int surahId, {
    required String lang,
  }) async => [
    for (var a = 1; a <= AyahId.ayahCount(surahId); a++)
      _ayah(AyahId(surahId, a), lang),
  ];

  @override
  Future<List<AyahView>> ayahs(
    Iterable<AyahId> ids, {
    required String lang,
  }) async => [for (final id in ids) _ayah(id, lang)];

  @override
  Future<List<TranslationSource>> translationSources(String lang) async =>
      lang == 'en' ? sources : const [];

  @override
  Future<TranslationSource?> selectedTranslation(String lang) async =>
      selected[lang] ?? (await translationSources(lang)).firstOrNull;

  @override
  Future<void> selectTranslation(String lang, TranslationSource source) async =>
      selected[lang] = source;

  @override
  Future<QuranSearchResult> search(String query, {required String lang}) async {
    final m = RegExp(r'^(\d{1,3}):(\d{1,3})$').firstMatch(query.trim());
    if (m != null && AyahId.isValid(int.parse(m[1]!), int.parse(m[2]!))) {
      return QuranSearchResult(
        reference: AyahId(int.parse(m[1]!), int.parse(m[2]!)),
      );
    }
    return QuranSearchResult();
  }

  @override
  Stream<AyahId?> watchReadingPosition() => _position.watch();

  @override
  Stream<Map<int, int>> watchReadCounts() => _counts.watch();

  @override
  Future<int> completedKhatms() async => 0;

  @override
  Future<ReadResult> markRead(
    AyahId ayah, {
    required ReaderMode mode,
    required LocalDate date,
  }) async {
    read.add((ayah, mode));
    final expected = _position.value?.next ?? AyahId.first;
    final moved = mode == ReaderMode.khatm && ayah == expected;
    if (moved) _position.value = ayah == AyahId.last ? null : ayah;
    return (
      newlySeen: true,
      moved: moved,
      khatmCompleted: moved && ayah == AyahId.last ? 1 : null,
    );
  }
}

/// Obsah kariet: placeholder pre kazdy typ; [missing] vrati null.
class FakeCardContentRepository implements CardContentRepository {
  FakeCardContentRepository({this.missing = const {}});

  final Set<CardId> missing;
  final _quran = FakeQuranRepository();

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    if (missing.contains(id)) return null;
    // Ako ContentCardRepository (BF-01): v `ar` je arabsky original sam
    // textom, preklad nabozenskeho textu sa nedoplna z `en`.
    final ar = lang == 'ar';
    return switch (id) {
      IntroCardId(:final date) => IntroContent(
        id,
        date: date,
        hijri: IslamicCalendar().hijriOf(date),
      ),
      AyahCardId(:final ayahId) => AyahContent(
        id,
        ayah: (await _quran.ayahs([ayahId], lang: lang)).single,
        surah: (await _quran.surah(ayahId.surah, lang))!,
        arabicOnly: ar,
      ),
      HadithCardId() => HadithContent(
        id,
        textAr: '[PLACEHOLDER hadith ar]',
        grade: 'sahih',
        collection: '[PLACEHOLDER collection]',
        sourceId: 'fake',
        lang: ar ? null : lang,
        text: ar ? null : '[PLACEHOLDER hadith]',
        arabicOnly: ar,
      ),
      DuaCardId() => DuaContent(
        id,
        textAr: '[PLACEHOLDER dua ar]',
        sourceRef: 'example:1',
        repeatCount: 1,
        lang: ar ? null : lang,
        text: ar ? null : '[PLACEHOLDER dua]',
        arabicOnly: ar,
      ),
      NameCardId() => NameContent(
        id,
        textAr: '[PLACEHOLDER name ar]',
        lang: ar ? null : lang,
        meaning: ar ? null : '[PLACEHOLDER meaning]',
        arabicOnly: ar,
      ),
      ReflectionCardId() => ReflectionContent(
        id,
        lang: lang,
        text: '[PLACEHOLDER reflection]',
      ),
      EventCardId(:final eventId) => EventContent(
        id,
        text: EventText(
          eventId: eventId,
          lang: lang,
          title: '[PLACEHOLDER event]',
        ),
      ),
      KhatmCardId() => KhatmContent(id),
      WordCardId() || QuizCardId() || DoneCardId() => null,
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
    FakePrayerRepository? prayer,
    FakeCityRepository? cities,
    FakeCalendarRepository? calendar,
    FakeQuranRepository? quran,
    FakeCardContentRepository? cards,
    FakeCardActionsRepository? actions,
  }) : settings = settings ?? InMemorySettingsRepository(),
       dailySets = dailySets ?? FakeDailySetRepository(),
       quests = quests ?? FakeQuestRepository(),
       streak = streak ?? FakeStreakRepository(),
       prayer = prayer ?? FakePrayerRepository(),
       cities = cities ?? FakeCityRepository(),
       calendar = calendar ?? FakeCalendarRepository(),
       quran = quran ?? FakeQuranRepository(),
       cards = cards ?? FakeCardContentRepository(),
       actions = actions ?? FakeCardActionsRepository();

  final SettingsRepository settings;
  final FakeDailySetRepository dailySets;
  final FakeQuestRepository quests;
  final FakeStreakRepository streak;
  final FakePrayerRepository prayer;
  final FakeCityRepository cities;
  final FakeCalendarRepository calendar;
  final FakeQuranRepository quran;
  final FakeCardContentRepository cards;
  final FakeCardActionsRepository actions;

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
    prayerRepositoryProvider.overrideWithValue(prayer),
    cityRepositoryProvider.overrideWithValue(cities),
    calendarRepositoryProvider.overrideWithValue(calendar),
    quranRepositoryProvider.overrideWithValue(quran),
    cardContentRepositoryProvider.overrideWithValue(cards),
    cardActionsRepositoryProvider.overrideWithValue(actions),
  ];
}

/// Skratka: overrides s predvolenymi fakes a casom [now].
List<Override> fakeRepositoryOverrides({DateTime? now}) =>
    FakeRepositories().overrides(now: now ?? DateTime(2026, 10, 29, 9));
