import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/practice/practice.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/types/text_cards.dart';
import 'package:prosoche/features/practice/widgets/journal_widgets.dart';
import 'package:prosoche/features/practice/widgets/practice_actions.dart';
import 'package:prosoche/ui/ui.dart';

/// Memento mori (F-01): tyzdne zivota. Rok narodenia je volitelny
/// a zostava len v zariadeni (`practice.birth_year`, nie je v analytike).
/// Text cvicenia je karta `practice:memento-mori` z content.db.
class MementoMoriScreen extends ConsumerWidget {
  const MementoMoriScreen({super.key});

  static const practiceId = 'practice:memento-mori';

  Future<void> _editYear(
    BuildContext context,
    WidgetRef ref,
    int? current,
  ) async {
    final l10n = context.l10n;
    final today = ref.read(localDateProvider);
    final text = await showTextInputDialog(
      context,
      title: l10n.mementoBirthYear,
      saveLabel: l10n.journalSave,
      initial: current?.toString() ?? '',
      helper: l10n.mementoBirthYearHelp,
      keyboardType: TextInputType.number,
      maxLines: 1,
      fieldKey: const ValueKey('memento:yearField'),
      saveKey: const ValueKey('memento:yearSave'),
    );
    final y = int.tryParse(text?.trim() ?? '');
    if (y == null || !LifeInWeeks.isValidBirthYear(y, today)) return;
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingsKeys.practiceBirthYear, y);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final year = ref.watch(settingOf(SettingsKeys.practiceBirthYear)).value;
    final today = ref.watch(localDateProvider);
    final practice = ref
        .watch(practicesProvider)
        .value
        ?.where((p) => p.id.format() == practiceId)
        .firstOrNull;
    final weeks = year != null && LifeInWeeks.isValidBirthYear(year, today)
        ? LifeInWeeks(birthYear: year, today: today)
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mementoTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('memento:list'),
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          children: [
            if (practice != null) ...[
              DefaultTextStyle.merge(
                style: sk.text.bodyLarge,
                child: PracticeSteps(steps: practice.steps),
              ),
              const SizedBox(height: SkSpace.space24),
            ],
            if (weeks == null)
              SkButton.secondary(
                key: const ValueKey('memento:setYear'),
                label: l10n.mementoAddYear,
                expand: true,
                onPressed: () => unawaited(_editYear(context, ref, year)),
              )
            else ...[
              Text(
                l10n.mementoWeeks(weeks.livedWeeks, weeks.totalWeeks),
                style: sk.text.titleMedium,
              ),
              const SizedBox(height: SkSpace.space12),
              Semantics(
                label: l10n.mementoGridA11y(
                  weeks.livedWeeks,
                  weeks.remainingWeeks,
                ),
                child: ExcludeSemantics(
                  child: LifeGrid(
                    lived: weeks.livedWeeks,
                    total: weeks.totalWeeks,
                    perRow: LifeInWeeks.weeksPerYear,
                  ),
                ),
              ),
              const SizedBox(height: SkSpace.space8),
              Text(
                l10n.mementoNote,
                style: sk.text.bodySmall!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
              Wrap(
                spacing: SkSpace.space8,
                children: [
                  TextButton(
                    key: const ValueKey('memento:editYear'),
                    onPressed: () => unawaited(_editYear(context, ref, year)),
                    child: Text(l10n.mementoChangeYear),
                  ),
                  TextButton(
                    key: const ValueKey('memento:clearYear'),
                    onPressed: () => unawaited(
                      ref
                          .read(settingsRepositoryProvider)
                          .reset(SettingsKeys.practiceBirthYear),
                    ),
                    child: Text(l10n.mementoClearYear),
                  ),
                ],
              ),
            ],
            const SizedBox(height: SkSpace.space8),
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: sk.colors.textSecondary,
                  ),
                ),
                const SizedBox(width: SkSpace.space8),
                Expanded(
                  child: Text(
                    l10n.mementoPrivacy,
                    style: sk.text.bodySmall!.copyWith(
                      color: sk.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SkSpace.space24),
            SkButton.primary(
              key: const ValueKey('memento:done'),
              label: l10n.practiceIDidThis,
              expand: true,
              onPressed: () => unawaited(_confirm(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    await confirmPracticeDone(ref);
    if (context.mounted) {
      showSkSnackbar(context, message: context.l10n.practiceMarkedDone);
    }
  }
}

/// Mriezka tyzdnov (jeden riadok = jeden rok). Len vizual, informaciu
/// nesie text a Semantics label nad nou.
class LifeGrid extends StatelessWidget {
  const LifeGrid({
    required this.lived,
    required this.total,
    required this.perRow,
    super.key,
  });

  final int lived;
  final int total;
  final int perRow;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / perRow;
        final rows = (total / perRow).ceil();
        return CustomPaint(
          size: Size(box.maxWidth, cell * rows),
          painter: _LifeGridPainter(
            lived: lived,
            total: total,
            perRow: perRow,
            filled: c.primary,
            empty: c.outline,
          ),
        );
      },
    );
  }
}

class _LifeGridPainter extends CustomPainter {
  _LifeGridPainter({
    required this.lived,
    required this.total,
    required this.perRow,
    required this.filled,
    required this.empty,
  });

  final int lived;
  final int total;
  final int perRow;
  final Color filled;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / perRow;
    final dot = cell * 0.7;
    final on = Paint()..color = filled;
    final off = Paint()..color = empty;
    for (var i = 0; i < total; i++) {
      final x = (i % perRow) * cell;
      final y = (i ~/ perRow) * cell;
      canvas.drawRect(Rect.fromLTWH(x, y, dot, dot), i < lived ? on : off);
    }
  }

  @override
  bool shouldRepaint(_LifeGridPainter old) =>
      old.lived != lived ||
      old.total != total ||
      old.filled != filled ||
      old.empty != empty;
}
