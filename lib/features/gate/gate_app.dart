import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/app.dart' show prosocheAppTheme, skUiStringsOf;
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _app = widget.initialApp;
    _requests = ref.read(blockerGatewayProvider).gateRequests.listen((app) {
      // Aktivita je uz pripojena: targetSdk 36 edge-to-edge.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge).ignore();
      setState(() {
        _app = app;
        _request++;
      });
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
