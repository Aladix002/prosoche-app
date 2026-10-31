@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/components/sk_button.dart';
import 'package:prosoche/ui/components/sk_card_surface.dart';
import 'package:prosoche/ui/components/sk_nav_bar.dart';
import 'package:prosoche/ui/gallery/gallery_samples.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../helpers/golden/golden.dart';

/// Goldeny komponentov U-01 cez harness U-02 (PLAN_VYVOJA 4.2 bod 3):
/// v1 len EN x svetla/tmava x textScale. Obsah su placeholdery
/// z [GallerySamples].
///
///   flutter test --update-goldens test/ui/goldens/components_locales_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  goldenAllLocales(
    'SkCardSurface locales',
    fileName: 'l10n_sk_card_surface',
    theme: theme,
    textScales: cardTextScales,
    builder: (context) => const SkCardSurface(
      eyebrow: 'SAMPLE 2.1',
      headerActions: [
        SkIconButton(
          icon: Icons.bookmark_border,
          tooltip: 'Save',
          onPressed: _noop,
        ),
      ],
      lead: Text(GallerySamples.lead),
      translation: Text(GallerySamples.translation),
      attribution: GallerySamples.attribution,
      footer: SkButton.secondary(label: 'Next card', onPressed: _noop),
    ),
  );

  goldenAllLocales(
    'SkNavBar locales',
    fileName: 'l10n_sk_nav_bar',
    theme: theme,
    builder: (context) => SkNavBar(
      selectedIndex: 1,
      onSelected: (_) {},
      destinations: [
        for (final (i, label) in const [
          'Today',
          'Library',
          'Practice',
          'Journey',
        ].indexed)
          SkNavDestination(
            icon: SkNavBar.tabIcons[i].$1,
            selectedIcon: SkNavBar.tabIcons[i].$2,
            label: label,
          ),
      ],
    ),
  );
}

void _noop() {}
