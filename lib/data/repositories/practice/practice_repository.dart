import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/cards/card_content_repository.dart';
import 'package:prosoche/data/repositories/library/library_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/practice.dart';

/// Otazka dennika (z obsahu: vety z textu cvicenia alebo karta `prompt`).
@immutable
final class RoutineQuestion {
  const RoutineQuestion({required this.id, required this.text});

  /// `card.id` otazky, alebo `<card.id>#<n>` pre otazku z textu cvicenia.
  final String id;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is RoutineQuestion && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(id, text);
}

/// Ranna priprava / vecerna reflexia dna: cvicenie, suvisiaca sekcia
/// (napr. Meditations 2.1, On Anger 3.36) a otazky do dennika.
@immutable
final class PracticeRoutine {
  const PracticeRoutine({
    required this.kind,
    required this.date,
    required this.questions,
    this.practice,
    this.section,
  });

  final RoutineKind kind;
  final LocalDate date;
  final PracticeContent? practice;
  final LibrarySection? section;
  final List<RoutineQuestion> questions;
}

/// Zaznam lokalneho dennika.
@immutable
final class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.kind,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.promptId,
    this.prompt,
  });

  final int id;
  final LocalDate date;
  final JournalKind kind;
  final String? promptId;
  final String? prompt;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Practice (F-01): rutiny z content.db, lokalny dennik a dokoncene praxe
/// v user.db. Dennik nikdy neopusti zariadenie (ziadna analytika, ziadne
/// logy s textom), je v exporte ([exportJournal]) a v "Delete all my data".
abstract interface class PracticeRepository {
  Future<PracticeRoutine> routine(RoutineKind kind, LocalDate date);

  /// Vsetky cvicenia (`practice`) v poradi `ord`.
  Future<List<PracticeContent>> practices();

  Stream<List<JournalEntry>> watchJournal();

  /// Odpoved na otazku [question] dna (null = este nie je).
  Future<JournalEntry?> answer(
    LocalDate date,
    RoutineKind kind,
    RoutineQuestion question,
  );

  /// Ulozi odpoved; prazdny text odpoved zmaze.
  Future<void> saveAnswer(
    LocalDate date,
    RoutineKind kind,
    RoutineQuestion question,
    String body,
  );

  /// Poznamka do dennika (volna, alebo odpoved na kartu `prompt`).
  Future<void> addNote(
    LocalDate date,
    String body, {
    String? promptId,
    String? prompt,
  });

  Future<void> deleteEntry(int id);

  Future<void> deleteJournal();

  /// Cely dennik ako text (export pouzivatelom cez share sheet).
  Future<String> exportJournal({required String title});

  Stream<Set<RoutineKind>> watchDone(LocalDate date);

  Future<void> setDone(LocalDate date, RoutineKind kind, {required bool done});
}

/// [PracticeRepository] nad content.db a user.db.
class DriftPracticeRepository implements PracticeRepository {
  DriftPracticeRepository({
    required this._content,
    required UserDb userDb,
    required this._library,
    this._clock = const Clock(),
  }) : _user = userDb;

  final Future<ContentDb> _content;
  final UserDb _user;
  final LibraryRepository _library;
  final Clock _clock;

  /// Cvicenia rutin podla kontraktu (prosoche-content `curated/`).
  static const Map<RoutineKind, String> routinePracticeIds = {
    RoutineKind.morning: 'practice:morning-preparation',
    RoutineKind.evening: 'practice:evening-review',
  };

  /// Kolko otazok ma rutina v dennik.
  static const questionCount = 3;

  static final LocalDate _epoch = LocalDate(2020, 1, 1);

  static JournalKind journalKind(RoutineKind k) => switch (k) {
    RoutineKind.morning => JournalKind.morning,
    RoutineKind.evening => JournalKind.evening,
  };

  @override
  Future<PracticeRoutine> routine(RoutineKind kind, LocalDate date) async {
    final db = await _content;
    final practice = await _practiceFor(db, kind);
    final section = practice?.sectionKey == null
        ? null
        : await _library.section(practice!.sectionKey!);
    final questions = <RoutineQuestion>[
      if (practice != null)
        for (final (i, q) in questionsIn(practice.text).indexed)
          RoutineQuestion(id: '${practice.id}#${i + 1}', text: q),
    ];
    if (questions.length < questionCount) {
      final prompts = [
        for (final r in await db.cardDao.ofType('prompt'))
          if (_tags(r.tags).contains(kind.tag)) r,
      ];
      for (final r in rotate(
        prompts,
        date.daysSince(_epoch),
        questionCount - questions.length,
      )) {
        questions.add(RoutineQuestion(id: r.id, text: r.textContent));
      }
    }
    return PracticeRoutine(
      kind: kind,
      date: date,
      practice: practice,
      section: section,
      questions: questions.take(questionCount).toList(),
    );
  }

