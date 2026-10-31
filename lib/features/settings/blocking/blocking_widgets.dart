import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Ikona appky z nativu (PNG), kym sa nacitava alebo chyba: genericka.
class GateAppIcon extends ConsumerWidget {
  const GateAppIcon(this.app, {this.size = 40, super.key});

  final String app;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final png = ref.watch(appIconProvider(app)).value;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: png == null
            ? Icon(Icons.apps, size: size * 0.8)
            : Image.memory(
                png,
                width: size,
                height: size,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}

/// `[-] hodnota [+]` s rozsahom a krokom (O5, A10.2, A10.1).
class CountStepper extends StatelessWidget {
  const CountStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
    this.step = 1,
    super.key,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String Function(int value) format;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = onChanged;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: SkSpace.space4),
      // Wrap: pri textScale 2.0 sa ovladanie presunie pod popis.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: context.sk.text.bodyLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkIconButton(
                icon: Icons.remove,
                tooltip: l10n.blkDecrease(label),
                onPressed: change == null || value - step < min
                    ? null
                    : () => change(value - step),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 64),
                  child: Semantics(
                    label: label,
                    value: format(value),
                    liveRegion: true,
                    excludeSemantics: true,
                    child: Text(
                      format(value),
                      textAlign: TextAlign.center,
                      style: context.sk.text.titleMedium,
                    ),
                  ),
                ),
              ),
              SkIconButton(
                icon: Icons.add,
                tooltip: l10n.blkIncrease(label),
                onPressed: change == null || value + step > max
                    ? null
                    : () => change(value + step),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minuty v jazyku UI ("10 min").
String formatMinutes(BuildContext context, int minutes) =>
    context.l10n.blkMinutes(
      ProsocheFormats(Localizations.localeOf(context)).number(minutes),
    );

/// Zoznam appiek na vyber (O5 a "Add apps"): navrchu caste socialne siete,
/// potom abecedne, lokalne vyhladavanie podla nazvu. [excluded] (uz
/// blokovane) sa nezobrazia.
class GateAppPicker extends ConsumerStatefulWidget {
  const GateAppPicker({
    required this.selected,
    required this.onChanged,
    this.excluded = const {},
    this.preselectSuggested = false,
    super.key,
  });

  /// Vybrane package names.
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final Set<String> excluded;

  /// Pri prvom nacitani predvyberie nainstalovane [kSuggestedPackages].
  final bool preselectSuggested;

  @override
  ConsumerState<GateAppPicker> createState() => _GateAppPickerState();
}

class _GateAppPickerState extends ConsumerState<GateAppPicker> {
  String _query = '';
  bool _preselected = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final apps = ref.watch(installedAppsProvider);
    return apps.when(
      skipLoadingOnReload: true,
      loading: () => const SkSkeleton.list(lines: 6),
      error: (_, _) => SkInlineBanner(
        variant: SkBannerVariant.error,
        message: l10n.blkAppsError,
        actionLabel: SkUiStrings.of(context).tryAgain,
        onAction: () => ref.invalidate(installedAppsProvider),
      ),
      data: (all) {
        final available = [
          for (final a in all)
            if (!widget.excluded.contains(a.ref)) a,
        ];
        _maybePreselect(available);
        final q = _query.trim().toLowerCase();
        final visible = [
          for (final a in available)
            if (q.isEmpty || a.label.toLowerCase().contains(q)) a,
        ];
        final suggested = [
          for (final ref in kSuggestedPackages)
            ...visible.where((a) => a.ref == ref),
        ];
        final rest = [
          for (final a in visible)
            if (!kSuggestedPackages.contains(a.ref)) a,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.blkAppsSearch,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: SkSpace.space8),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(SkSpace.space16),
                child: Text(l10n.blkAppsEmpty, textAlign: TextAlign.center),
              ),
            if (suggested.isNotEmpty) ...[
              _Header(l10n.blkAppsSuggested),
              for (final a in suggested) _tile(a),
            ],
            if (rest.isNotEmpty) ...[
              if (suggested.isNotEmpty) _Header(l10n.blkAppsAll),
              for (final a in rest) _tile(a),
            ],
          ],
        );
      },
    );
  }

  void _maybePreselect(List<LaunchableApp> available) {
    if (_preselected || !widget.preselectSuggested) return;
    _preselected = true;
    final installed = {
      for (final a in available)
        if (kSuggestedPackages.contains(a.ref)) a.ref,
    };
    if (installed.isEmpty) return;
    // Po builde: rodic si vyber ulozi cez setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged({...widget.selected, ...installed});
    });
  }

  Widget _tile(LaunchableApp app) {
    final checked = widget.selected.contains(app.ref);
    return CheckboxListTile(
      key: ValueKey('app:${app.ref}'),
      contentPadding: EdgeInsetsDirectional.zero,
      secondary: GateAppIcon(app.ref),
      title: Text(app.label),
      value: checked,
      onChanged: (v) {
        final next = {...widget.selected};
        if (v ?? false) {
          next.add(app.ref);
        } else {
          next.remove(app.ref);
        }
        widget.onChanged(next);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: SkSpace.space16,
      bottom: SkSpace.space4,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.sk.text.titleSmall!.copyWith(
          color: context.sk.colors.accentText,
        ),
      ),
    ),
  );
}

