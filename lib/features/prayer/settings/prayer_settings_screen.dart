import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/country_defaults.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/prayer/prayer_paths.dart';
import 'package:prosoche/features/prayer/prayer_texts.dart';
import 'package:prosoche/ui/ui.dart';

/// Nastavenia modlitieb (docs/02 A10.3). Route `/settings/prayer`.
///
/// Kazda zmena ide cez [PrayerRepository], ktory vola
/// `prayerSettingsChangedProvider` (preplanovanie notifikacii, P-02), a
/// nahlad dnesnych casov sa hned prepocita.
class PrayerSettingsScreen extends ConsumerWidget {
  const PrayerSettingsScreen({super.key});

  /// Rucny posun (A10.3).
  static const minAdjust = -30;
  static const maxAdjust = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(prayerConfigProvider);
    final Widget body;
    if (config.hasError) {
      body = SkErrorState(
        title: l10n.prayerErrorTitle,
        body: l10n.prayerErrorBody,
        onRetry: () => ref.invalidate(prayerConfigProvider),
      );
    } else if (!config.hasValue) {
      body = const Center(
        child: SkLoadingView(skeleton: SkSkeleton.list(lines: 6)),
      );
    } else if (config.requireValue == null) {
      body = ListView(
        children: [
          const _LocationTile(config: null),
          SkEmptyState(
            title: l10n.prayerLocationTitle,
            body: l10n.prayerLocationBody,
            actionLabel: l10n.prayerChooseCity,
            onAction: () => unawaited(context.push(PrayerPaths.citySearch)),
          ),
        ],
      );
    } else {
      body = _SettingsList(config: config.requireValue!);
    }
    return Scaffold(
      appBar: skAppBar(context, title: l10n.prayerSettingsTitle),
      body: body,
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.config});

  final PrayerConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repo = ref.read(prayerRepositoryProvider);
    final s = config.settings;
    final manual =
        ref.watch(settingOf(SettingsKeys.prayerMethod)).value != null;
    final countryDefault = CountryDefaults.forCountry(config.location.country)
        .method;
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space24),
      children: [
        _LocationTile(config: config),
        _Section(l10n.prayerSettingsMethod),
        ListTile(
          title: Text(context.methodName(s.method)),
          subtitle: Text(
            manual
                ? context.methodAngles(s.method)
                : '${l10n.prayerMethodAutomatic} · '
                      '${context.methodAngles(s.method)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await _pickMethod(
              context,
              current: manual ? s.method : null,
              countryDefault: countryDefault,
            );
            if (picked != null) await repo.setMethod(picked.method);
          },
        ),
        _Section(l10n.prayerSettingsAsr),
        for (final (asr, label) in [
          (AsrMadhab.shafi, l10n.prayerAsrShafi),
          (AsrMadhab.hanafi, l10n.prayerAsrHanafi),
        ])
          ListTile(
            title: Text(label),
            selected: s.asr == asr,
            trailing: s.asr == asr ? const Icon(Icons.check) : null,
            onTap: () => unawaited(repo.setAsr(asr)),
          ),
        _Section(
          l10n.prayerSettingsHighLat,
          help: l10n.prayerSettingsHighLatHelp,
        ),
        for (final rule in HighLatRule.values)
          ListTile(
            title: Text(context.highLatName(rule)),
            subtitle: Text(l10n.prayerHighLatDescription(rule.key)),
            selected: s.highLatRule == rule,
            trailing: s.highLatRule == rule ? const Icon(Icons.check) : null,
            onTap: () => unawaited(repo.setHighLatRule(rule)),
          ),
        _Section(
          l10n.prayerSettingsAdjust,
          help: l10n.prayerSettingsAdjustHelp,
        ),
        for (final p in Prayer.salah)
          _AdjustStepper(
            prayer: p,
            minutes: s.adjust[p] ?? 0,
            onChanged: (m) => unawaited(repo.setAdjust(p, m)),
          ),
        _Section(l10n.prayerSettingsPreview),
        _Preview(config: config),
      ],
    );
  }

  Future<({PrayerMethod? method})?> _pickMethod(
    BuildContext context, {
    required PrayerMethod? current,
    required PrayerMethod countryDefault,
  }) => showModalBottomSheet<({PrayerMethod? method})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final l10n = context.l10n;
      Widget tile(PrayerMethod? m) {
        final selected = m == current;
        return ListTile(
          title: Text(
            m == null ? l10n.prayerMethodAutomatic : context.methodName(m),
          ),
          subtitle: Text(
            m == null
                ? l10n.prayerMethodAutomaticFor(
                    context.methodName(countryDefault),
                  )
                : context.methodAngles(m),
          ),
          selected: selected,
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop((method: m)),
        );
      }

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(SkSpace.space16),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.prayerSettingsMethod,
                  style: context.sk.text.titleLarge,
                ),
              ),
            ),
            tile(null),
            for (final m in PrayerMethod.values) tile(m),
          ],
        ),
      );
    },
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, {this.help});

  final String title;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space24,
        SkSpace.space16,
        SkSpace.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: sk.text.titleSmall!.copyWith(color: sk.colors.primary),
            ),
          ),
          if (help != null)
            Text(
              help!,
              style: sk.text.bodyMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.config});

  final PrayerConfig? config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = config?.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(l10n.prayerSettingsLocation),
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(
            location == null
                ? l10n.prayerLocationTitle
                : location.city ?? location.tz,
          ),
          subtitle: location == null ? null : Text(location.tz),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(context.push(PrayerPaths.citySearch)),
        ),
      ],
    );
  }
}

