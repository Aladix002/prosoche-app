@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/features/settings/privacy_settings_screen.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_screen.dart';
import 'package:prosoche/features/settings/sources_screen.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'settings_test_app.dart';

ThemeData _theme(Brightness b) =>
    b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

const _screen = BoxConstraints.tightFor(width: 360, height: 760);

/// Placeholder zdroje (tvar riadkov `source`, nie skutocne atribucie).
const _sources = SourcesInfo(
  contentVersion: '2026.11.1',
  sources: [
    ContentSource(
      id: 'fx-uthmani',
      kind: 'quran_text',
      name: '[PLACEHOLDER quran text]',
      version: '1.1',
      license: 'CC BY 3.0',
      attribution: '[PLACEHOLDER attribution]',
      url: 'https://example.invalid/quran',
    ),
    ContentSource(
      id: 'fx-en',
      kind: 'translation',
      lang: 'en',
      name: '[PLACEHOLDER translation]',
      version: '1.1.2',
      license: '[PLACEHOLDER license]',
      attribution: '[PLACEHOLDER attribution]',
      url: 'https://example.invalid/en',
    ),
    ContentSource(
      id: 'fx-font',
      kind: 'font',
      name: '[PLACEHOLDER font]',
      version: '1.0',
      license: 'OFL-1.1',
      attribution: '[PLACEHOLDER attribution]',
      url: 'https://example.invalid/font',
    ),
  ],
);

/// Goldeny nastaveni A10.0, A10.9 a A11 (EN, AR, UR, BN, smoke ID a TR).
///
///   flutter test --update-goldens test/features/settings/settings_golden_test.dart
void main() {
  final overrides = [
    ...settingsOverrides(fakes: FakeRepositories()),
    sourcesInfoProvider.overrideWith((ref) async => _sources),
  ];

  Widget screen(Widget child) => ProviderScope(
    overrides: overrides,
    retry: (_, _) => null,
    child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
  );

  goldenAllLocales(
    'SettingsScreen',
    fileName: 'f07_settings',
    theme: _theme,
    constraints: _screen,
    builder: (_) => screen(const SettingsScreen()),
  );

  goldenAllLocales(
    'PrivacySettingsScreen',
    fileName: 'f07_privacy',
    theme: _theme,
    constraints: _screen,
    builder: (_) => screen(const PrivacySettingsScreen()),
  );

  goldenAllLocales(
    'SourcesScreen',
    fileName: 'f07_sources',
    theme: _theme,
    constraints: _screen,
    builder: (_) => screen(const SourcesScreen()),
  );
}
