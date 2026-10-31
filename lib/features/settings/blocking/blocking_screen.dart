import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';
import 'package:prosoche/features/settings/blocking/blocking_widgets.dart';
import 'package:prosoche/features/settings/settings_paths.dart';
import 'package:prosoche/features/settings/settings_widgets.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Cesty podobrazoviek brany (docs/02 A10.1, A10.2).
abstract final class BlockingPaths {
  static const String root = SettingsPaths.blocking;
  static const permissions = '$root/permissions';
  static const add = '$root/add';

  static String app(String ref) => '$root/app/${Uri.encodeComponent(ref)}';
}

/// A10.1 Brana - prehlad (`/settings/blocking`, len `FEATURE_GATE`).
///
/// Hlavny prepinac, stav sluzby s "Fix", povolenia, blokovane appky,
/// pripomienka modlitby a lokalna statistika za 7 dni. Po navrate do
/// appky (resumed) sa stav nativu nacita znova (odobraty usage access).
class BlockingScreen extends ConsumerStatefulWidget {
  const BlockingScreen({super.key});

  @override
  ConsumerState<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends ConsumerState<BlockingScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref
        ..invalidate(blockerOverviewProvider)
        ..invalidate(gateStatsProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _setEnabled(bool on) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final actions = ref.read(blockingActionsProvider);
    try {
      if (!on) {
        await actions.disable();
        return;
      }
      switch (await actions.enable()) {
        case GateEnableResult.enabled:
          break;
        case GateEnableResult.needsPermissions:
          if (mounted) unawaited(context.push(BlockingPaths.permissions));
        case GateEnableResult.failed:
          if (mounted) setState(() => _error = context.l10n.blkTurnOnFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fix(GateHealth health) {
    if (health == GateHealth.stopped) {
      unawaited(_setEnabled(true));
    } else {
      unawaited(context.push(BlockingPaths.permissions));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overview = ref.watch(blockerOverviewProvider);
    return Scaffold(
      appBar: skAppBar(context, title: l10n.blkTitle),
      body: overview.when(
        skipLoadingOnReload: true,
        loading: () => const SkLoadingView(),
        error: (_, _) => SkErrorState(
          title: l10n.blkLoadError,
          onRetry: () => ref.invalidate(blockerOverviewProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(BlockerOverview overview) {
    final l10n = context.l10n;
    final health = overview.health;
    final apps = ref.watch(blockedAppsProvider);
    final stats = ref.watch(gateStatsProvider).value;
    final prayerMinutes = ref
        .watch(settingOf(SettingsKeys.blockerPrayerLockMinutes))
        .value;
    final statusText = switch (health) {
      GateHealth.off => l10n.blkStatusOff,
      GateHealth.running => l10n.blkStatusRunning,
      GateHealth.noUsageAccess => l10n.blkStatusNoUsage,
      GateHealth.noOverlay => l10n.blkStatusNoOverlay,
      GateHealth.stopped => l10n.blkStatusStopped,
    };
    final paused = health != GateHealth.off && health != GateHealth.running;
    final formats = ProsocheFormats(Localizations.localeOf(context));

    return SettingsList(
      children: [
        SwitchListTile(
          key: const ValueKey('blocking:switch'),
          title: Text(l10n.blkSwitch),
          subtitle: Text(statusText),
          value: overview.state.enabled,
          onChanged: _busy ? null : _setEnabled,
        ),
        if (paused)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SkSpace.space16,
            ),
            child: SkInlineBanner(
              key: const ValueKey('blocking:paused'),
              variant: SkBannerVariant.warning,
              message: statusText,
              actionLabel: l10n.blkFix,
              onAction: () => _fix(health),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsetsDirectional.all(SkSpace.space16),
            child: SkInlineBanner(
              variant: SkBannerVariant.error,
              message: _error!,
            ),
          ),
        SettingsNavTile(
          icon: Icons.verified_user_outlined,
          title: l10n.blkPermissions,
          value: overview.permissions.readyForGate
              ? l10n.blkPermissionsOk
              : l10n.blkPermissionsMissing,
          warning: !overview.permissions.readyForGate,
          onTap: () => unawaited(context.push(BlockingPaths.permissions)),
        ),
        SettingsSection(l10n.blkApps),
        ...apps.when(
          loading: () => [const SkSkeleton.list()],
          error: (_, _) => [SettingsNote(l10n.blkLoadError)],
          data: (list) => [
            if (list.isEmpty) SettingsNote(l10n.blkAppsNone),
            for (final app in list)
              BlockedAppTile(
                app: app,
                unlocks: stats?.unlocksPerApp[app.id],
                onTap: () =>
                    unawaited(context.push(BlockingPaths.app(app.ref))),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
          ),
          child: SkButton.outlined(
            key: const ValueKey('blocking:add'),
            label: l10n.blkAddApps,
            icon: Icons.add,
            expand: true,
            onPressed: () => unawaited(context.push(BlockingPaths.add)),
          ),
        ),
        SettingsSection(l10n.blkPrayerSection, help: l10n.blkPrayerHelp),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
          ),
          child: CountStepper(
            key: const ValueKey('blocking:prayer'),
            label: l10n.blkPrayerMinutes,
            value: (prayerMinutes ?? 15).clamp(
              BlockedAppLimits.minPrayerLock,
              BlockedAppLimits.maxPrayerLock,
            ),
            min: BlockedAppLimits.minPrayerLock,
            max: BlockedAppLimits.maxPrayerLock,
            step: 5,
            format: (v) => formatMinutes(context, v),
            onChanged: prayerMinutes == null
                ? null
                : (v) => unawaited(
                    ref
                        .read(settingsRepositoryProvider)
                        .set(SettingsKeys.blockerPrayerLockMinutes, v),
                  ),
          ),
        ),
        SettingsSection(l10n.blkStatsSection, help: l10n.blkStatsHelp),
        if (stats == null)
          const Padding(
            padding: EdgeInsetsDirectional.all(SkSpace.space16),
            child: SkSkeletonBox(height: 48),
          )
        else if (stats.isEmpty)
          SettingsNote(l10n.blkStatsEmpty)
        else ...[
          _StatRow(l10n.blkStatsGates, formats.number(stats.gates)),
          _StatRow(
            l10n.blkStatsCards,
            formats.number(stats.unlocksOf(UnlockSource.cards)),
          ),
          _StatRow(
            l10n.blkStatsEmergency,
            formats.number(stats.unlocksOf(UnlockSource.emergency)),
          ),
          if (stats.unlocksOf(UnlockSource.error) > 0)
            _StatRow(
              l10n.blkStatsError,
              formats.number(stats.unlocksOf(UnlockSource.error)),
            ),
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: context.sk.text.titleMedium),
    ),
  );
}
