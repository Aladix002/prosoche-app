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
      // D-01: uvitanie so znackou (portal) a grecke slovo s vyznamom.
      leading: const [
        SizedBox(height: SkSpace.space24),
        Center(child: SkPortalMark(size: 96)),
        SizedBox(height: SkSpace.space24),
      ],
      titleStyle: text.displaySmall,
      subtitle: l10n.onbWelcomeMeaning,
      title: l10n.appTitle,
      body: l10n.onbWelcomeBody,
      primaryLabel: l10n.onbContinue,
      onPrimary: onNext,
      children: [Text(l10n.onbWelcomeNote, style: text.bodyMedium)],
    );
  }
}