/// Povolenia brany s prominent disclosure (O6 a
/// `/settings/blocking/permissions`, docs/01 7.3). Vysvetlenie je na
/// obrazovke pred tlacidlom "Allow in settings". Po navrate zo systemovych
/// nastaveni sa stav nacita znova; [onResult] dostane vysledok kazdeho
/// povolenia, ktore pouzivatel isiel zapnut (analytika bez nazvov appiek).
class GatePermissionsPanel extends ConsumerStatefulWidget {
  const GatePermissionsPanel({this.onResult, super.key});

  final void Function(String permission, {required bool granted})? onResult;

  @override
  ConsumerState<GatePermissionsPanel> createState() =>
      _GatePermissionsPanelState();
}

class _GatePermissionsPanelState extends ConsumerState<GatePermissionsPanel> {
  late final AppLifecycleListener _lifecycle;

  /// Povolenia, ktore pouzivatel isiel zapnut (zobrazi "Not allowed yet").
  final _asked = <BlockerSettings>{};
  bool _batteryDone = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    ref.invalidate(blockerOverviewProvider);
    final overview = await ref.read(blockerOverviewProvider.future);
    final p = overview.permissions;
    for (final kind in _asked) {
      final granted = switch (kind) {
        BlockerSettings.usageAccess => p.usageAccess,
        BlockerSettings.overlay => p.overlay,
        BlockerSettings.notifications => p.notifications,
        _ => null,
      };
      if (granted != null) {
        widget.onResult?.call(switch (kind) {
          BlockerSettings.usageAccess => 'usage_access',
          BlockerSettings.overlay => 'overlay',
          _ => 'notifications',
        }, granted: granted);
      }
    }
  }

  Future<void> _open(BlockerSettings kind) async {
    setState(() => _asked.add(kind));
    await ref.read(blockerGatewayProvider).openSystemSettings(kind);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overview = ref.watch(blockerOverviewProvider);
    final p = overview.value?.permissions;
    final vendor = batteryVendorOf(
      ref.watch(deviceManufacturerProvider).value ?? '',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.blkPermIntro, style: context.sk.text.bodyLarge),
        const SizedBox(height: SkSpace.space16),
        _PermissionRow(
          key: const ValueKey('perm:usage'),
          number: 1,
          title: l10n.permUsageTitle,
          granted: p?.usageAccess,
          asked: _asked.contains(BlockerSettings.usageAccess),
          disclosure: [
            l10n.permUsageBody,
            l10n.permUsageDoes,
            l10n.permUsageNever,
            l10n.permLocal,
            l10n.permUsageSteps,
          ],
          onAllow: () => _open(BlockerSettings.usageAccess),
        ),
        _PermissionRow(
          key: const ValueKey('perm:overlay'),
          number: 2,
          title: l10n.permOverlayTitle,
          granted: p?.overlay,
          asked: _asked.contains(BlockerSettings.overlay),
          disclosure: [l10n.permOverlayBody, l10n.permOverlayNever],
          onAllow: () => _open(BlockerSettings.overlay),
        ),
        _PermissionRow(
          key: const ValueKey('perm:notifications'),
          number: 3,
          title: l10n.permNotifTitle,
          granted: p?.notifications,
          asked: _asked.contains(BlockerSettings.notifications),
          disclosure: [l10n.permNotifBody],
          onAllow: () => _open(BlockerSettings.notifications),
        ),
        if (vendor != null)
          _BatteryRow(
            vendor: vendor,
            manufacturer: ref.watch(deviceManufacturerProvider).value ?? '',
            done: _batteryDone,
            onDone: (v) => setState(() => _batteryDone = v),
          )
        else ...[
          const SizedBox(height: SkSpace.space8),
          Text(
            l10n.batteryBodyGeneric,
            style: context.sk.text.bodySmall!.copyWith(
              color: context.sk.colors.textSecondary,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkButton.tertiary(
              label: l10n.batteryOpen,
              onPressed: () => ref
                  .read(blockerGatewayProvider)
                  .openSystemSettings(BlockerSettings.batteryOptimization),
            ),
          ),
        ],
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.number,
    required this.title,
    required this.granted,
    required this.asked,
    required this.disclosure,
    required this.onAllow,
    super.key,
  });

  final int number;
  final String title;

  /// null = nacitava sa.
  final bool? granted;
  final bool asked;
  final List<String> disclosure;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final ok = granted ?? false;
    final formats = ProsocheFormats(Localizations.localeOf(context));
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: l10n.permStateLabel(title, ok.toString()),
            excludeSemantics: true,
            child: Row(
              children: [
                Text('${formats.number(number)}  ', style: sk.text.titleMedium),
                Expanded(child: Text(title, style: sk.text.titleMedium)),
                if (granted == null)
                  const SkSkeletonBox(width: 24, height: 24)
                else
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: ok ? sk.colors.success : sk.colors.textSecondary,
                  ),
              ],
            ),
          ),
          if (!ok) ...[
            const SizedBox(height: SkSpace.space4),
            for (final line in disclosure)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: SkSpace.space4,
                ),
                child: Text(line, style: sk.text.bodyMedium),
              ),
            if (asked && granted != null)
              Text(
                l10n.permNotYet,
                style: sk.text.bodySmall!.copyWith(color: sk.colors.warning),
              ),
            const SizedBox(height: SkSpace.space4),
            SkButton.secondary(
              label: l10n.permAllow,
              expand: true,
              onPressed: granted == null ? null : onAllow,
            ),
          ] else
            Text(l10n.permGranted, style: sk.text.bodySmall),
        ],
      ),
    );
  }
}