/// Stepper -/+ (docs/01 3.2 `SkStepper`, pristupnejsi nez slider).
class _AdjustStepper extends StatelessWidget {
  const _AdjustStepper({
    required this.prayer,
    required this.minutes,
    required this.onChanged,
  });

  final Prayer prayer;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final value = context.signedNumber(minutes);
    final name = context.prayerName(prayer);
    return Semantics(
      container: true,
      label: l10n.prayerAdjustSemantics(name, value),
      value: l10n.prayerAdjustMinutes(value),
      increasedValue: minutes < PrayerSettingsScreen.maxAdjust
          ? l10n.prayerAdjustMinutes(context.signedNumber(minutes + 1))
          : null,
      decreasedValue: minutes > PrayerSettingsScreen.minAdjust
          ? l10n.prayerAdjustMinutes(context.signedNumber(minutes - 1))
          : null,
      onIncrease: minutes < PrayerSettingsScreen.maxAdjust
          ? () => onChanged(minutes + 1)
          : null,
      onDecrease: minutes > PrayerSettingsScreen.minAdjust
          ? () => onChanged(minutes - 1)
          : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space16,
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Text(name, style: sk.text.bodyLarge),
              ),
            ),
            SkIconButton(
              icon: Icons.remove,
              tooltip: l10n.prayerAdjustEarlier,
              onPressed: minutes > PrayerSettingsScreen.minAdjust
                  ? () => onChanged(minutes - 1)
                  : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: ExcludeSemantics(
                child: Text(
                  l10n.prayerAdjustMinutes(value),
                  textAlign: TextAlign.center,
                  style: ProsocheTypography.tabular(sk.text.bodyLarge!),
                ),
              ),
            ),
            SkIconButton(
              icon: Icons.add,
              tooltip: l10n.prayerAdjustLater,
              onPressed: minutes < PrayerSettingsScreen.maxAdjust
                  ? () => onChanged(minutes + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nahlad dnesnych casov (prepocita sa po kazdej zmene).
class _Preview extends ConsumerWidget {
  const _Preview({required this.config});

  final PrayerConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = LocalDate.fromDateTime(ref.watch(appClockProvider).now());
    final day = config.schedule.day(today);
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space16,
      ),
      child: Wrap(
        spacing: SkSpace.space16,
        runSpacing: SkSpace.space8,
        children: [
          for (final p in Prayer.values)
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.prayerName(p),
                    style: sk.text.labelMedium!.copyWith(
                      color: sk.colors.textSecondary,
                    ),
                  ),
                  Text(
                    context.formats.time(day[p]),
                    style: ProsocheTypography.tabular(sk.text.bodyLarge!),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
