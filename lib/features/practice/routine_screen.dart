import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/practice.dart';
import 'package:prosoche/features/cards/types/text_cards.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/practice/widgets/journal_widgets.dart';
import 'package:prosoche/features/practice/widgets/practice_actions.dart';
import 'package:prosoche/ui/ui.dart';

/// Ranna priprava / vecerna reflexia (F-01): suvisiaca sekcia diela
/// (napr. Meditations 2.1, On Anger 3.36) doslovne z content.db, postup
/// cvicenia a otazky do lokalneho dennika. "Done" oznaci prax dna a splni
/// `act` quest (potvrdenie pouzivatelom).
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({required this.kind, super.key});

  final RoutineKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final routine = ref.watch(practiceRoutineProvider(kind));
    final eyebrow = switch (kind) {
      RoutineKind.morning => l10n.practiceMorning,
      RoutineKind.evening => l10n.practiceEvening,
    };
    final Widget body;
    if (routine.hasError && !routine.isLoading) {
      body = SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(practiceRoutineProvider(kind)),
      );
    } else if (!routine.hasValue) {
      body = const SkLoadingView(skeleton: SkSkeleton.list());
    } else {
      body = _RoutineBody(routine: routine.requireValue, eyebrow: eyebrow);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          eyebrow.toUpperCase(),
          style: sk.text.labelLarge!.copyWith(
            color: sk.colors.accentText,
            letterSpacing: 1.4,
          ),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _RoutineBody extends ConsumerWidget {
  const _RoutineBody({required this.routine, required this.eyebrow});

  final PracticeRoutine routine;
  final String eyebrow;

  Future<void> _done(BuildContext context, WidgetRef ref, bool done) async {
    await ref
        .read(practiceRepositoryProvider)
        .setDone(routine.date, routine.kind, done: !done);
    if (!done) await confirmPracticeDone(ref);
    if (!context.mounted || done) return;
    showSkSnackbar(context, message: context.l10n.practiceMarkedDone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final practice = routine.practice;
    final section = routine.section;
    final done =
        (ref.watch(practiceDoneProvider(routine.date)).value ??
                const <RoutineKind>{})
            .contains(routine.kind);
    final repo = ref.read(practiceRepositoryProvider);
    return ListView(
      key: ValueKey('routine:body:${routine.kind.tag}'),
      padding: const EdgeInsetsDirectional.all(SkSpace.space16),
      children: [
        Semantics(
          header: true,
          child: Text(
            practice?.title ??
                switch (routine.kind) {
                  RoutineKind.morning => l10n.practiceMorningTitle,
                  RoutineKind.evening => l10n.practiceEveningTitle,
                },
            style: sk.text.headlineMedium,
          ),
        ),
        if (practice?.subtitle case final s?)
          Text(
            s,
            style: sk.text.titleMedium!.copyWith(
              color: sk.colors.textSecondary,
            ),
          ),
        if (section != null) ...[
          const SizedBox(height: SkSpace.space24),
          _SectionQuote(section: section),
        ],
        if (practice != null) ...[
          const SizedBox(height: SkSpace.space24),
          DefaultTextStyle.merge(
            style: sk.text.bodyLarge,
            child: PracticeSteps(steps: practice.steps),
          ),
        ],
        if (routine.questions.isNotEmpty) ...[
          const SizedBox(height: SkSpace.space32),
          Semantics(
            header: true,
            child: Text(l10n.journalTitle, style: sk.text.titleLarge),
          ),
          const SizedBox(height: SkSpace.space12),
          for (final q in routine.questions) ...[
            _AnswerField(routine: routine, question: q, repo: repo),
            const SizedBox(height: SkSpace.space12),
          ],
          const JournalPrivacyNote(),
        ],
        const SizedBox(height: SkSpace.space24),
        if (done)
          SkButton.secondary(
            key: const ValueKey('routine:undo'),
            label: l10n.practiceDoneToday,
            icon: Icons.check,
            expand: true,
            onPressed: () => unawaited(_done(context, ref, done)),
          )
        else
          SkButton.primary(
            key: const ValueKey('routine:done'),
            label: l10n.practiceMarkDone,
            expand: true,
            onPressed: () => unawaited(_done(context, ref, done)),
          ),
      ],
    );
  }
}

/// Sekcia diela k praxi (cely text, referencia, prekladatel).
class _SectionQuote extends ConsumerWidget {
  const _SectionQuote({required this.section});

  final LibrarySection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final works = ref.watch(libraryAuthorsProvider).value;
    final work = works
        ?.expand((a) => a.works)
        .where((w) => w.id == section.workId)
        .firstOrNull;
    final style = sk.type.translation.copyWith(color: sk.colors.lead);
    return SkCardSurface(
      variant: SkCardVariant.compact,
      eyebrow: section.reference,
      translation: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, p) in section.paragraphs.indexed) ...[
            if (i > 0) const SizedBox(height: SkSpace.space12),
            Text(p, style: style),
          ],
        ],
      ),
      attribution: work == null
          ? null
          : [
              work.author,
              translatedBy(
                context,
                Translation(
                  translator: work.translator,
                  year: work.editionYear,
                ),
              ),
            ].join(' · '),
      footer: CardLink(
        label: l10n.cardReadInContext,
        onPressed: () => unawaited(
          openReader(context, workId: section.workId, section: section.key),
        ),
      ),
    );
  }
}

class _AnswerField extends ConsumerWidget {
  const _AnswerField({
    required this.routine,
    required this.question,
    required this.repo,
  });

  final PracticeRoutine routine;
  final RoutineQuestion question;
  final PracticeRepository repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(
      _answerProvider((routine.date, routine.kind, question)),
    );
    if (!existing.hasValue) return const SizedBox(height: 96);
    return JournalField(
      key: ValueKey('answer:${question.id}'),
      label: question.text,
      initial: existing.value?.body ?? '',
      onSave: (text) =>
          repo.saveAnswer(routine.date, routine.kind, question, text),
    );
  }
}

/// Ulozena odpoved na otazku dna (pociatocny text pola).
final FutureProviderFamily<
  JournalEntry?,
  (LocalDate, RoutineKind, RoutineQuestion)
>
_answerProvider = FutureProvider.autoDispose
    .family<JournalEntry?, (LocalDate, RoutineKind, RoutineQuestion)>(
      (ref, k) => ref.read(practiceRepositoryProvider).answer(k.$1, k.$2, k.$3),
      name: 'routineAnswerProvider',
    );