class _BatteryRow extends ConsumerWidget {
  const _BatteryRow({
    required this.vendor,
    required this.manufacturer,
    required this.done,
    required this.onDone,
  });

  final BatteryVendor vendor;
  final String manufacturer;
  final bool done;
  final ValueChanged<bool> onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final name = _brand(manufacturer);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${ProsocheFormats(Localizations.localeOf(context)).number(4)}'
                '  ',
                style: sk.text.titleMedium,
              ),
              Expanded(
                child: Text(
                  l10n.batteryVendorTitle(name),
                  style: sk.text.titleMedium,
                ),
              ),
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? sk.colors.success : sk.colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: SkSpace.space4),
          SkButton.secondary(
            key: const ValueKey('perm:battery'),
            label: l10n.batteryGuide,
            expand: true,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => BatteryGuideSheet(
                vendor: vendor,
                manufacturer: name,
                done: done,
                onDone: onDone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _brand(String m) =>
    m.isEmpty ? m : '${m[0].toUpperCase()}${m.substring(1)}';

/// Navod k baterii podla vyrobcu (docs/01 5.1). Len odkaz na zoznam
/// optimalizacie baterie, nikdy priama ziadost
/// (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` sa nepouziva, TECHNICKY_PLAN 9.3).
/// Splnenie sa neda overit, preto "I've done this".
class BatteryGuideSheet extends ConsumerStatefulWidget {
  const BatteryGuideSheet({
    required this.vendor,
    required this.manufacturer,
    required this.done,
    required this.onDone,
    super.key,
  });

  final BatteryVendor vendor;
  final String manufacturer;
  final bool done;
  final ValueChanged<bool> onDone;

  @override
  ConsumerState<BatteryGuideSheet> createState() => _BatteryGuideSheetState();
}

class _BatteryGuideSheetState extends ConsumerState<BatteryGuideSheet> {
  late bool _done = widget.done;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = switch (widget.vendor) {
      BatteryVendor.samsung => l10n.batteryStepsSamsung,
      BatteryVendor.xiaomi => l10n.batteryStepsXiaomi,
      BatteryVendor.huawei => l10n.batteryStepsHuawei,
      BatteryVendor.oppo => l10n.batteryStepsOppo,
    };
    return SkSheet(
      title: l10n.batteryTitle,
      closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.batteryBodyVendor(widget.manufacturer)),
          const SizedBox(height: SkSpace.space8),
          Text(steps),
          const SizedBox(height: SkSpace.space8),
          Text(
            l10n.batteryNote,
            style: context.sk.text.bodySmall!.copyWith(
              color: context.sk.colors.textSecondary,
            ),
          ),
          const SizedBox(height: SkSpace.space16),
          SkButton.secondary(
            label: l10n.batteryOpen,
            expand: true,
            onPressed: () => ref
                .read(blockerGatewayProvider)
                .openSystemSettings(BlockerSettings.batteryOptimization),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.batteryDone),
            value: _done,
            onChanged: (v) {
              setState(() => _done = v ?? false);
              widget.onDone(_done);
            },
          ),
        ],
      ),
    );
  }
}

/// Riadok blokovanej appky (A10.1).
class BlockedAppTile extends StatelessWidget {
  const BlockedAppTile({
    required this.app,
    required this.onTap,
    this.unlocks,
    super.key,
  });

  final BlockedApp app;
  final VoidCallback onTap;

  /// Odomknutia za 7 dni (null = nezobrazit).
  final int? unlocks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = l10n.blkAppSummary(
      app.cardsRequired,
      ProsocheFormats(Localizations.localeOf(context))
          .number(app.unlockMinutes),
    );
    final n = unlocks;
    return ListTile(
      key: ValueKey('blocked:${app.ref}'),
      leading: GateAppIcon(app.ref),
      title: Text(app.displayName),
      subtitle: Text(
        n == null || n == 0 ? summary : '$summary\n${l10n.blkStatsPerApp(n)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Cislo v jazyku UI (arabske/bengalske cislice).
String formatCount(BuildContext context, int value) =>
    ProsocheFormats(Localizations.localeOf(context)).number(value);
