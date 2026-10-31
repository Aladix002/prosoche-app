import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/prayer/city_repository.dart';
import 'package:prosoche/data/repositories/prayer/prayer_repository.dart';
import 'package:prosoche/data/repositories/providers.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_controller.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Nad touto sirkou sa zobrazi info o pravidle vysokych sirok (docs/02 O3).
const highLatitudeThreshold = 48.0;

enum _GpsState { idle, locating, denied, failed, noCity }

/// O3 Poloha a metoda (docs/02 A1). Poloha z GPS raz s nizkou presnostou
/// (najblizsie mesto z offline zoznamu, bez reverse geocodingu) alebo
/// rucny vyber mesta. Volba sa hned ulozi, nahlad casov sa prepocita.
class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  _GpsState _gps = _GpsState.idle;

  /// Nazov krajiny vybrateho mesta (pre text o predvolenej metode).
  String? _countryName;

  Future<void> _useGps() async {
    setState(() => _gps = _GpsState.locating);
    final controller = ref.read(onboardingControllerProvider);
    final result = await ref.read(deviceLocationProvider).locateOnce();
    controller.track('permission_result', {
      'permission': 'location',
      'granted': result is! LocationDenied,
    });
    if (!mounted) return;
    switch (result) {
      case LocationDenied():
        setState(() => _gps = _GpsState.denied);
      case LocationFailed():
        setState(() => _gps = _GpsState.failed);
        showSkSnackbar(context, message: context.l10n.onbLocationFailed);
      case LocationFound(:final lat, :final lng):
        final City? city;
        try {
          city = await ref.read(cityRepositoryProvider).nearest(lat, lng);
        } on Object {
          if (mounted) setState(() => _gps = _GpsState.failed);
          return;
        }
        if (!mounted) return;
        if (city == null) {
          setState(() => _gps = _GpsState.noCity);
          return;
        }
        // Suradnice z GPS (zaokruhli PrayerLocation), mesto a zona z
        // najblizsieho zaznamu.
        await _save(
          PrayerLocation(
            lat: lat,
            lng: lng,
            country: city.countryCode,
            tz: city.tz,
            city: city.name,
          ),
          countryName: city.countryName,
        );
    }
  }

  Future<void> _chooseCity() async {
    final city = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Sheet je na root navigatore; repozitar dostane priamo.
      builder: (_) => CitySearchSheet(cities: ref.read(cityRepositoryProvider)),
    );
    if (city == null || !mounted) return;
    await _save(city.toPrayerLocation(), countryName: city.countryName);
  }

  Future<void> _save(PrayerLocation location, {String? countryName}) async {
    // Nova poloha = predvolba metody a asr podla krajiny.
    final prayer = ref.read(prayerRepositoryProvider);
    await prayer.setMethod(null);
    await prayer.saveLocation(location, resetAsr: true);
    if (mounted) {
      setState(() {
        _gps = _GpsState.idle;
        _countryName = countryName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(prayerConfigProvider);
    final location = config.value?.location;
    final message = switch (_gps) {
      _GpsState.denied => l10n.onbLocationDenied,
      _GpsState.failed => l10n.onbLocationFailed,
      _GpsState.noCity => l10n.onbLocationNoCity,
      _ => null,
    };
    // Bez povolenia je hlavnou volbou rucny vyber mesta.
    final cityFirst = _gps == _GpsState.denied || _gps == _GpsState.noCity;
    final gpsButton = SkButton(
      variant: cityFirst ? SkButtonVariant.outlined : SkButtonVariant.secondary,
      label: l10n.onbLocationGps,
      icon: Icons.my_location,
      loading: _gps == _GpsState.locating,
      expand: true,
      onPressed: _gps == _GpsState.locating ? null : _useGps,
    );
    final cityButton = SkButton(
      variant: cityFirst ? SkButtonVariant.secondary : SkButtonVariant.outlined,
      label: l10n.onbLocationCity,
      icon: Icons.search,
      expand: true,
      onPressed: _gps == _GpsState.locating ? null : _chooseCity,
    );
    return OnboardingStepBody(
      icon: Icons.place_outlined,
      title: l10n.onbLocationTitle,
      body: l10n.onbLocationBody,
      primaryLabel: l10n.onbContinue,
      // Continue az po vybere polohy, inak len Skip (docs/02 O3 AC).
      onPrimary: location == null ? null : widget.onNext,
      children: [
        if (cityFirst) ...[cityButton, const SizedBox(height: SkSpace.space8)],
        gpsButton,
        if (!cityFirst) ...[const SizedBox(height: SkSpace.space8), cityButton],
        if (_gps == _GpsState.locating) ...[
          const SizedBox(height: SkSpace.space12),
          Semantics(liveRegion: true, child: Text(l10n.onbLocationFinding)),
        ],
        if (message != null) ...[
          const SizedBox(height: SkSpace.space12),
          SkInlineBanner(variant: SkBannerVariant.warning, message: message),
        ],
        if (config.value case final PrayerConfig c) ...[
          const SizedBox(height: SkSpace.space24),
          _MethodSection(config: c, countryName: _countryName),
        ],
      ],
    );
  }
}

class _MethodSection extends ConsumerWidget {
  const _MethodSection({required this.config, required this.countryName});

  final PrayerConfig config;
  final String? countryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = context.sk.text;
    final location = config.location;
    final prayer = ref.read(prayerRepositoryProvider);
    final formats = ProsocheFormats(Localizations.localeOf(context));
    final day = config.schedule.day(ref.watch(localDateProvider));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            location.city ?? location.country,
            key: const ValueKey('location:city'),
            style: text.titleMedium,
          ),
        ),
        const SizedBox(height: SkSpace.space8),
        Text(
          l10n.onbMethodBody(countryName ?? location.country),
          style: text.bodyMedium,
        ),
        const SizedBox(height: SkSpace.space12),
        DropdownButtonFormField<PrayerMethod>(
          key: ValueKey('method:${config.settings.method.key}'),
          initialValue: config.settings.method,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.onbMethodLabel),
          items: [
            for (final m in PrayerMethod.values)
              DropdownMenuItem(
                value: m,
                child: Text(
                  l10n.onbMethodName(m.key),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: prayer.setMethod,
        ),
        const SizedBox(height: SkSpace.space12),
        DropdownButtonFormField<AsrMadhab>(
          key: ValueKey('asr:${config.settings.asr.key}'),
          initialValue: config.settings.asr,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.onbAsrLabel),
          items: [
            DropdownMenuItem(
              value: AsrMadhab.shafi,
              child: Text(l10n.onbAsrShafi, overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: AsrMadhab.hanafi,
              child: Text(l10n.onbAsrHanafi),
            ),
          ],
          onChanged: (a) {
            if (a != null) unawaited(prayer.setAsr(a));
          },
        ),
        if (location.lat.abs() > highLatitudeThreshold) ...[
          const SizedBox(height: SkSpace.space12),
          SkInlineBanner(message: l10n.onbHighLatNote),
        ],
        const SizedBox(height: SkSpace.space16),
        Text(l10n.onbTodayTimes, style: text.titleSmall),
        const SizedBox(height: SkSpace.space4),
        Wrap(
          spacing: SkSpace.space16,
          runSpacing: SkSpace.space4,
          children: [
            for (final p in Prayer.salah)
              Text(
                '${l10n.notifPrayerName(p.name)} ${formats.time(day[p])}',
                style: text.bodyMedium,
              ),
          ],
        ),
      ],
    );
  }
}

