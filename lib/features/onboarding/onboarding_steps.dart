/// Kroky onboardingu (docs/02 A1, bez polohy a modlitieb). [key] je segment routy
/// `/onboarding/:step` a hodnota `settings.onboarding.step`.
enum OnboardingStep {
  welcome('welcome'),
  intention('intention'),
  notifications('notifications'),
  gateApps('gate_apps', gateOnly: true),
  permissions('permissions', gateOnly: true),
  privacy('privacy');

  OnboardingStep(this.key, {this.gateOnly = false});

  final String key;

  /// Len pri `FEATURE_GATE` (O5, O6); v `lite` ma onboarding 4 kroky.
  final bool gateOnly;

  /// Uvitanie a sukromie sa nedaju preskocit (sukromie je povinne
  /// rozhodnutie).
  bool get skippable => this != welcome && this != privacy;

  static OnboardingStep? tryParse(String? key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }
}

/// Poradie krokov pre zapnute funkcie.
final class OnboardingFlow {
  const OnboardingFlow({required this.gate});

  /// `FEATURE_GATE`: kroky O5 a O6.
  final bool gate;

  List<OnboardingStep> get steps => [
    for (final s in OnboardingStep.values)
      if (gate || !s.gateOnly) s,
  ];

  OnboardingStep get first => steps.first;

  int get total => steps.length;

  /// 1-based poradie kroku v tomto flow.
  int number(OnboardingStep step) => steps.indexOf(step) + 1;

  bool contains(OnboardingStep step) => steps.contains(step);

  OnboardingStep? next(OnboardingStep step) {
    final i = steps.indexOf(step);
    return i < 0 || i + 1 >= steps.length ? null : steps[i + 1];
  }

  OnboardingStep? previous(OnboardingStep step) {
    final i = steps.indexOf(step);
    return i <= 0 ? null : steps[i - 1];
  }

  /// Krok na obnovenie z ulozeneho `onboarding.step`. Krok, ktory v tomto
  /// flow nie je (brana v `lite`), sa nahradi najblizsim dalsim krokom.
  OnboardingStep resume(String? stored) {
    final step = OnboardingStep.tryParse(stored);
    if (step == null) return first;
    for (final s in OnboardingStep.values.skip(step.index)) {
      if (contains(s)) return s;
    }
    return first;
  }
}
