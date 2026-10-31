import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sakina/ui/tokens/sk_fonts.dart';

/// Zaregistruje OFL licencie pribalenych fontov do `LicenseRegistry`
/// (docs/01 2.3.1, "Sources & licenses"). Volat raz pri starte appky.
void registerSakinaFontLicenses({AssetBundle? bundle}) {
  final assets = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: dir) in SkFonts.licenseDirs.entries) {
      final text = await assets.loadString('assets/fonts/$dir/OFL.txt');
      yield LicenseEntryWithLineBreaks(['font: $name'], text);
    }
  });
}
