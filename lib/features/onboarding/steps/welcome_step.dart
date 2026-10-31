import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/ui/ui.dart';

/// O1 Uvitanie (docs/02 A1). v1 ma len EN, vyber jazyka nie je.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.sk.text;
    return OnboardingStepBody(
      leading: const [
        // D-05: uvitanie s medailonom motivu (pomaly sa dokresli).
        Center(child: SkMotifBadge(size: 112, animate: true)),
        SizedBox(height: SkSpace.space16),
      ],
      title: l10n.appTitle,
      body: l10n.onbWelcomeBody,
      primaryLabel: l10n.onbContinue,
      onPrimary: onNext,
      children: [Text(l10n.onbWelcomeNote, style: text.bodyMedium)],
    );
  }
}
