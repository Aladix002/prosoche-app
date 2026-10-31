# prosoche-app

Flutter appka Prosoche (pracovny nazov, Android, iOS). Interny kodovy nazov ostava
`prosoche` (Dart package, triedy `Prosoche*`, repozitare).
Plan: `../TECHNICKY_PLAN.md`, rozhodnutia: `../docs/`.

## Poziadavky

- Flutter 3.47.8 / Dart 3.13 (pin v `pubspec.yaml` `environment.flutter`, kontroluje `tool/check.sh`)
- Android SDK 36, Java 17+

## Spustenie

```
flutter pub get
dart run build_runner build -d
flutter run --flavor devLite
```

## Flavory

Dve dimenzie: `env` (dev, prod) x `edition` (lite, full).

| Flavor | applicationId | Nazov | Brana |
|---|---|---|---|
| devLite | app.prosoche.dev | Prosoche Dev | nie |
| devFull | app.prosoche.dev | Prosoche Dev | ano (`android/app/src/full/`) |
| prodLite | app.prosoche | Prosoche | nie |
| prodFull | app.prosoche | Prosoche | ano |

`lite` je produkcia B bez FGS, usage access a overlay povoleni.
Entrypoint je jeden (`lib/main.dart`), flavor sa cita z `--flavor` (`appFlavor`).

```
flutter build apk --debug --flavor devLite
flutter build apk --release --flavor prodLite
./tool/check_manifest.sh --build      # lite manifest bez povoleni brany
```

Nedokoncene funkcie su za flagmi (`lib/core/flags/feature_flags.dart`), predvolene vypnute:

```
flutter run --flavor devFull --dart-define=FEATURE_GATE=true --dart-define=FEATURE_WORDS=true
```

Flagy: `FEATURE_GATE` (len `full`), `FEATURE_WORDS`, `FEATURE_AUDIO`, `FEATURE_RAMADAN_LIGHT`.

iOS flavory (schemy v Xcode) zatial nie su, nastavuje sa na Macu.

## Testy a kontroly

```
./tool/check.sh                 # vsetko ako CI
flutter test test/domain/common # len jedna oblast
```

`check.sh`: pub get, merge ARB + gen-l10n + build_runner (bez diffu), format,
analyze `--fatal-infos`, zakazane vzory, testy s pokrytim
(`lib/domain` >= 90 %, `lib/data` >= 80 %).

`test/architecture_test.dart` strazi, ze `lib/domain` neimportuje Flutter ani drift.

## E2E (Patrol)

Scenare v `patrol_test/` (mimo `flutter test` a `check.sh`) bezia na
emulatore alebo zariadeni proti `devLite` s realnou `content.db`:

```
dart pub global activate patrol_cli 4.8.0   # raz, PATH += ~/.pub-cache/bin
tool/e2e.sh                                 # vsetky scenare (~10 min)
tool/e2e.sh -t patrol_test/s3_quran_search_test.dart
```

Skript pribali obsah (`tool/bundle_content.sh`, `-c <prosoche-content>`), appku
pred behom odinstaluje a kazdy test spusti v novom procese (Android Test
Orchestrator). Cas je fixny (11. 11. 2026 09:00, `support/app_harness.dart`),
`--dart-define=E2E_REAL_TIME=true` = realny cas. `s6a` a `s6b` (restart
uprostred feedu) su zavisle, spustaju sa spolu.

## Preklady (ARB)

Kazda uloha pise EN texty do `lib/l10n/parts/<ID>_en.arb` (napr. `F-02_en.arb`).
`dart run tool/merge_arb.dart` ich zluci do `lib/l10n/app_en.arb`; rovnako pre
dalsie jazyky (`<ID>_ar.arb` -> `app_ar.arb`). `app_*.arb` sa needituju rucne.

## Struktura

`lib/core` (spolocne), `lib/domain` (cisty Dart, kontrakty v `common/` a `settings/`),
`lib/data` (DB, siet, nativ), `lib/features` (obrazovky, routy v `<f>_routes.dart`).
Kto co meni: `../PLAN_VYVOJA.md` kap. 2.

Deep linky (docs/02 C4): `prosoche://today`, `prosoche://feed`, `prosoche://quran/2/255`,
`prosoche://prayer/qibla`, `prosoche://calendar`, `prosoche://settings/notifications`,
`prosoche://gate?app=<package>` (len pri `FEATURE_GATE`).
