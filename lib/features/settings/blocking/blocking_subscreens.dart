import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/blocker/blocked_apps_repository.dart';
import 'package:sakina/data/blocker/blocker_gateway.dart';
import 'package:sakina/features/settings/blocking/blocking_providers.dart';
import 'package:sakina/features/settings/blocking/blocking_widgets.dart';
import 'package:sakina/features/settings/settings_widgets.dart';
import 'package:sakina/ui/ui.dart';

/// `/settings/blocking/permissions`: rovnaky obsah ako O6. Ked su
/// povolenia hotove a brana este nebezi, ponukne "Turn on the gate".
class BlockingPermissionsScreen extends ConsumerStatefulWidget {
  const BlockingPermissionsScreen({super.key});

  @override
  ConsumerState<BlockingPermissionsScreen> createState() =>
      _BlockingPermissionsScreenState();
}

class _BlockingPermissionsScreenState
    extends ConsumerState<BlockingPermissionsScreen> {
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
    if (result == GateEnableResult.enabled && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overview = ref.watch(blockerOverviewProvider).value;
    final ready = overview?.permissions.readyForGate ?? false;
    final running = overview?.health == GateHealth.running;
    return Scaffold(
      appBar: skAppBar(context, title: l10n.blkPermTitle),
      body: SettingsList(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.all(SkSpace.space16),
            child: GatePermissionsPanel(),
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
              ),
              child: SkInlineBanner(
                variant: SkBannerVariant.error,
                message: l10n.blkTurnOnFailed,
              ),
            ),
          if (!running)
            Padding(
              padding: const EdgeInsetsDirectional.all(SkSpace.space16),
              child: SkButton.primary(
                key: const ValueKey('blocking:turn_on'),
                label: l10n.blkTurnOn,
                expand: true,
                loading: _busy,
                onPressed: ready && !_busy ? _turnOn : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// `/settings/blocking/add`: picker ako O5, uz blokovane appky skryte.
class BlockingAddScreen extends ConsumerStatefulWidget {
  const BlockingAddScreen({super.key});

  @override
  ConsumerState<BlockingAddScreen> createState() => _BlockingAddScreenState();
}

class _BlockingAddScreenState extends ConsumerState<BlockingAddScreen> {
  Set<String> _selected = {};
  bool _busy = false;

  Future<void> _add(List<LaunchableApp> all) async {
    setState(() => _busy = true);
    await ref.read(blockedAppsRepositoryProvider).add([
      for (final a in all)
        if (_selected.contains(a.ref)) a,
    ]);
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existing = {
      for (final a in ref.watch(blockedAppsProvider).value ?? <BlockedApp>[])
        a.ref,
    };
    final all = ref.watch(installedAppsProvider).value;
    return Scaffold(
      appBar: skAppBar(context, title: l10n.blkAddApps),
      body: Column(
        children: [
          Expanded(
            child: SettingsList(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.all(SkSpace.space16),
                  child: GateAppPicker(
                    selected: _selected,
                    excluded: existing,
                    onChanged: (s) => setState(() => _selected = s),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(SkSpace.space16),
              child: SkButton.primary(
                key: const ValueKey('blocking:add_confirm'),
                label: l10n.blkAddCta(_selected.length),
                expand: true,
                loading: _busy,
                onPressed: _selected.isEmpty || all == null || _busy
                    ? null
                    : () => _add(all),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A10.2 Brana - detail appky (`/settings/blocking/app/:ref`). Kazda
/// zmena sa hned ulozi a cely zoznam sa posle do nativu.
class BlockingAppScreen extends ConsumerWidget {
  const BlockingAppScreen({required this.appRef, super.key});

  final String appRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final apps = ref.watch(blockedAppsProvider);
    final app = apps.value?.where((a) => a.ref == appRef).firstOrNull;
    final repo = ref.read(blockedAppsRepositoryProvider);
    void update(BlockedAppPatch patch) =>
        unawaited(repo.update(app!.id, patch));

    Future<void> remove() async {
      final ok = await showSkConfirmDialog(
        context,
        title: l10n.blkAppRemoveTitle(app!.displayName),
        confirmLabel: l10n.blkAppRemoveConfirm,
        variant: SkConfirmVariant.destructive,
      );
      if (!ok) return;
      await repo.remove(app.id);
      if (context.mounted && context.canPop()) context.pop();
    }

    return Scaffold(
      appBar: skAppBar(context, title: app?.displayName ?? l10n.blkTitle),
      body: switch (apps) {
        AsyncValue(value: null, hasError: false) => const SkLoadingView(),
        _ when app == null => SkEmptyState(title: l10n.blkAppNotFound),
        _ => SettingsList(
          children: [
            ListTile(
              leading: GateAppIcon(app.ref, size: 48),
              title: Text(app.displayName, style: context.sk.text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
              ),
              child: Column(
                children: [
                  CountStepper(
                    key: const ValueKey('app:cards'),
                    label: l10n.blkCardsLabel,
                    value: app.cardsRequired,
                    min: BlockedAppLimits.minCards,
                    max: BlockedAppLimits.maxCards,
                    format: (v) => formatCount(context, v),
                    onChanged: (v) => update(BlockedAppPatch(cardsRequired: v)),
                  ),
                  CountStepper(
                    key: const ValueKey('app:minutes'),
                    label: l10n.blkMinutesLabel,
                    value: app.unlockMinutes,
                    min: BlockedAppLimits.minMinutes,
                    max: BlockedAppLimits.maxMinutes,
                    step: BlockedAppLimits.minutesStep,
                    format: (v) => formatMinutes(context, v),
                    onChanged: (v) => update(BlockedAppPatch(unlockMinutes: v)),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              key: const ValueKey('app:prayer'),
              title: Text(l10n.blkAppPrayerLock),
              subtitle: Text(l10n.blkAppPrayerLockHelp),
              value: app.prayerLock,
              onChanged: (v) => update(BlockedAppPatch(prayerLock: v)),
            ),
            const SizedBox(height: SkSpace.space16),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
              ),
              child: SkButton.destructive(
                key: const ValueKey('app:remove'),
                label: l10n.blkAppRemove,
                expand: true,
                onPressed: remove,
              ),
            ),
          ],
        ),
      },
    );
  }
}
