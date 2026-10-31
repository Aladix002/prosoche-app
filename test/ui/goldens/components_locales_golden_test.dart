@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/components/sk_arabic_text.dart';
import 'package:prosoche/ui/components/sk_button.dart';
import 'package:prosoche/ui/components/sk_card_surface.dart';
import 'package:prosoche/ui/components/sk_nav_bar.dart';
import 'package:prosoche/ui/components/sk_prayer_row.dart';
import 'package:prosoche/ui/gallery/gallery_samples.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../helpers/golden/golden.dart';

/// Goldeny komponentov U-01 cez harness U-02 (PLAN_VYVOJA 4.2 bod 3):
/// EN, AR (RTL), UR (RTL, Nastaliq), BN x svetla/tmava x textScale; ID
/// a TR smoke. UI texty su pseudo-lokalizovane ([PseudoLocale]), arabsky
/// obsah su neutralne ukazky z [GallerySamples] cez `SkArabicText`.
///
///   flutter test --update-goldens test/ui/goldens/components_locales_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  String pseudo(BuildContext context, String en) =>
      PseudoLocale.localize(en, Localizations.localeOf(context));

  String time(BuildContext context, int h, int m) =>
      ProsocheFormats(Localizations.localeOf(context))
          .time(DateTime(2026, 3, 7, h, m));

  goldenAllLocales(
    'SkArabicText locales',
    fileName: 'l10n_sk_arabic_text',
    theme: theme,
    textScales: cardTextScales,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SkArabicText.quran(
          GallerySamples.segments,
          textSimple: GallerySamples.sentenceSimple,
          tajwid: true,
        ),
        SkArabicText.text(
          GallerySamples.words,
          semanticsText: GallerySamples.wordsSimple,
          textAlign: TextAlign.start,
        ),
        Text(pseudo(context, 'Sample translation below the Arabic text')),
      ],
    ),
  );

  goldenAllLocales(
    'SkCardSurface locales',
    fileName: 'l10n_sk_card_surface',
    theme: theme,
    textScales: cardTextScales,
    builder: (context) => SkCardSurface(
      eyebrow: pseudo(context, 'SAMPLE 1:12'),
      headerActions: const [
        SkIconButton(
          icon: Icons.bookmark_border,
          tooltip: 'Save',
          onPressed: _noop,
        ),
      ],
      arabic: const SkArabicText.quran([
        SkArabicSegment(GallerySamples.sentence),
      ], textSimple: GallerySamples.sentenceSimple),
      translation: Text(PseudoLocale.sentence(Localizations.localeOf(context))),
      attribution: pseudo(context, 'Translation: sample source'),
      footer: SkButton.secondary(
        label: pseudo(context, 'Next card'),
        onPressed: _noop,
      ),
    ),
  );

  goldenAllLocales(
    'SkPrayerRow locales',
    fileName: 'l10n_sk_prayer_row',
    theme: theme,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkPrayerRow(
          name: pseudo(context, 'Dhuhr'),
          time: time(context, 11, 58),
          state: SkPrayerRowState.passed,
          status: SkPrayerStatus.onTime,
        ),
        SkPrayerRow(
          name: pseudo(context, 'Asr'),
          time: time(context, 14, 21),
          state: SkPrayerRowState.next,
          relative: pseudo(context, 'in 1 h 12 min'),
          onTrackerTap: _noop,
        ),
        SkPrayerRow(
          name: pseudo(context, 'Isha'),
          time: time(context, 18, 15),
          estimated: true,
          notificationOff: true,
          adjustedLabel: '+2',
        ),
      ],
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
          'Quran',
          'Prayer',
          'Journey',
        ].indexed)
          SkNavDestination(
            icon: SkNavBar.tabIcons[i].$1,
            selectedIcon: SkNavBar.tabIcons[i].$2,
            label: pseudo(context, label),
          ),
      ],
    ),
  );
}

void _noop() {}
