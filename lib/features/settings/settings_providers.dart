import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appBuildNumber;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_guard.dart';
import 'package:url_launcher/url_launcher.dart';

// Providery obrazoviek nastaveni (docs/02 A10, A11). Vlastnik: F-07.

// ------------------------------------------------------------------- tema

/// Hodnoty `SettingsKeys.displayTheme` v poradi vyberu (docs/02 A10.6).
const List<String> themeValues = SettingsKeys.displayThemes;

ThemeMode themeModeOf(String value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// Tema appky pre `MaterialApp` (lib/app.dart). Kym sa nastavenie nacita,
/// plati systemova.
final Provider<ThemeMode> appThemeModeProvider = Provider<ThemeMode>(
  (ref) =>
      themeModeOf(ref.watch(settingOf(SettingsKeys.displayTheme)).value ?? ''),
  name: 'appThemeModeProvider',
);

/// Jas temy pre [mode]; `system` = jas systemu [platform].
Brightness brightnessFor(ThemeMode mode, Brightness platform) => switch (mode) {
  ThemeMode.light => Brightness.light,
  ThemeMode.dark => Brightness.dark,
  ThemeMode.system => platform,
};

// ---------------------------------------------------------- odkazy, verzia

/// Otvori URL v prehliadaci; false = nepodarilo sa. V testoch override.
typedef LinkOpener = Future<bool> Function(Uri uri);

final Provider<LinkOpener> linkOpenerProvider = Provider<LinkOpener>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  },
  name: 'linkOpenerProvider',
);

/// Externe odkazy appky. Prazdne = riadok sa neukaze (URL OVERIT,
/// docs/02 O7; doplni sa cez `--dart-define`).
@immutable
final class AppLinks {
  const AppLinks({this.privacyPolicy, this.feedback});

  static const fromEnvironment = AppLinks(
    privacyPolicy: String.fromEnvironment('PRIVACY_POLICY_URL'),
    feedback: String.fromEnvironment('FEEDBACK_URL'),
  );

  final String? privacyPolicy;
  final String? feedback;

  Uri? get privacyPolicyUri => _uri(privacyPolicy);
  Uri? get feedbackUri => _uri(feedback);

  static Uri? _uri(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    return uri != null && uri.hasScheme ? uri : null;
  }
}

final Provider<AppLinks> appLinksProvider = Provider<AppLinks>(
  (ref) => AppLinks.fromEnvironment,
  name: 'appLinksProvider',
);

/// Cislo buildu (`FLUTTER_BUILD_NUMBER`); null = neznamy (napr. testy).
final Provider<String?> appBuildNumberProvider = Provider<String?>(
  (ref) => appBuildNumber,
  name: 'appBuildNumberProvider',
);

// ------------------------------------------------------- zdroje a licencie

/// Riadok tabulky `source` v content.db (docs/02 A11).
@immutable
final class ContentSource {
  const ContentSource({
    required this.id,
    required this.kind,
    required this.name,
    required this.version,
    required this.license,
    required this.attribution,
    required this.url,
    this.lang,
    this.licenseUrl,
    this.licenseText = '',
  });

  final String id;
  final String kind;
  final String? lang;
  final String name;
  final String version;
  final String license;
  final String? licenseUrl;
  final String licenseText;
  final String attribution;
  final String url;
}

/// Poradie skupin na obrazovke Zdroje (docs/02 A11). Nezname druhy idu na
/// koniec v abecednom poradi.
const sourceKindOrder = ['text', 'translation', 'curated', 'font'];

/// Zdroje zoskupene podla `kind` (preklady aj podla jazyka).
List<({String kind, List<ContentSource> sources})> groupSources(
  List<ContentSource> sources,
) {
  int rank(String kind) {
    final i = sourceKindOrder.indexOf(kind);
    return i < 0 ? sourceKindOrder.length : i;
  }

  final byKind = <String, List<ContentSource>>{};
  for (final s in sources) {
    (byKind[s.kind] ??= []).add(s);
  }
  final kinds = byKind.keys.toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.compareTo(b);
    });
  return [
    for (final k in kinds)
      (
        kind: k,
        sources: byKind[k]!
          ..sort((a, b) {
            final l = (a.lang ?? '').compareTo(b.lang ?? '');
            return l != 0 ? l : a.name.compareTo(b.name);
          }),
      ),
  ];
}

/// Obsah obrazovky Zdroje: vsetky riadky `source` a `content_version`.
@immutable
final class SourcesInfo {
  const SourcesInfo({required this.sources, this.contentVersion});

  final List<ContentSource> sources;
  final String? contentVersion;
}

final FutureProvider<SourcesInfo> sourcesInfoProvider =
    FutureProvider<SourcesInfo>((ref) async {
      final dao = (await ref.watch(contentDbProvider.future)).contentMetaDao;
      final rows = await dao.allSources();
      return SourcesInfo(
        contentVersion: await dao.metaValue('content_version'),
        sources: [
          for (final r in rows)
            ContentSource(
              id: r.id,
              kind: r.kind,
              name: r.name,
              version: r.version,
              license: r.license,
              // content.db v1: odovodnenie licencie (kontrakt kap. 5).
              licenseText: r.licenseNote,
              attribution: r.attribution,
              // Pri zdrojoch z Project Gutenberg je url NULL (kap. 5).
              url: r.url ?? '',
            ),
        ],
      );
    }, name: 'sourcesInfoProvider');

// ---------------------------------------------------------------- akcie

/// Po zmazani dat (A10.9): zrusenie notifikacii, reset analytiky a pod.
/// Integracia prepise; default nic.
final Provider<Future<void> Function()> afterDataDeletedProvider =
    Provider<Future<void> Function()>(
      (ref) => () async {},
      name: 'afterDataDeletedProvider',
    );

/// Zmeny nastaveni s vedlajsimi ucinkami mimo kluca v `settings`.
class SettingsActions {
  SettingsActions(this.ref);

  final Ref ref;

  /// "Delete all my data" (A10.9): zmaze user.db (vratane `settings`, teda
  /// aj `onboarding.completed`), vypne branu, zavola
  /// [afterDataDeletedProvider] a znovu vytvori router, ktory presmeruje do
  /// onboardingu (O1).
  Future<void> deleteAllData() async {
    final log = ref.read(appLoggerProvider);
    await ref.read(userDbProvider).deleteAllData();
    if (ref.read(featureFlagsProvider).gate) {
      final blocker = ref.read(blockerGatewayProvider);
      await blocker.setTargets(const []);
      await blocker.setEnabled(enabled: false);
    }
    try {
      await ref.read(afterDataDeletedProvider)();
    } on Object catch (e, st) {
      log.error('settings', 'after delete hook failed', error: e, stack: st);
    }
    ref
      ..invalidate(installIdProvider)
      ..invalidate(onboardingGuardProvider);
  }
}

final Provider<SettingsActions> settingsActionsProvider =
    Provider<SettingsActions>(
      SettingsActions.new,
      name: 'settingsActionsProvider',
    );
