import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/data/repositories/settings/settings_providers.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/ui/i18n/sakina_locales.dart';

/// Jazyk UI z `settings.ui.locale` pre `MaterialApp.locale` (docs/02 0.7,
/// O1). null = jazyk systemu (ulozena volba chyba, este sa nacitava alebo
/// sa neda precitat); vyber zo systemovych jazykov robi
/// [resolveAppLocales].
final Provider<Locale?> appLocaleProvider = Provider<Locale?>((ref) {
  final stored = ref.watch(settingOf(SettingsKeys.uiLocale)).value;
  return stored == null ? null : SakinaLocales.resolve(stored: stored);
}, name: 'appLocaleProvider');

/// `MaterialApp.localeListResolutionCallback`: prvy podporovany jazyk zo
/// zoznamu (ulozena volba alebo systemove jazyky), inak `en`. Bez neho by
/// Flutter pre nepodporovany jazyk (napr. `de`) zvolil prvy zo
/// `supportedLocales` (`ar`).
Locale resolveAppLocales(List<Locale>? locales, Iterable<Locale> supported) =>
    SakinaLocales.resolve(deviceLocales: locales ?? const []);
