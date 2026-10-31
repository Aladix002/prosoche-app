import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/onboarding/onboarding_controller.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/ui/ui.dart';

/// O7 Sukromie a analytika (docs/02 A1, docs/01 7.2). Dve samostatne
/// volby (anonymne pouzivanie, hlasenie chyb) s rovnocennymi tlacidlami,
/// obe default nie; dostupne az po potvrdeni veku 16+. "Finish" je
/// aktivne vzdy (nevybrate = nie) a dokonci onboarding.
class PrivacyStep extends ConsumerStatefulWidget {
  const PrivacyStep({super.key});

  @override
  ConsumerState<PrivacyStep> createState() => _PrivacyStepState();
}

class _PrivacyStepState extends ConsumerState<PrivacyStep> {
  bool _age = false;
  bool? _analytics;
  bool? _crash;
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingControllerProvider)
          .finish(
            ageConfirmed: _age,
            analytics: _analytics ?? false,
            crashReports: _crash ?? false,
          );
      if (mounted) context.go(AppRoutes.today);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _whatWeCollect() => showSkInfoSheet<void>(
    context,
    title: context.l10n.onbWhatWeCollect,
    child: Text(context.l10n.onbWhatWeCollectBody),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.sk.text;
    return OnboardingStepBody(
      icon: Icons.lock_outline,
      title: l10n.onbPrivacyTitle,
      primaryLabel: l10n.onbFinish,
      busy: _busy,
      onPrimary: _finish,
      children: [
        _Point(icon: Icons.person_off_outlined, text: l10n.onbPrivacyPoint1),
        _Point(icon: Icons.phone_android, text: l10n.onbPrivacyPoint2),
        const SizedBox(height: SkSpace.space8),
        CheckboxListTile(
          key: const ValueKey('privacy:age'),
          contentPadding: EdgeInsetsDirectional.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.onbAgeConfirm),
          subtitle: _age ? null : Text(l10n.onbAgeNote),
          value: _age,
          onChanged: (v) => setState(() {
            _age = v ?? false;
            if (!_age) _analytics = _crash = null;
          }),
        ),
        const SizedBox(height: SkSpace.space8),
        _Choice(
          id: 'analytics',
          title: l10n.onbAnalyticsTitle,
          body: l10n.onbAnalyticsBody,
          yes: l10n.onbAnalyticsYes,
          no: l10n.onbAnalyticsNo,
          value: _analytics,
          enabled: _age,
          onChanged: (v) => setState(() => _analytics = v),
        ),
        const SizedBox(height: SkSpace.space16),
        _Choice(
          id: 'crash',
          title: l10n.onbCrashTitle,
          body: l10n.onbCrashBody,
          yes: l10n.onbCrashYes,
          no: l10n.onbCrashNo,
          value: _crash,
          enabled: _age,
          onChanged: (v) => setState(() => _crash = v),
        ),
        const SizedBox(height: SkSpace.space8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SkButton.tertiary(
            label: l10n.onbWhatWeCollect,
            icon: Icons.info_outline,
            onPressed: _whatWeCollect,
          ),
        ),
        Text(l10n.onbPrivacyNote, style: text.bodySmall),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SkSpace.space4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, color: context.sk.colors.primary)),
        const SizedBox(width: SkSpace.space12),
        Expanded(child: Text(text, style: context.sk.text.bodyLarge)),
      ],
    ),
  );
}

/// Ano/nie s rovnocennymi tlacidlami; null = nevybrate (= nie).
class _Choice extends StatelessWidget {
  const _Choice({
    required this.id,
    required this.title,
    required this.body,
    required this.yes,
    required this.no,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String id;
  final String title;
  final String body;
  final String yes;
  final String no;
  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = context.sk.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: text.titleMedium)),
        const SizedBox(height: SkSpace.space4),
        Text(body, style: text.bodyMedium),
        const SizedBox(height: SkSpace.space8),
        SegmentedButton<bool>(
          key: ValueKey('privacy:$id'),
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: true,
              label: Text(yes, key: ValueKey('privacy:$id:yes')),
            ),
            ButtonSegment(
              value: false,
              label: Text(no, key: ValueKey('privacy:$id:no')),
            ),
          ],
          selected: {?value},
          onSelectionChanged: enabled
              ? (s) => onChanged(s.isEmpty ? null : s.first)
              : null,
        ),
      ],
    );
  }
}
