import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/app.dart' show prosocheAppTheme, skUiStringsOf;
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/repositories/infra/databases.dart'
    show userDbProvider;
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/gate/gate_screen.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/shell/app_locale.dart';
import 'package:prosoche/ui/foundation/sk_text_scaling.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

/// Koren enginu brany (`gateMain`, ADR-16). Engine bezi predhriaty v
/// `FlutterEngineCache` uz pred otvorenim blokovanej appky; GateActivity
/// posle `onGateRequested(ref)` a az vtedy sa zobrazi [GateScreen]. Po
/// zavreti brany sa vrati do necinneho stavu, aby dalsie pripojenie
/// aktivity neukazalo staru branu.
class GateApp extends ConsumerStatefulWidget {
  const GateApp({this.initialApp, super.key});

  /// Appka bez poziadavky z nativu (testy).
  final String? initialApp;

  @override
  ConsumerState<GateApp> createState() => _GateAppState();
}

class _GateAppState extends ConsumerState<GateApp> {
  StreamSubscription<String>? _requests;
  String? _app;
  int _request = 0;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _app = widget.initialApp;
    _requests = ref.read(blockerGatewayProvider).gateRequests.listen((app) {
      // Aktivita je uz pripojena: targetSdk 36 edge-to-edge.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge).ignore();
      unawaited(_show(app));
    });
  }

  /// Poziadavka z nativu: najprv cerstve nastavenia, potom brana.
  Future<void> _show(String app) async {
    final request = ++_pending;
    await reloadGateSettings(ref);
    // Medzitym prisla novsia poziadavka alebo engine skoncil.
    if (!mounted || request != _pending) return;
    setState(() {
      _app = app;
      _request++;
    });
  }

  @override
  void dispose() {
    unawaited(_requests?.cancel());
    super.dispose();
  }

  void _closed() {
    if (mounted) setState(() => _app = null);
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    // Tema z nastaveni ako v hlavnej appke (`display.theme`).
    final themeMode = ref.watch(appThemeModeProvider);
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: ProsocheTheme.light(),
      darkTheme: ProsocheTheme.dark(),
      themeMode: themeMode,
      highContrastTheme: ProsocheTheme.light(highContrast: true),
      highContrastDarkTheme: ProsocheTheme.dark(highContrast: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(appLocaleProvider),
      localeListResolutionCallback: resolveAppLocales,
      builder: (context, child) {
        final brightness = brightnessFor(
          themeMode,
          MediaQuery.platformBrightnessOf(context),
        );
        // Edge-to-edge bez AppBar: ikony status baru podla temy (tmave
        // na svetlej ploche).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: gateSystemUiStyle(brightness),
          child: Theme(
            data: prosocheAppTheme(
              brightness: brightness,
              highContrast: MediaQuery.highContrastOf(context),
              locale: Localizations.localeOf(context),
            ),
            child: SkTextScaling(
              child: SkUiStringsScope(
                strings: skUiStringsOf(context.l10n),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: app == null
          ? const _GateIdle()
          : GateScreen(key: ValueKey(_request), app: app, onClosed: _closed),
    );
  }
}

/// Oznami drift streamom v izolate brany, ze user.db mohla zmenit hlavna
/// appka (P-03). Default: vsetky tabulky user.db oznaci ako zmenene, takze
/// kazdy `watch` (nastavenia, sada, questy) sa znova dotaze na disk.
/// V testoch override.
final Provider<void Function()> gateExternalChangesProvider =
    Provider<void Function()>((ref) {
      return () {
        final db = ref.read(userDbProvider);
        db.markTablesUpdated(db.allTables);
      };
    }, name: 'gateExternalChangesProvider');

/// Znova nacita nastavenia, ktore mohla zmenit hlavna appka (P-03).
///
/// Predhriaty engine brany bezi v inom izolate nez hlavna appka a ma
/// vlastne spojenie na user.db: drift o zapisoch appky nevie, jeho stream
/// dotazy (aj nove odbery, ktore drift berie z cache) vracaju hodnoty
/// z casu predhriatia, takze samotne `invalidate` (I-01) nestaci a tema
/// by ostala stara. Pri kazdej poziadavke preto drift dostane signal
/// o zmene vsetkych tabuliek a brana pocka, kym tema a jazyk
/// v provideroch zodpovedaju cerstvemu citaniu z disku, aby nezablikla
/// starym vzhladom. Ak to trva dlhsie nez [timeout], brana sa ukaze
/// a dobehne sama.
Future<void> reloadGateSettings(
  WidgetRef ref, {
  Duration timeout = const Duration(milliseconds: 500),
}) async {
  try {
    ref.read(gateExternalChangesProvider)();
    ref.invalidate(contentLanguageProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final theme = await settings.get(SettingsKeys.displayTheme);
    final locale = await settings.get(SettingsKeys.uiLocale);
    await Future.wait([
      _settled(ref, SettingsKeys.displayTheme, theme, timeout),
      _settled(ref, SettingsKeys.uiLocale, locale, timeout),
    ]);
  } on Object {
    // Chyba alebo timeout: brana ide dalej s tym, co sa nacita.
  }
}

/// Pocka (najviac [timeout]), kym `settingProvider(key)` ma hodnotu [want].
Future<void> _settled(
  WidgetRef ref,
  SettingKey<Object?> key,
  Object? want,
  Duration timeout,
) {
  final provider = settingProvider(key);
  if (ref.read(provider) case AsyncData(:final value) when value == want) {
    return Future<void>.value();
  }
  final done = Completer<void>();
  late final ProviderSubscription<AsyncValue<Object?>> sub;
  sub = ref.listenManual(provider, (_, next) {
    if (next case AsyncData(:final value) when value == want) {
      if (!done.isCompleted) done.complete();
    }
  });
  return done.future.timeout(timeout).whenComplete(sub.close);
}

/// Status a navigacna lista brany: priehladne, ikony kontrastne k
/// [brightness] temy.
SystemUiOverlayStyle gateSystemUiStyle(Brightness brightness) =>
    (brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light)
        .copyWith(
          statusBarColor: const Color(0x00000000),
          systemNavigationBarColor: const Color(0x00000000),
        );

/// Necinny engine: pokojna plocha ako nativny splash (ziadny obsah).
class _GateIdle extends StatelessWidget {
  const _GateIdle();

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}
