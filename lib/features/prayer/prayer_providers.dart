import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/qibla.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/prayer/location/city_ranking.dart';
import 'package:sakina/features/prayer/prayer_view.dart';
import 'package:timezone/timezone.dart' as tz;

/// Stav pripomienok modlitieb pre banery na A7.1 (docs/01 6 Prayer).
@immutable
final class PrayerReminderHealth {
  const PrayerReminderHealth({
    this.notificationsEnabled = true,
    this.exactAlarms = true,
  });

  /// Stav nezisteny alebo v poriadku: ziadny baner.
  static const ok = PrayerReminderHealth();

  /// false = Android blokuje notifikacie (P-NOTIF-BANNER).
  final bool notificationsEnabled;

  /// false = presne alarmy nie su povolene (P-EXACT-INFO).
  final bool exactAlarms;
}

/// Override point pre integraciu: `NotificationService.areEnabled()` a
/// `canScheduleExact()` (P-02). Default bez banerov.
final FutureProvider<PrayerReminderHealth> prayerReminderHealthProvider =
    FutureProvider<PrayerReminderHealth>(
      (ref) async => PrayerReminderHealth.ok,
      name: 'prayerReminderHealthProvider',
    );

/// Jednorazova poloha z GPS (O3, A7.3). `lat`/`lng` presne, zaokruhli ich
/// az [PrayerLocation]. Null = poloha nie je k dispozicii (zamietnute).
abstract interface class DeviceLocator {
  Future<({double lat, double lng})?> locate();
}

/// Override point pre `geolocator` (zdiela ho onboarding O3, F-01).
/// Default null: tlacidlo "Use my location" sa neukaze.
final Provider<DeviceLocator?> deviceLocatorProvider = Provider<DeviceLocator?>(
  (ref) => null,
  name: 'deviceLocatorProvider',
);

/// Fajr/isha dna `date` urcene pravidlom vysokych sirok.
final FutureProviderFamily<Set<Prayer>, LocalDate> estimatedPrayersProvider =
    FutureProvider.family<Set<Prayer>, LocalDate>((ref, date) async {
      final config = await ref.watch(prayerConfigProvider.future);
      return config == null
          ? const {}
          : estimatedPrayers(config.schedule, date);
    }, name: 'estimatedPrayersProvider');

/// Modlitby s vypnutou notifikaciou (`notif.prayer.{p}` = false).
final FutureProvider<Set<Prayer>> prayerNotificationsOffProvider =
    FutureProvider<Set<Prayer>>((ref) async {
      final off = <Prayer>{};
      for (final p in Prayer.salah) {
        final on = await ref.watch(
          settingProvider(SettingsKeys.notifPrayer(p.name)).future,
        );
        if (on == false) off.add(p);
      }
      return off;
    }, name: 'prayerNotificationsOffProvider');

/// Azimut qibly z ulozenej polohy; null bez polohy.
final FutureProvider<double?> qiblaBearingProvider = FutureProvider<double?>((
  ref,
) async {
  final config = await ref.watch(prayerConfigProvider.future);
  final l = config?.location;
  return l == null ? null : qiblaBearing(l.lat, l.lng);
}, name: 'qiblaBearingProvider');

/// Zona zariadenia sa lisi od zony polohy (A7.1 "Cestovanie", docs/01
/// 5.6). Porovnava sa aktualny posun od UTC, nie nazov zony
/// (Europe/Vienna a Europe/Bratislava su ta ista zona pre modlitby).
final FutureProvider<bool> prayerTimeZoneMismatchProvider =
    FutureProvider<bool>((ref) async {
      final config = await ref.watch(prayerConfigProvider.future);
      if (config == null) return false;
      final device = tryTimeZone(
        await ref.watch(deviceTimeZoneProvider.future),
      );
      if (device == null) return false;
      final now = ref.watch(appClockProvider).now();
      int offset(tz.Location l) =>
          l.timeZone(now.millisecondsSinceEpoch).offset.inMilliseconds;
      return offset(device) != offset(config.schedule.zone);
    }, name: 'prayerTimeZoneMismatchProvider');

/// Mesta pre dotaz (A7.3): prefix z content.db, poradie [rankCities].
final FutureProviderFamily<List<City>, String> citySearchProvider =
    FutureProvider.family<List<City>, String>((ref, query) async {
      final q = query.trim();
      if (q.isEmpty) return const [];
      final candidates = await ref
          .watch(cityRepositoryProvider)
          .search(q, limit: cityCandidateLimit);
      final config = await ref.watch(prayerConfigProvider.future);
      final reference =
          config?.location.tz ?? await ref.watch(deviceTimeZoneProvider.future);
      return rankCities(
        q,
        candidates,
        referenceZone: reference,
        now: ref.watch(appClockProvider).now(),
      );
    }, name: 'citySearchProvider');
