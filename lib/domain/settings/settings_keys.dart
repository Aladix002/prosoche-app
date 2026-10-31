import 'package:prosoche/domain/common/ayah_id.dart';
import 'package:prosoche/domain/ramadan/ramadan_season.dart';
import 'package:prosoche/domain/settings/prayer_location.dart';
import 'package:prosoche/domain/settings/setting_key.dart';

/// Vsetky kluce tabulky `settings` (docs/02 0.7).
///
/// Defaulty, ktore zavisia od prostredia (system locale, krajina, zemepisna
/// sirka, generovane `install_id`), su tu `null` a doplna ich ten, kto kluc
/// pouziva. Novy kluc = zmena kontraktu, ide samostatnou ulohou.
abstract final class SettingsKeys {
  // Onboarding
  static final SettingKey<bool> onboardingCompleted = SettingKey.boolean(
    'onboarding.completed',
    defaultValue: false,
  );
  static final SettingKey<String> onboardingStep = SettingKey.string(
    'onboarding.step',
    defaultValue: 'language',
    allowed: onboardingSteps,
  );

  /// Pouzivatel v onboardingu potvrdil vek 16+ (docs/02 0.7, plan 24.3).
  static final SettingKey<bool> ageConfirmed16 = SettingKey.boolean(
    'age_confirmed_16',
    defaultValue: false,
  );

  /// UUID pre seed. Generuje sa pri prvom starte, nikdy neodchadza z appky.
  static final SettingKey<String?> installId = SettingKey.optionalString(
    'install_id',
  );

  // Jazyk a zobrazenie
  /// null = jazyk systemu, fallback `en`.
  static final SettingKey<String?> uiLocale = SettingKey.optionalString(
    'ui.locale',
  );
  static final SettingKey<bool> displayTranslit = SettingKey.boolean(
    'display.translit',
    defaultValue: false,
  );
  static final SettingKey<bool> displayTranslation = SettingKey.boolean(
    'display.translation',
    defaultValue: true,
  );

  /// Tema appky (docs/02 A10.6): `system`, `light` alebo `dark`.
  static final SettingKey<String> displayTheme = SettingKey.string(
    'display.theme',
    defaultValue: 'system',
    allowed: displayThemes.toSet(),
  );

  /// Hodnoty [displayTheme] v poradi vyberu.
  static const displayThemes = ['system', 'light', 'dark'];

  /// Nasobok nad systemovy text scale len pre arabsky text.
  static final SettingKey<double> displayArabicScale = SettingKey.decimal(
    'display.arabic_scale',
    defaultValue: 1,
    min: 0.5,
    max: 3,
  );

  // Niyyah
  static final SettingKey<String?> niyyahText = SettingKey.optionalString(
    'niyyah.text',
  );
  static final SettingKey<String?> niyyahPreset = SettingKey.optionalString(
    'niyyah.preset',
  );

  // Denna sada
  static final SettingKey<int> feedCardsCount = SettingKey.integer(
    'feed.cards_count',
    defaultValue: 12,
    allowed: const {8, 12, 16},
  );
  static final SettingKey<int> cardSeenDwellMs = SettingKey.integer(
    'card.seen_dwell_ms',
    defaultValue: 2500,
    min: 0,
    max: 60000,
  );

  /// Skryje streak a grace days.
  static final SettingKey<bool> simpleMode = SettingKey.boolean(
    'simple_mode',
    defaultValue: false,
  );

  // Modlitby
  static final SettingKey<PrayerLocation?> prayerLocation =
      SettingKey.json<PrayerLocation?>(
        'prayer.location',
        defaultValue: null,
        fromJson: PrayerLocation.fromJson,
        toJson: (v) => v?.toJson(),
      );

  /// Nazov metody adhan_dart; null = predvolba podla krajiny (P-01).
  static final SettingKey<String?> prayerMethod = SettingKey.optionalString(
    'prayer.method',
  );
  static final SettingKey<String> prayerAsr = SettingKey.string(
    'prayer.asr',
    defaultValue: 'shafi',
    allowed: const {'shafi', 'hanafi'},
  );

  /// Pravidlo vysokych sirok adhan_dart; null = `middle_of_night` pre
  /// lat > 48, inak bez pravidla (P-01).
  static final SettingKey<String?> prayerHighLatRule =
      SettingKey.optionalString('prayer.high_lat_rule');

  /// Posun v minutach pre jednotlive modlitby, chybajuca = 0.
  static final SettingKey<Map<String, int>> prayerAdjust =
      SettingKey.json<Map<String, int>>(
        'prayer.adjust',
        defaultValue: const {},
        fromJson: _adjustFromJson,
        toJson: (v) => v,
      );

  static final SettingKey<int> hijriOffset = SettingKey.integer(
    'hijri.offset',
    defaultValue: 0,
    min: -2,
    max: 2,
  );

  // Notifikacie
  static SettingKey<bool> notifPrayer(String prayer) {
    if (!prayers.contains(prayer)) {
      throw ArgumentError.value(prayer, 'prayer', 'one of $prayers');
    }
    return SettingKey.boolean('notif.prayer.$prayer', defaultValue: true);
  }

  static final SettingKey<bool> notifMorningEnabled = SettingKey.boolean(
    'notif.morning.enabled',
    defaultValue: true,
  );
  static final SettingKey<String> notifMorningTime = SettingKey.string(
    'notif.morning.time',
    defaultValue: '07:30',
    pattern: RegExp(r'^([01]\d|2[0-3]):[0-5]\d$'),
  );

