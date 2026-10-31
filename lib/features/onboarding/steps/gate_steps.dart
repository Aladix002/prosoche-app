import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_controller.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';
import 'package:prosoche/features/settings/blocking/blocking_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// O5 Brana - vyber appiek (docs/02 A1 O5), len pri `FEATURE_GATE`.
///
/// Zoznam z `installedApps()` s ikonami, caste socialne siete navrchu a
/// predvybrate (ak su nainstalovane). Pocet kariet a dlzka odomknutia
/// plati pre vsetky vybrate appky (per-app az v A10.2). Bez vyberu sa O6
/// preskoci a brana ostane vypnuta.
class GateAppsStep extends ConsumerStatefulWidget {
  const GateAppsStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  ConsumerState<GateAppsStep> createState() => _GateAppsStepState();
}

class _GateAppsStepState extends ConsumerState<GateAppsStep> {
  Set<String> _selected = {};
  int _cards = BlockedAppLimits.defaultCards;
  int _minutes = BlockedAppLimits.defaultMinutes;
  bool _loaded = false;
  bool _preselect = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExisting());
  }

  /// Navrat cez "Back": vyber z `blocked_app` namiesto predvyberu.
  Future<void> _loadExisting() async {
    final existing = await ref.read(blockedAppsRepositoryProvider).apps();
    if (!mounted) return;
    setState(() {
      if (existing.isNotEmpty) {
        _preselect = false;
        _selected = {for (final a in existing) a.ref};
        _cards = existing.first.cardsRequired;
        _minutes = existing.first.unlockMinutes;
      }
      _loaded = true;
    });
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final all = ref.read(installedAppsProvider).value ?? const [];
      final selected = [
        for (final a in all)
          if (_selected.contains(a.ref)) a,
      ];
      await ref
          .read(blockedAppsRepositoryProvider)
          .replaceSelection(
            selected,
            cardsRequired: _cards,
            unlockMinutes: _minutes,
          );
      // Len pocet, nikdy nazvy appiek (docs/02 O5).
      ref.read(onboardingControllerProvider).track('gate_apps_selected', {
        'count': selected.length,
      });
      await widget.onNext(skipped: selected.isEmpty);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final apps = ref.watch(installedAppsProvider);
    return OnboardingStepBody(
      icon: Icons.apps_outlined,
      title: l10n.blkAppsTitle,
      body: l10n.blkAppsBody,
      primaryLabel: l10n.blkAppsCta(_selected.length),
      busy: _busy,
      onPrimary: _loaded && apps.hasValue ? _continue : null,
      children: [
        CountStepper(
          key: const ValueKey('o5:cards'),
          label: l10n.blkCardsLabel,
          value: _cards,
          min: BlockedAppLimits.minCards,
          max: BlockedAppLimits.maxCards,
          format: (v) => formatCount(context, v),
          onChanged: (v) => setState(() => _cards = v),
        ),
        CountStepper(
          key: const ValueKey('o5:minutes'),
          label: l10n.blkMinutesLabel,
          value: _minutes,
          min: BlockedAppLimits.minMinutes,
          max: BlockedAppLimits.maxMinutes,
          step: BlockedAppLimits.minutesStep,
          format: (v) => formatMinutes(context, v),
          onChanged: (v) => setState(() => _minutes = v),
        ),
        const SizedBox(height: SkSpace.space8),
        if (_loaded)
          GateAppPicker(
            selected: _selected,
            preselectSuggested: _preselect,
            onChanged: (s) => setState(() => _selected = s),
          ),
      ],
    );
  }
}

/// O6 Povolenia brany (docs/02 A1 O6, docs/01 7.3): prominent disclosure,
/// usage access, overlay, notifikacie a navod k baterii podla vyrobcu.
/// "Turn on the gate" je aktivne, ked su usage access a overlay zapnute.
class GatePermissionsStep extends ConsumerStatefulWidget {
  const GatePermissionsStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  ConsumerState<GatePermissionsStep> createState() =>
      _GatePermissionsStepState();
}

class _GatePermissionsStepState extends ConsumerState<GatePermissionsStep> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _turnOn() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final result = await ref.read(blockingActionsProvider).enable();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = result != GateEnableResult.enabled;
    });
    if (result == GateEnableResult.enabled) await widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready =
        ref.watch(blockerOverviewProvider).value?.permissions.readyForGate ??
        false;
    final controller = ref.read(onboardingControllerProvider);
    return OnboardingStepBody(
      icon: Icons.shield_outlined,
      title: l10n.blkPermTitle,
      primaryLabel: l10n.blkTurnOn,
      busy: _busy,
      onPrimary: ready ? _turnOn : null,
      children: [
        GatePermissionsPanel(
          onResult: (permission, {required granted}) => controller.track(
            'permission_result',
            {'permission': permission, 'granted': granted},
          ),
        ),
        if (_failed)
          SkInlineBanner(
            variant: SkBannerVariant.error,
            message: l10n.blkTurnOnFailed,
          ),
      ],
    );
  }
}
