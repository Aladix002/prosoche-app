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

  /// Velkost pisma v citacke Library (docs/DESIGN.md 3.6): `s`, `m`, `l`,
  /// `xl` (0.9, 1.0, 1.15, 1.3 x systemovy TextScaler). I-01.
  static final SettingKey<String> readerScale = SettingKey.string(
    'reader.scale',
    defaultValue: 'm',
    allowed: readerScales.toSet(),
  );

  /// Hodnoty [readerScale] v poradi vyberu.
  static const readerScales = ['s', 'm', 'l', 'xl'];

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

  /// Vecerna pripomienka reflexie (F-01), opt-in.
  static final SettingKey<bool> notifEveningEnabled = SettingKey.boolean(
    'notif.evening.enabled',
    defaultValue: false,
  );
  static final SettingKey<String> notifEveningTime = SettingKey.string(
    'notif.evening.time',
    defaultValue: '21:00',
    pattern: RegExp(r'^([01]\d|2[0-3]):[0-5]\d$'),
  );

  /// Notifikacie bez obsahu karty na zamknutej obrazovke.
  static final SettingKey<bool> notifPrivateLockscreen = SettingKey.boolean(
    'notif.private_lockscreen',
    defaultValue: true,
  );

  // Practice (F-01)
  /// Rok narodenia pre memento mori (tyzdne zivota). Volitelne, len lokalne,
  /// nikdy v analytike.
  static final SettingKey<int?> practiceBirthYear = SettingKey.optionalInt(
    'practice.birth_year',
    isValid: (y) => y >= 1900 && y <= 2100,
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

  /// Brana sa spyta "Why are you opening {app}?" (G-01).
  static final SettingKey<bool> gateAskIntent = SettingKey.boolean(
    'gate.ask_intent',
    defaultValue: true,
  );

  /// Pocitadlo otvoreni dna a rastuci odpor (G-01).
  static final SettingKey<bool> gateRisingFriction = SettingKey.boolean(
    'gate.rising_friction',
    defaultValue: true,
  );

  /// Ranny zamok "Practice first" (G-01), opt-in.
  static final SettingKey<bool> gatePracticeFirst = SettingKey.boolean(
    'gate.practice_first',
    defaultValue: false,
  );

  /// Koniec ranneho zamku `HH:mm` (G-01).
  static final SettingKey<String> gatePracticeFirstUntil = SettingKey.string(
    'gate.practice_first.until',
    defaultValue: '10:00',
    pattern: RegExp(r'^([01]\d|2[0-3]):[0-5]\d$'),
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
    readerScale,
    intentionText,
    intentionPreset,
    feedCardsCount,
    cardSeenDwellMs,
    simpleMode,
    notifMorningEnabled,
    notifMorningTime,
    notifEveningEnabled,
    notifEveningTime,
    notifPrivateLockscreen,
    practiceBirthYear,
    contentUpdateWifiOnly,
    blockerEnabled,
    gateAskIntent,
    gateRisingFriction,
    gatePracticeFirst,
    gatePracticeFirstUntil,
    analyticsOptIn,
    crashReports,
  ];
}