  /// Notifikacie bez nabozenskeho obsahu na zamknutej obrazovke.
  static final SettingKey<bool> notifPrivateLockscreen = SettingKey.boolean(
    'notif.private_lockscreen',
    defaultValue: true,
  );

  /// Posledna potvrdena IANA casova zona (docs/01 5.6). Ina zona
  /// zariadenia pozastavi notifikacie modlitieb do potvrdenia polohy.
  static final SettingKey<String?> notifConfirmedTz = SettingKey.optionalString(
    'notif.confirmed_tz',
  );

  // Audio a obsah
  static final SettingKey<String> audioReciter = SettingKey.string(
    'audio.reciter',
    defaultValue: 'Alafasy_128kbps',
  );
  static final SettingKey<bool> audioWifiOnly = SettingKey.boolean(
    'audio.wifi_only',
    defaultValue: false,
  );
  static final SettingKey<bool> contentUpdateWifiOnly = SettingKey.boolean(
    'content.update_wifi_only',
    defaultValue: true,
  );

  // Brana
  static final SettingKey<bool> blockerEnabled = SettingKey.boolean(
    'blocker.enabled',
    defaultValue: false,
  );
  static final SettingKey<int> blockerPrayerLockMinutes = SettingKey.integer(
    'blocker.prayer_lock_minutes',
    defaultValue: 15,
    min: 0,
    max: 120,
  );

  // Sukromie
  static final SettingKey<bool> analyticsOptIn = SettingKey.boolean(
    'analytics_opt_in',
    defaultValue: false,
  );

  /// Vyslovny suhlas s hlasenim chyb, default vypnute (TECHNICKY_PLAN 13).
  static final SettingKey<bool> crashReports = SettingKey.boolean(
    'crash_reports',
    defaultValue: false,
  );

  // Ramadan (F-08)
  /// Potvrdenie sezony Ramadanu (`ramadan.season`), kodek vlastni F-08.
  static final SettingKey<RamadanConfirmation?> ramadanSeason =
      RamadanConfirmation.settingKey;

  // Pozicie
  static final SettingKey<int> readerLastAyahId = SettingKey.integer(
    'reader.last_ayah_id',
    defaultValue: 1001,
    min: AyahId.first.value,
    max: AyahId.last.value,
  );
  static final SettingKey<int> namesCursor = SettingKey.integer(
    'names.cursor',
    defaultValue: 1,
    min: 1,
    max: 99,
  );

  /// Posledny ayah_id eventu (napr. `event_cursor.jumuah`); null = prvy vers
  /// eventu.
  static SettingKey<int?> eventCursor(String eventId) {
    if (!_eventId.hasMatch(eventId)) {
      throw ArgumentError.value(eventId, 'eventId', '[a-z0-9_]+');
    }
    return SettingKey.optionalInt(
      'event_cursor.$eventId',
      isValid: (v) => AyahId.tryFromValue(v) != null,
    );
  }

  static final SettingKey<int> journeyLastKhatmSeen = SettingKey.integer(
    'journey.last_khatm_seen',
    defaultValue: 0,
    min: 0,
  );

  /// Zvoleny preklad (`source_id`) pre jazyk [lang]; null = prvy zdroj.
  static SettingKey<int?> translation(String lang) {
    if (!_lang.hasMatch(lang)) {
      throw ArgumentError.value(lang, 'lang', 'ISO 639-1/3 code');
    }
    return SettingKey.optionalInt('translation.$lang', isValid: (v) => v > 0);
  }

  static const onboardingSteps = {
    'language',
    'niyyah',
    'location',
    'notifications',
    'gate_apps',
    'permissions',
    'privacy',
  };

  /// Modlitby s nastavitelnou notifikaciou a posunom.
  static const prayers = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};

  /// Vsetky pevne kluce (bez rodin [translation], [notifPrayer],
  /// [eventCursor]).
  static final List<SettingKey<Object?>> all = [
    onboardingCompleted,
    onboardingStep,
    ageConfirmed16,
    installId,
    uiLocale,
    displayTranslit,
    displayTranslation,
    displayTheme,
    displayArabicScale,
    niyyahText,
    niyyahPreset,
    feedCardsCount,
    cardSeenDwellMs,
    simpleMode,
    prayerLocation,
    prayerMethod,
    prayerAsr,
    prayerHighLatRule,
    prayerAdjust,
    hijriOffset,
    notifMorningEnabled,
    notifMorningTime,
    notifPrivateLockscreen,
    notifConfirmedTz,
    audioReciter,
    audioWifiOnly,
    contentUpdateWifiOnly,
    blockerEnabled,
    blockerPrayerLockMinutes,
    analyticsOptIn,
    crashReports,
    ramadanSeason,
    readerLastAyahId,
    namesCursor,
    journeyLastKhatmSeen,
  ];

  /// Prefixy rodin klucov.
  static const familyPrefixes = {
    'translation.',
    'notif.prayer.',
    'event_cursor.',
  };

  static final RegExp _lang = RegExp(r'^[a-z]{2,3}$');
  static final RegExp _eventId = RegExp(r'^[a-z0-9_]{1,64}$');

  static Map<String, int> _adjustFromJson(Object json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('prayer.adjust: expected object');
    }
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (prayers.contains(key) &&
            value is int &&
            value >= -60 &&
            value <= 60)
          key: value
        else
          key: throw FormatException('prayer.adjust: invalid $key=$value'),
    };
  }
}
