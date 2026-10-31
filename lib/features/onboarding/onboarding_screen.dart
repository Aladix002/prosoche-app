import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/features/onboarding/onboarding_controller.dart';
import 'package:prosoche/features/onboarding/onboarding_routes.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';
import 'package:prosoche/features/onboarding/steps/gate_steps.dart';
import 'package:prosoche/features/onboarding/steps/intention_step.dart';
import 'package:prosoche/features/onboarding/steps/notifications_step.dart';
import 'package:prosoche/features/onboarding/steps/privacy_step.dart';
import 'package:prosoche/features/onboarding/steps/welcome_step.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Pokracovanie po kroku: [skipped] = "Skip" alebo prazdny vyber.
typedef OnboardingNext = Future<void> Function({bool skipped});

/// Obrazovka kroku onboardingu (docs/02 A1): hlavicka s "Back", progresom
/// "Step x of n" a "Skip", pod nou obsah kroku.
///
/// Android back = predchadzajuci krok, na prvom kroku zavrie appku
/// (systemovo, predictive back cez [PopScope], docs/02 C5).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({required this.step, required this.flow, super.key});

  final OnboardingStep step;
  final OnboardingFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previous = flow.previous(step);

    Future<void> next({bool skipped = false}) async {
      final controller = ref.read(onboardingControllerProvider);
      var following = await controller.advance(step, skipped: skipped);
      // O5 bez appiek (Skip alebo prazdny vyber): povolenia brany netreba,
      // O6 sa preskoci (docs/02 O5 okrajove pripady).
      if (step == OnboardingStep.gateApps &&
          skipped &&
          following == OnboardingStep.permissions) {
        following = await controller.advance(following!, skipped: true);
      }
      if (following != null && context.mounted) {
        context.go(OnboardingRoutes.step(following.key));
      }
    }

    void back() {
      if (previous != null) context.go(OnboardingRoutes.step(previous.key));
    }

    return PopScope<Object?>(
      canPop: previous == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SkSpace.maxContentWidth,
              ),
              child: Column(
                children: [
                  _Header(
                    current: flow.number(step),
                    total: flow.total,
                    onBack: previous == null ? null : back,
                    onSkip: step.skippable ? () => next(skipped: true) : null,
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(step),
                      child: switch (step) {
                        OnboardingStep.welcome => WelcomeStep(onNext: next),
                        OnboardingStep.intention => IntentionStep(onNext: next),
                        OnboardingStep.notifications => NotificationsStep(
                          onNext: next,
                        ),
                        OnboardingStep.gateApps => GateAppsStep(onNext: next),
                        OnboardingStep.permissions => GatePermissionsStep(
                          onNext: next,
                        ),
                        OnboardingStep.privacy => const PrivacyStep(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.current,
    required this.total,
    required this.onBack,
    required this.onSkip,
  });

  final int current;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formats = ProsocheFormats(Localizations.localeOf(context));
    final progress = l10n.onbStepProgress(
      formats.number(current),
      formats.number(total),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space8,
        vertical: SkSpace.space4,
      ),
      child: Row(
        children: [
          // Ikona so 48 dp cielom (aj pri textScale 2.0 sa zmesti).
          SizedBox.square(
            dimension: SkSpace.minTouchTarget,
            child: onBack == null
                ? null
                : SkIconButton(
                    icon: Icons.arrow_back,
                    tooltip: l10n.onbBack,
                    onPressed: onBack,
                  ),
          ),
          const SizedBox(width: SkSpace.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(progress, style: context.sk.text.labelLarge),
                const SizedBox(height: SkSpace.space4),
                // Tichy segmentovy progres (D-05); text vyssie nesie
                // informaciu aj pre screen reader.
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 1; i <= total; i++) ...[
                        if (i > 1) const SizedBox(width: SkSpace.space4),
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: i <= current
                                  ? context.sk.colors.primary
                                  : context.sk.colors.outline,
                              borderRadius: BorderRadius.circular(
                                SkRadius.full,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onSkip != null)
            SkButton.tertiary(label: l10n.onbSkip, onPressed: onSkip)
          else
            const SizedBox(height: SkSpace.minTouchTarget),
        ],
      ),
    );
  }
}

/// Spolocne rozlozenie obsahu kroku: nadpis, text, obsah (scroll) a hlavne
/// tlacidlo dole.
class OnboardingStepBody extends StatelessWidget {
  const OnboardingStepBody({
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    this.body,
    this.leading = const [],
    this.children = const [],
    this.busy = false,
    this.icon,
    super.key,
  });

  /// Ikona kroku v medailone motivu nad nadpisom (D-05).
  final IconData? icon;

  final String title;
  final String? body;

  /// Obsah nad nadpisom (medailon v uvitani).
  final List<Widget> leading;
  final List<Widget> children;
  final String primaryLabel;

  /// null = tlacidlo je neaktivne.
  final VoidCallback? onPrimary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = context.sk.text;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SkSpace.space24,
              vertical: SkSpace.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...leading,
                if (icon != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkMotifBadge(icon: icon, size: 80),
                  ),
                  const SizedBox(height: SkSpace.space16),
                ],
                Semantics(
                  header: true,
                  child: Text(title, style: text.headlineSmall),
                ),
                if (body != null) ...[
                  const SizedBox(height: SkSpace.space8),
                  Text(body!, style: text.bodyLarge),
                ],
                const SizedBox(height: SkSpace.space16),
                ...children,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(SkSpace.space16),
          child: SkButton.primary(
            label: primaryLabel,
            onPressed: busy ? null : onPrimary,
            loading: busy,
            expand: true,
          ),
        ),
      ],
    );
  }
}
