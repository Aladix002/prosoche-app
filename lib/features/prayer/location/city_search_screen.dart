import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/prayer/country_defaults.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/prayer/prayer_providers.dart';
import 'package:sakina/features/prayer/prayer_texts.dart';
import 'package:sakina/ui/ui.dart';

/// Vyber mesta (docs/02 A7.3): "Use my location" a offline vyhladavanie
/// v tabulke `city`. Routy `/settings/prayer/location` a
/// `/settings/prayer/location/search`.
///
/// [onPicked] pouzije onboarding O3 (F-01): mesto len vrati a nic neuklada.
/// Bez neho sa mesto ulozi ([applyCity]) a obrazovka sa zavrie.
class CitySearchScreen extends ConsumerStatefulWidget {
  const CitySearchScreen({this.onPicked, super.key});

  final ValueChanged<City>? onPicked;

  /// Oneskorenie vyhladavania po pisani.
  static const debounce = Duration(milliseconds: 200);

  /// Max. cakanie na GPS (O3: timeout 10 s).
  static const locateTimeout = Duration(seconds: 10);

  @override
  ConsumerState<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends ConsumerState<CitySearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _locating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(CitySearchScreen.debounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  Future<void> _pick(City city) async {
    final onPicked = widget.onPicked;
    if (onPicked != null) return onPicked(city);
    await applyCity(context, ref, city);
    if (mounted && context.canPop()) context.pop();
  }

  Future<void> _useLocation(DeviceLocator locator) async {
    setState(() => _locating = true);
    City? city;
    try {
      final fix = await locator.locate().timeout(
        CitySearchScreen.locateTimeout,
      );
      if (fix != null) {
        city = await ref.read(cityRepositoryProvider).nearest(fix.lat, fix.lng);
      }
    } on Object {
      city = null;
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (city == null) {
      final l10n = context.l10n;
      showSkSnackbar(
        context,
        message:
            '${l10n.cityLocationErrorTitle}. ${l10n.cityLocationErrorBody}',
      );
      return;
    }
    await _pick(city);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final locator = ref.watch(deviceLocatorProvider);
    final current = ref.watch(prayerConfigProvider).value?.location.city;
    final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: skAppBar(context, title: l10n.citySearchTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              SkSpace.space8,
              gutter,
              SkSpace.space8,
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (t) {
                _debounce?.cancel();
                setState(() => _query = t.trim());
              },
              decoration: InputDecoration(
                hintText: l10n.citySearchHint,
                hintMaxLines: 3,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _controller.text.isEmpty
                      ? const SizedBox.shrink()
                      : SkIconButton(
                          icon: Icons.clear,
                          tooltip: l10n.citySearchClear,
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
          ),
          if (locator != null)
            ListTile(
              leading: _locating
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              title: Text(
                _locating ? l10n.cityLocating : l10n.prayerUseMyLocation,
              ),
              enabled: !_locating,
              onTap: () => unawaited(_useLocation(locator)),
            ),
          if (current != null && _query.isEmpty)
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: gutter,
                vertical: SkSpace.space8,
              ),
              child: Text(
                l10n.citySearchCurrent(current),
                style: sk.text.bodyMedium!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
            ),
          Expanded(
            child: _Results(query: _query, onPick: _pick),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onPick});

  final String query;
  final Future<void> Function(City) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    if (query.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(SkSpace.space24),
        child: Text(
          l10n.citySearchTips,
          textAlign: TextAlign.center,
          style: sk.text.bodyLarge!.copyWith(color: sk.colors.textSecondary),
        ),
      );
    }
    final results = ref.watch(citySearchProvider(query));
    if (results.hasError) {
      return SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(citySearchProvider(query)),
      );
    }
    if (!results.hasValue) {
      return const Center(child: SkLoadingView());
    }
    final cities = results.requireValue;
    if (cities.isEmpty) {
      return SkEmptyState(
        title: l10n.citySearchEmptyTitle(query),
        body: l10n.citySearchEmptyBody,
      );
    }
    return ListView.builder(
      itemCount: cities.length,
      itemBuilder: (context, i) {
        final c = cities[i];
        return ListTile(
          leading: const Icon(Icons.location_city_outlined),
          title: Text(c.name),
          subtitle: Text(c.countryName ?? c.countryCode),
          onTap: () => unawaited(onPick(c)),
        );
      },
    );
  }
}

/// Ulozi mesto ako `prayer.location` (A7.3, docs/01 5.6).
///
/// Repozitar prepocita metodu podla krajiny, ak je automaticka, a zavola
/// preplanovanie notifikacii. Ak bola metoda zvolena rucne a nova krajina
/// ma inu obvyklu metodu, ponukne zmenu (METHOD-SUGGEST). Na konci
/// snackbar "Prayer times updated for {city}."
Future<void> applyCity(BuildContext context, WidgetRef ref, City city) async {
  final repo = ref.read(prayerRepositoryProvider);
  final settings = ref.read(settingsRepositoryProvider);
  final before = await repo.config();
  final manual = await settings.get(SettingsKeys.prayerMethod) != null;
  await repo.saveLocation(city.toPrayerLocation());
  final suggested = CountryDefaults.forCountry(city.countryCode).method;
  final current = before?.settings.method;
  if (!context.mounted) return;
  if (manual &&
      current != null &&
      before?.location.country != city.countryCode &&
      suggested != current) {
    final l10n = context.l10n;
    final change = await showSkInfoSheet<bool>(
      context,
      title: l10n.prayerMethodSuggestTitle(
        context.methodName(suggested),
        city.countryName ?? city.countryCode,
      ),
      actions: [
        Builder(
          builder: (sheet) => SkButton.primary(
            label: l10n.prayerMethodSuggestSwitch,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
        ),
        Builder(
          builder: (sheet) => SkButton.secondary(
            label: l10n.prayerMethodSuggestKeep(context.methodName(current)),
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ),
      ],
      child: Text(l10n.prayerMethodSuggestBody),
    );
    // Automaticka metoda = obvykla metoda novej krajiny.
    if (change ?? false) await repo.setMethod(null);
    if (!context.mounted) return;
  }
  showSkSnackbar(context, message: context.l10n.prayerUpdatedFor(city.name));
}