  Future<PracticeContent?> _practiceFor(ContentDb db, RoutineKind kind) async {
    final rows = await db.cardDao.ofType('practice');
    final row =
        rows.where((r) => r.id == routinePracticeIds[kind]).firstOrNull ??
        rows.where((r) => _tags(r.tags).contains(kind.tag)).firstOrNull;
    if (row == null) return null;
    final c = await contentFromRow(
      db,
      CardId.parse(row.id) as ContentCardId,
      row,
    );
    return c is PracticeContent ? c : null;
  }

  static List<String> _tags(String json) =>
      RegExp('"([a-z_]+)"').allMatches(json).map((m) => m[1]!).toList();

  @override
  Future<List<PracticeContent>> practices() async {
    final db = await _content;
    final out = <PracticeContent>[];
    for (final r in await db.cardDao.ofType('practice')) {
      final id = CardId.tryParse(r.id);
      if (id is! ContentCardId) continue;
      if (await contentFromRow(db, id, r) case final PracticeContent c) {
        out.add(c);
      }
    }
    return out;
  }

  @override
  Stream<List<JournalEntry>> watchJournal() =>
      _user.journalDao.watchAll().map((rows) => rows.map(_entry).toList());

  static JournalEntry _entry(JournalEntryRow r) => JournalEntry(
    id: r.id,
    date: r.date,
    kind: r.kind,
    promptId: r.promptId,
    prompt: r.prompt,
    body: r.body,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  @override
  Future<JournalEntry?> answer(
    LocalDate date,
    RoutineKind kind,
    RoutineQuestion question,
  ) async {
    final r = await _user.journalDao.find(
      date,
      journalKind(kind),
      promptId: question.id,
    );
    return r == null ? null : _entry(r);
  }

  @override
  Future<void> saveAnswer(
    LocalDate date,
    RoutineKind kind,
    RoutineQuestion question,
    String body,
  ) async {
    final text = body.trim();
    final dao = _user.journalDao;
    final existing = await dao.find(
      date,
      journalKind(kind),
      promptId: question.id,
    );
    if (existing != null) {
      if (text.isEmpty) {
        await dao.remove(existing.id);
      } else if (existing.body != text) {
        await dao.updateBody(existing.id, text, _clock.now());
      }
      return;
    }
    if (text.isEmpty) return;
    await dao.add(
      date: date,
      kind: journalKind(kind),
      body: text,
      now: _clock.now(),
      promptId: question.id,
      prompt: question.text,
    );
  }

  @override
  Future<void> addNote(
    LocalDate date,
    String body, {
    String? promptId,
    String? prompt,
  }) async {
    final text = body.trim();
    if (text.isEmpty) return;
    await _user.journalDao.add(
      date: date,
      kind: JournalKind.note,
      body: text,
      now: _clock.now(),
      promptId: promptId,
      prompt: prompt,
    );
  }

  @override
  Future<void> deleteEntry(int id) => _user.journalDao.remove(id);

  @override
  Future<void> deleteJournal() => _user.journalDao.deleteAll();

  @override
  Future<String> exportJournal({required String title}) async {
    final out = StringBuffer(title);
    LocalDate? day;
    for (final e in (await _user.journalDao.all()).map(_entry)) {
      if (e.date != day) {
        day = e.date;
        out.write('\n\n$day');
      }
      out.write('\n\n');
      if (e.prompt case final p?) out.write('$p\n');
      out.write(e.body);
    }
    return out.toString();
  }

  @override
  Stream<Set<RoutineKind>> watchDone(LocalDate date) => _user.journalDao
      .watchDone(date)
      .map(
        (kinds) => {
          for (final k in RoutineKind.values)
            if (kinds.contains(journalKind(k))) k,
        },
      );

  @override
  Future<void> setDone(
    LocalDate date,
    RoutineKind kind, {
    required bool done,
  }) => done
      ? _user.journalDao.markDone(date, journalKind(kind), _clock.now())
      : _user.journalDao.unmarkDone(date, journalKind(kind));
}
