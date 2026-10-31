import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/practice/practice.dart';
import 'package:prosoche/features/practice/practice_routes.dart';
import 'package:prosoche/ui/ui.dart';

/// Practice (F-01): ranna priprava, vecerna reflexia, dennik, memento mori
/// a cvicenia z kariet `practice`. Vsetky texty cviceni su z content.db.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final today = ref.watch(localDateProvider);
    final done =
        ref.watch(practiceDoneProvider(today)).value ?? const <RoutineKind>{};
    final practices = ref.watch(practicesProvider);
    // Ranna priprava a vecerna reflexia su hore ako velke karty, v zozname
    // cviceni sa neopakuju (I-01).
    final routineIds = {
      for (final kind in RoutineKind.values)
        ?ref.watch(practiceRoutineProvider(kind)).value?.practice?.id.key,
    };
    final journal = ref.watch(journalProvider).value;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('practice:list'),
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          children: [
            SkScreenTitle(title: l10n.tabPractice),
            for (final kind in RoutineKind.values) ...[
              _RoutineTile(kind: kind, done: done.contains(kind)),
              const SizedBox(height: SkSpace.space12),
            ],
            _HubTile(
              key: const ValueKey('practice:journal'),
              icon: Icons.edit_note,
              title: l10n.journalTitle,
              subtitle: journal == null || journal.isEmpty
                  ? l10n.journalSubtitleEmpty
                  : l10n.journalSubtitleCount(journal.length),
              onTap: () => context.push(PracticeRoutes.journal),
            ),
            const SizedBox(height: SkSpace.space12),
            _HubTile(
              key: const ValueKey('practice:memento'),
              icon: Icons.hourglass_bottom,
              title: l10n.mementoTitle,
              subtitle: l10n.mementoSubtitle,
              onTap: () => context.push(PracticeRoutes.memento),
            ),
            const SizedBox(height: SkSpace.space24),
            Semantics(
              header: true,
              child: Text(
                l10n.practiceOtherExercises,
                style: sk.text.titleLarge,
              ),
            ),
            const SizedBox(height: SkSpace.space8),
            ...switch (practices) {
              AsyncValue(:final value?) => [
                for (final p in value)
                  if (!routineIds.contains(p.id.key))
                    ListTile(
                      key: ValueKey('exercise:${p.id.key}'),
                      contentPadding: EdgeInsetsDirectional.zero,
                      minTileHeight: SkSpace.minTouchTarget,
                      title: Text(p.title, style: sk.text.titleMedium),
                      subtitle: p.subtitle == null ? null : Text(p.subtitle!),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(PracticeRoutes.exercise(p.id.key)),
                    ),
              ],
              AsyncValue(hasError: true, isLoading: false) => [
                SkErrorState(
                  title: l10n.errorGeneric,
                  onRetry: () => ref.invalidate(practicesProvider),
                ),
              ],
              _ => [const SkLoadingView(skeleton: SkSkeleton.list())],
            },
          ],
        ),
      ),
    );
  }
}

/// Ranna priprava / vecerna reflexia s nadpisom cvicenia z obsahu.
class _RoutineTile extends ConsumerWidget {
  const _RoutineTile({required this.kind, required this.done});

  final RoutineKind kind;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final routine = ref.watch(practiceRoutineProvider(kind)).value;
    final practice = routine?.practice;
    final eyebrow = switch (kind) {
      RoutineKind.morning => l10n.practiceMorning,
      RoutineKind.evening => l10n.practiceEvening,
    };
    return Material(
      color: sk.colors.surface,
      borderRadius: BorderRadius.circular(SkRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('routine:${kind.tag}'),
        onTap: () => context.push(PracticeRoutes.routine(kind)),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: sk.text.labelMedium!.copyWith(
                        color: sk.colors.accentText,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: SkSpace.space4),
                    Text(
                      practice?.title ??
                          switch (kind) {
                            RoutineKind.morning => l10n.practiceMorningTitle,
                            RoutineKind.evening => l10n.practiceEveningTitle,
                          },
                      style: sk.text.headlineSmall,
                    ),
                    if (routine?.section?.reference case final r?)
                      Text(
                        r,
                        style: sk.text.bodyMedium!.copyWith(
                          color: sk.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (done)
                Semantics(
                  label: l10n.practiceDoneToday,
                  child: Icon(Icons.check_circle, color: sk.colors.success),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    // Rovnaky tvar a typografia ako karty rannej a vecernej praxe (I-01):
    // radius lg, serifovy nadpis, sekundarny podnadpis, ikona namiesto
    // eyebrow.
    return Material(
      color: sk.colors.surface,
      borderRadius: BorderRadius.circular(SkRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: sk.colors.accentText)),
              const SizedBox(width: SkSpace.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: sk.text.headlineSmall),
                    Text(
                      subtitle,
                      style: sk.text.bodyMedium!.copyWith(
                        color: sk.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