/// Offline vyhladavanie mesta (A7.3 v onboarding mode). Vrati vybrate
/// [City] cez `Navigator.pop`.
class CitySearchSheet extends StatefulWidget {
  const CitySearchSheet({required this.cities, super.key});

  final CityRepository cities;

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  String _query = '';
  Future<List<City>>? _results;

  void _search(String q) {
    setState(() {
      _query = q.trim();
      // FutureBuilder sa prihlasi az pri builde; chyba nesmie byt
      // medzitym neosetrena.
      _results = _query.isEmpty
          ? null
          : (widget.cities.search(_query)..ignore());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(SkSpace.space16),
              child: TextField(
                key: const ValueKey('city:search'),
                autofocus: true,
                onChanged: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.onbCitySearchHint,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<City>>(
                // Novy dotaz = novy future; stary vysledok sa nezobrazi.
                key: ValueKey(_query),
                future: _results,
                builder: (context, snap) {
                  if (_results == null) return const SizedBox.shrink();
                  if (snap.hasError) {
                    return SkErrorState(
                      title: l10n.onbCitySearchError,
                      onRetry: () => _search(_query),
                    );
                  }
                  final cities = snap.data;
                  if (cities == null) {
                    return const SkLoadingView(skeleton: SkSkeleton.list());
                  }
                  if (cities.isEmpty) {
                    return SkEmptyState(title: l10n.onbCitySearchEmpty);
                  }
                  return ListView(
                    children: [
                      for (final c in cities)
                        ListTile(
                          key: ValueKey('city:${c.id}'),
                          title: Text(c.name),
                          subtitle: c.countryName == null
                              ? null
                              : Text(c.countryName!),
                          onTap: () => Navigator.of(context).pop(c),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
