import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/generated/app_localizations.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/providers.dart';
import 'package:prosoche/features/home_widget/home_widget_sync.dart';
import 'package:prosoche/features/shell/app_locale.dart';
import 'package:prosoche/ui/i18n/prosoche_locales.dart';

/// Widget na ploche (W-01): pri starte appky, pri navrate do popredia, po
/// polnoci (zmena `localDateProvider`) a po zmene obsahu posle nativnemu
/// widgetu citaty dna na [widgetScheduleDays] dni dopredu.
///
/// Vrati funkciu, ktora synchronizaciu zastavi (testy).
VoidCallback startHomeWidget(
  ProviderContainer container, {
  HomeWidgetChannel channel = const HomeWidgetChannel(),
  bool listenLifecycle = true,
}) {
  final sync = HomeWidgetSyncer(container, channel);
  final subs = [
    container.listen(localDateProvider, (_, _) => sync.run()),
    container.listen(contentCatalogProvider, (_, _) => sync.run()),
    container.listen(appLocaleProvider, (_, _) => sync.run()),
  ];
  final lifecycle = listenLifecycle
      ? AppLifecycleListener(onResume: sync.run)
      : null;
  sync.run();
  return () {
    for (final s in subs) {
      s.close();
    }
    lifecycle?.dispose();
  };
}

/// Jedna synchronizacia naraz; poziadavka pocas behu sa spusti po nom.
class HomeWidgetSyncer {
  HomeWidgetSyncer(this._container, this._channel);

  final ProviderContainer _container;
  final HomeWidgetChannel _channel;
  Future<void>? _running;
  bool _again = false;

  /// Posledny vysledok (true = widget dostal data). Pre testy.
  bool? lastResult;

  void run() {
    if (_running != null) {
      _again = true;
      return;
    }
    _running = _loop().whenComplete(() => _running = null);
  }

  /// Dokonci prebiehajucu synchronizaciu (testy).
  Future<void> get idle => _running ?? Future.value();

  Future<void> _loop() async {
    do {
      _again = false;
      lastResult = await _once();
    } while (_again);
  }

  Future<bool> _once() async {
    final c = _container;
    try {
      final db = await c.read(contentDbProvider.future);
      final locale =
          c.read(appLocaleProvider) ??
          ProsocheLocales.resolve(
            deviceLocales: PlatformDispatcher.instance.locales,
          );
      final payload = await buildWidgetPayload(
        db: db,
        today: c.read(localDateProvider),
        l10n: lookupAppLocalizations(_supported(locale)),
        disabled: {for (final id in c.read(disabledCardIdsProvider)) '$id'},
      );
      if (payload == null) return false;
      return await _channel.update(payload);
    } on Object catch (e, st) {
      c
          .read(appLoggerProvider)
          .error('widget', 'home widget sync failed', error: e, stack: st);
      return false;
    }
  }

  static Locale _supported(Locale l) =>
      AppLocalizations.supportedLocales.any(
        (s) => s.languageCode == l.languageCode,
      )
      ? Locale(l.languageCode)
      : const Locale('en');
}
