import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/cards/types/text_cards.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/practice/widgets/practice_actions.dart';
import 'package:prosoche/ui/ui.dart';

/// Cvicenie z karty `practice` (F-01): postup (vlastny text z obsahu),
/// suvisiaca sekcia ("Read in context") a potvrdenie "I did this", ktore
/// splni `act` quest dna.
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({required this.cardKey, super.key});

  /// Cast `card.id` za `practice:`.
  final String cardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final all = ref.watch(practicesProvider);
    final p = all.value?.where((p) => p.id.key == cardKey).firstOrNull;
    final Widget body;
    if (all.hasError && !all.isLoading) {
      body = SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(practicesProvider),
      );
    } else if (!all.hasValue) {
      body = const SkLoadingView(skeleton: SkSkeleton.list());
    } else if (p == null) {
      body = SkEmptyState(
        icon: Icons.self_improvement,
        title: l10n.exerciseMissing,
      );
    } else {
      body = ListView(
        key: ValueKey('exercise:body:$cardKey'),
        padding: const EdgeInsetsDirectional.all(SkSpace.space16),
        children: [
          Semantics(
            header: true,
            child: Text(p.title, style: sk.text.headlineMedium),
          ),
          if (p.subtitle case final s?)
            Text(
              s,
              style: sk.text.titleMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          const SizedBox(height: SkSpace.space24),
          DefaultTextStyle.merge(
            style: sk.text.bodyLarge,
            child: PracticeSteps(steps: p.steps),
          ),
          if (p.sectionKey case final key?) ...[
            const SizedBox(height: SkSpace.space16),
            CardLink(
              label: p.reference == null
                  ? l10n.cardReadInContext
                  : l10n.cardReadReference(p.reference!),
              onPressed: () => unawaited(
                openReader(context, workId: workIdOfSection(key), section: key),
              ),
            ),
          ],
          const SizedBox(height: SkSpace.space24),
          SkButton.primary(
            key: const ValueKey('exercise:done'),
            label: l10n.practiceIDidThis,
            expand: true,
            onPressed: () => unawaited(_confirm(context, ref)),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.cardTypePractice.toUpperCase(),
          style: sk.text.labelLarge!.copyWith(
            color: sk.colors.accentText,
            letterSpacing: 1.4,
          ),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    await confirmPracticeDone(ref);
    if (context.mounted) {
      showSkSnackbar(context, message: context.l10n.practiceMarkedDone);
    }
  }
}
