@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/quran/quran_screen.dart';
import 'package:prosoche/features/quran/reader/quran_reader_screen.dart';
import 'package:prosoche/features/quran/search/quran_search_screen.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../../fakes/fake_repositories.dart';
import '../../../helpers/golden/golden.dart';
import '../quran_test_helpers.dart';

/// Goldeny obrazoviek Koranu cez harness U-02: EN, AR (RTL, bez prekladu),
/// UR (Nastaliq), BN (EN fallback so stitkom) x svetla/tmava x 1.0/2.0;
/// ID a TR smoke. Obsah je placeholder z fakes; goldeny so skutocnym
/// textom su v `full_db/quran_full_db_golden_test.dart`.
///
///   flutter test --update-goldens test/features/quran/goldens
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  const screen = BoxConstraints.tightFor(width: 360, height: 640);

  goldenAllLocales(
    'Quran list',
    fileName: 'quran_list',
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      setup: (f) async {
        f.quran.position = AyahId(2, 143);
        await f.settings.set(SettingsKeys.readerLastAyahId, 36012);
      },
      quran: TestQuranRepository(surahCount: 6)..readCounts = {2: 143, 3: 20},
      child: const QuranScreen(),
    ),
  );

  goldenAllLocales(
    'Quran reader 2:255',
    fileName: 'quran_reader_2_255',
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      quran: TestQuranRepository(
        sajda: {AyahId(2, 256)},
        footnotes: {AyahId(2, 255): '[PLACEHOLDER footnote]'},
      ),
      child: const QuranReaderScreen(surah: 2, ayahId: 2255),
    ),
  );

  goldenAllLocales(
    'Quran reader surah 1',
    fileName: 'quran_reader_1',
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      quran: TestQuranRepository(),
      child: const QuranReaderScreen(surah: 1, mode: ReaderMode.khatm),
    ),
  );

  // BF-02: znacky poznamok prekladatela ako horny index (bez rozbalovacky)
  // a atribucia QuranEnc s verziou raz.
  goldenAllLocales(
    'Quran reader translator notes',
    fileName: 'quran_reader_notes',
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      quran: TestQuranRepository(
        translations: {
          AyahId(1, 1): '(1) [PLACEHOLDER] one,[2] [PLACEHOLDER] two.[3]',
        },
        footnotes: {AyahId(1, 1): '[2]- [PLACEHOLDER]\n[3]- [PLACEHOLDER]'},
        sources: const [
          TranslationSource(
            id: 'fake-en',
            lang: 'en',
            name: 'Fake translation',
            version: '1.1.2',
            attribution: '[PLACEHOLDER], via QuranEnc.com, version 1.1.2',
            license: 'test-only',
          ),
        ],
      ),
      child: const QuranReaderScreen(surah: 1, mode: ReaderMode.khatm),
    ),
  );

  goldenAllLocales(
    'Quran reader not found',
    fileName: 'quran_reader_not_found',
    locales: const [Locale('en'), Locale('ar')],
    textScales: const [1.0],
    brightness: const [Brightness.light],
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      quran: TestQuranRepository(),
      child: const QuranReaderScreen(surah: 2, ayahId: 3001),
    ),
  );

  goldenAllLocales(
    'Quran search',
    fileName: 'quran_search',
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      quran: TestQuranRepository(
        hits: const [
          SearchHit(
            ayahId: 2255,
            snippet:
                '[PLACEHOLDER] ${SearchHit.matchStart}placeholder'
                '${SearchHit.matchEnd} snippet',
          ),
          SearchHit(ayahId: 1002, snippet: '[PLACEHOLDER snippet]'),
        ],
      ),
      child: const QuranSearchScreen(
        initialQuery: 'placeholder',
        debounce: Duration.zero,
      ),
    ),
  );

  goldenAllLocales(
    'Quran search empty',
    fileName: 'quran_search_empty',
    locales: const [Locale('en'), Locale('ar')],
    brightness: const [Brightness.light],
    theme: theme,
    constraints: screen,
    builder: (_) => _Scope(
      quran: TestQuranRepository(),
      child: const QuranSearchScreen(initialQuery: 'none'),
    ),
  );
}

/// ProviderScope s fakes v jazyku scenara (vytvori sa raz).
class _Scope extends StatefulWidget {
  const _Scope({required this.quran, required this.child, this.setup});

  final TestQuranRepository quran;
  final Future<void> Function(FakeRepositories fakes)? setup;
  final Widget child;

  @override
  State<_Scope> createState() => _ScopeState();
}

class _ScopeState extends State<_Scope> {
  late final FakeRepositories _fakes = FakeRepositories(quran: widget.quran);
  late final Future<void> _ready = widget.setup?.call(_fakes) ?? Future.value();
  late final String _lang = Localizations.localeOf(context).languageCode;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _ready,
    builder: (context, snap) => snap.connectionState != ConnectionState.done
        ? const SizedBox.shrink()
        : ProviderScope(
            overrides: _fakes.overrides(
              now: DateTime(2026, 10, 29, 9),
              deviceLanguage: _lang,
            ),
            retry: (_, _) => null,
            child: widget.child,
          ),
  );
}
