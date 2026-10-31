import 'package:meta/meta.dart';

/// Produktova analytika (TECHNICKY_PLAN 19, docs/02 0.6, D19).
///
/// Volajuci posiela len nazov eventu z [AnalyticsSchema] a jeho vlastnosti.
/// Implementacia zahodi nezname eventy, nepovolene vlastnosti a hodnoty,
/// ktore nie su bool, cislo alebo kratky identifikator. Bez suhlasu
/// `analytics_opt_in` sa nic neodosiela.
abstract interface class Analytics {
  void track(String event, [Map<String, Object?> props = const {}]);
}

/// Analytika, ktora vsetko zahodi (bez suhlasu, bez kluca, v testoch).
final class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void track(String event, [Map<String, Object?> props = const {}]) {}
}

/// Allowlist eventov a vlastnosti (TECHNICKY_PLAN 19, docs/02 D19).
///
/// Ziadny event nesmie obsahovat `card_id`, `ayah_id`, nazov sury, stav
/// modlitby, nazov appky ani polohu (docs/02 0.6). Preto je zoznam
/// vlastnosti uzavrety a hodnoty textovych vlastnosti su len kratke
/// identifikatory (`[a-z0-9_]`, verzie s bodkami), nie volny text.
abstract final class AnalyticsSchema {
  /// Event -> povolene vlastnosti.
  static const events = <String, Set<String>>{
    'onboarding_step': {'step', 'skipped'},
    'onboarding_completed': {'blocker_enabled', 'notif_granted'},
    'screen_view': {'screen'},
    'permission_result': {'permission', 'granted'},
    'daily_set_started': {'cards_count', 'duration_s'},
    'daily_set_completed': {'cards_count', 'duration_s'},
    'card_action': {'type', 'action'},
    'gate_apps_selected': {'count'},
    'gate_shown': {'cards_required'},
    'gate_passed': {'cards_required'},
    'gate_emergency': {'cards_required'},
    'gate_dismissed': {'cards_seen'},
    'quest_completed': {'slot'},
    'quiz_session_completed': {'count', 'correct'},
    'audio_play': {'source'},
    'feature_used': {'feature'},
    'backup_exported': {'result'},
    'backup_imported': {'result'},
    'content_updated': {'from_version', 'to_version'},
  };

  /// Spolocne vlastnosti kazdeho eventu (docs/02 0.6). Nic ine.
  static const superProperties = {
    'app_version',
    'content_version',
    'locale',
    'flavor',
  };

  /// Textova hodnota: kratky identifikator bez medzier, bodiek a velkych
  /// pismen (bodka by pustila package name appky, `com.example.app`).
  static final _token = RegExp(r'^[a-z0-9_]{1,48}$');

  /// Verzie (`1.2.0+10`, `2026.11.1`).
  static final _version = RegExp(r'^[0-9][0-9a-z.+\-]{0,31}$');
  static const _versionKeys = {
    'app_version',
    'content_version',
    'from_version',
    'to_version',
  };

  /// `screen` je nazov routy z docs/02 C2 (`quran_reader`), nikdy cesta
  /// s parametrami (`/quran/read/2`), preto bez cislic a lomiek.
  static final _screen = RegExp(r'^[a-z][a-z_]{0,47}$');

  static bool isKnownEvent(String event) => events.containsKey(event);

  /// Povolene vlastnosti s platnymi hodnotami. Ostatne zahodi.
  static Map<String, Object> sanitize(
    String event,
    Map<String, Object?> props,
  ) {
    final allowed = events[event];
    if (allowed == null) return const {};
    return {
      for (final e in props.entries)
        if (allowed.contains(e.key) && isValidValue(e.key, e.value))
          e.key: e.value!,
    };
  }

  /// Spolocne vlastnosti s platnymi hodnotami.
  static Map<String, Object> sanitizeSuper(Map<String, Object?> props) => {
    for (final e in props.entries)
      if (superProperties.contains(e.key) && isValidValue(e.key, e.value))
        e.key: e.value!,
  };

  @visibleForTesting
  static bool isValidValue(String key, Object? value) => switch (value) {
    bool() => true,
    int() => true,
    double() => value.isFinite,
    String() => switch (key) {
      'screen' => _screen,
      _ when _versionKeys.contains(key) => _version,
      _ => _token,
    }.hasMatch(value),
    _ => false,
  };
}
