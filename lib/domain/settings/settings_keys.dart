import 'package:prosoche/domain/settings/setting_key.dart';

/// Vsetky kluce tabulky `settings` (docs/02 0.7).
///
/// Defaulty, ktore zavisia od prostredia (system locale, generovane
/// `install_id`), su tu `null` a doplna ich ten, kto kluc pouziva. Novy kluc
/// = zmena kontraktu, ide samostatnou ulohou.
abstract final class SettingsKeys {
  // Onboarding
  static final SettingKey<bool> onboardingCompleted = SettingKey.boolean(
    'onboarding.completed',
    defaultValue: false,
  );
  static final SettingKey<String> onboardingStep = SettingKey.string(
    'onboarding.step',
    defaultValue: 'welcome',
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

  /// Tema appky (docs/02 A10.6): `system`, `light` alebo `dark`.
  static final SettingKey<String> displayTheme = SettingKey.string(
    'display.theme',
    defaultValue: 'system',
    allowed: displayThemes.toSet(),
  );

  /// Hodnoty [displayTheme] v poradi vyberu.
  static const displayThemes = ['system', 'light', 'dark'];

  // Umysel dna (onboarding, Journey)
  static final SettingKey<String?> intentionText = SettingKey.optionalString(
    'intention.text',
  );
  static final SettingKey<String?> intentionPreset = SettingKey.optionalString(
    'intention.preset',
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

  // Notifikacie
  static final SettingKey<bool> notifMorningEnabled = SettingKey.boolean(
    'notif.morning.enabled',
    defaultValue: true,
  );
  static final SettingKey<String> notifMorningTime = SettingKey.string(
    'notif.morning.time',
    defaultValue: '07:30',
    pattern: RegExp(r'^([01]\d|2[0-3]):[0-5]\d$'),
  );

  /// Notifikacie bez obsahu karty na zamknutej obrazovke.
  static final SettingKey<bool> notifPrivateLockscreen = SettingKey.boolean(
    'notif.private_lockscreen',
    defaultValue: true,
  );

  // Obsah
  static final SettingKey<bool> contentUpdateWifiOnly = SettingKey.boolean(
    'content.update_wifi_only',
    defaultValue: true,
  );

  // Brana
  static final SettingKey<bool> blockerEnabled = SettingKey.boolean(
    'blocker.enabled',
    defaultValue: false,
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

  static const onboardingSteps = {
    'welcome',
    'intention',
    'notifications',
    'gate_apps',
    'permissions',
    'privacy',
  };

  /// Vsetky pevne kluce.
  static final List<SettingKey<Object?>> all = [
    onboardingCompleted,
    onboardingStep,
    ageConfirmed16,
    installId,
    uiLocale,
    displayTheme,
    intentionText,
    intentionPreset,
    feedCardsCount,
    cardSeenDwellMs,
    simpleMode,
    notifMorningEnabled,
    notifMorningTime,
    notifPrivateLockscreen,
    contentUpdateWifiOnly,
    blockerEnabled,
    analyticsOptIn,
    crashReports,
  ];
}
