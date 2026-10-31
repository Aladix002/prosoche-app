import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/features/shell/tab_placeholder.dart';

/// Practice: ranna priprava, vecerna reflexia a dalsie cvicenia. Zatial
/// placeholder, implementuje F-01 (PLAN.md kap. 2).
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TabPlaceholder(
      key: const ValueKey('practice:placeholder'),
      title: l10n.tabPractice,
      icon: Icons.self_improvement_outlined,
      body: l10n.practicePlaceholderBody,
    );
  }
}
