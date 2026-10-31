import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/shell/app_locale.dart';
import 'package:prosoche/ui/foundation/sk_text_scaling.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/i18n/locale_fonts.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

class ProsocheApp extends ConsumerWidget {
  const ProsocheApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // F-07: tema (system/svetla/tmava) z nastaveni.
    final themeMode = ref.watch(appThemeModeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      // Temy MaterialApp su zaklad (bez routera, napr. ScaffoldMessenger);
      // obsah dostane v builderi temu s fontom jazyka.
      theme: ProsocheTheme.light(),
      darkTheme: ProsocheTheme.dark(),
      highContrastTheme: ProsocheTheme.light(highContrast: true),
      highContrastDarkTheme: ProsocheTheme.dark(highContrast: true),
      themeMode: themeMode,
      routerConfig: router,
      // Predictive back (Android 14+, enableOnBackInvokedCallback): engine
      // zavrie aktivitu, ked od frameworku nevie, ze back spracuje (I-03).
      onNavigationNotification: (n) => handleNavigationNotification(n, router),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // F-01: `ui.locale` (O1), inak jazyk systemu cez ProsocheLocales.resolve.
      locale: ref.watch(appLocaleProvider),
      localeListResolutionCallback: resolveAppLocales,
      builder: (context, child) {
        final l10n = context.l10n;
        if (kReleaseMode) {
          // V release neutralna karta namiesto sivej/cervenej plochy.
          final message = l10n.errorGeneric;
          ErrorWidget.builder = (_) => _ErrorFallback(message: message);
        }
        return Theme(
          data: prosocheAppTheme(
            brightness: brightnessFor(
              themeMode,
              MediaQuery.platformBrightnessOf(context),
            ),
            highContrast: MediaQuery.highContrastOf(context),
            locale: Localizations.localeOf(context),
          ),
          child: SkTextScaling(
            child: SkUiStringsScope(
              strings: skUiStringsOf(l10n),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// `WidgetsApp.onNavigationNotification`: posle enginu
/// `setFrameworkHandlesBack`, ze back spracuje framework, ked to tvrdi
/// notifikacia **alebo** ked [router] vie popnut (push routy nad shellom,
/// vnorene navigatory).
///
/// Pricina chyby I-03: default Flutteru (`_defaultOnNavigationNotification`)
/// notifikaciu zahodi, kym `lifecycleState` je null. Ked engine framework-u
/// stav zivotneho cyklu nikdy neohlasi (videne pri studenom starte v E2E,
/// prerusovane), zahodia sa vsetky notifikacie, engine nezaregistruje
/// OnBackInvokedCallback a systemovy back zavrie aktivitu, hoci router ma
/// co popnut. Preto sa preskakuje len `detached`.
bool handleNavigationNotification(
  NavigationNotification notification,
  GoRouter router,
) {
  if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
    return true;
  }
  final handles = notification.canHandlePop || router.canPop();
  SystemNavigator.setFrameworkHandlesBack(handles).ignore();
  return true;
}

/// Tema appky pre jazyk UI: [ProsocheTheme] (U-01) s fontom a riadkovanim
/// jazyka z [LocaleFonts] (U-02). Komponentove temy (tlacidla, nav bar)
/// dostanu rodinu a nasobok vysky riadku, `textTheme` presne
/// [applyLocaleFontToTextTheme] (fallback, min. vyska riadku).
ThemeData prosocheAppTheme({
  required Brightness brightness,
  required Locale locale,
  bool highContrast = false,
}) {
  final spec = LocaleFonts.forLocale(locale);
  ThemeData build({String? family, double heightFactor = 1}) =>
      brightness == Brightness.dark
      ? ProsocheTheme.dark(
          highContrast: highContrast,
          uiFontFamily: family ?? ProsocheFontFamilies.inter,
          uiHeightFactor: heightFactor,
        )
      : ProsocheTheme.light(
          highContrast: highContrast,
          uiFontFamily: family ?? ProsocheFontFamilies.inter,
          uiHeightFactor: heightFactor,
        );
  final base = build();
  final themed = spec.family == ProsocheFontFamilies.inter
      ? base
      : build(family: spec.family, heightFactor: spec.lineHeightScale);
  return themed.copyWith(
    textTheme: applyLocaleFontToTextTheme(base.textTheme, locale),
  );
}

/// Genericke texty komponentov `lib/ui` z ARB (`lib/l10n/parts/U-01_en.arb`).
SkUiStrings skUiStringsOf(AppLocalizations l10n) => SkUiStrings(
  loading: l10n.skLoading,
  stillLoading: l10n.skStillLoading,
  tryAgain: l10n.skTryAgain,
  dismiss: l10n.skDismiss,
  undo: l10n.skUndo,
  cancel: l10n.skCancel,
  done: l10n.skDone,
  skippedForToday: l10n.skSkippedForToday,
  iDidIt: l10n.skIDidIt,
  freeReading: l10n.skFreeReading,
  dailyCards: l10n.skDailyCards,
  scrollForMore: l10n.skScrollForMore,
  holdToConfirm: l10n.skHoldToConfirm,
  contentUnavailableTitle: l10n.skContentUnavailableTitle,
  contentUnavailableBody: l10n.skContentUnavailableBody,
  progressOf: l10n.skProgressOf,
  // F-01: "Translated by George Long (1862)" (karty, citacka, obrazok).
  translatedBy: (translator, year) => year == null
      ? l10n.cardTranslatedBy(translator)
      : l10n.cardTranslatedByYear(translator, year),
);

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Material(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    ),
  );
}
