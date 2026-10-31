import 'package:flutter/widgets.dart';
import 'package:sakina/core/l10n/generated/app_localizations.dart';

export 'package:sakina/core/l10n/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
