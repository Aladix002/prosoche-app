# prosoche-app

Flutter appka Prosoche (Android, iOS): stoicka appka proti doomscrollingu.
Vznikla forkom appky Mursa (sakina-app, tag rc1.2, uloha S-01); islamske
casti su odstranene. Plan: `../PLAN.md`.

## Poziadavky

- Flutter 3.47.8 / Dart 3.13 (pin v `pubspec.yaml`, kontroluje `tool/check.sh`)
- Android SDK 36, Java 17+

## Spustenie

```
flutter pub get
dart run build_runner build -d
tool/bundle_content.sh            # content.db z ../prosoche-content
flutter run --flavor devLite
```

Bez pribalenej `content.db` appka ukaze chybu obsahu.

## Flavory

| Flavor | applicationId | Nazov | Brana |
|---|---|---|---|
| devLite | app.prosoche.dev | Prosoche Dev | nie |
| devFull | app.prosoche.dev | Prosoche Dev | ano (`android/app/src/full/`) |
| prodLite | app.prosoche | Prosoche | nie |
| prodFull | app.prosoche | Prosoche | ano |

Brana pred appkami je za flagom: `--dart-define=FEATURE_GATE=true` (len `full`).

## Testy a kontroly

```
./tool/check.sh     # vsetko ako CI (pokrytie lib/domain >= 90 %, lib/data >= 80 %)
tool/e2e.sh         # Patrol scenare na emulatore (patrol_test/)
```

## Preklady

Zatial len EN. Texty v `lib/l10n/parts/<ID>_en.arb`, zlucenie
`dart run tool/merge_arb.dart && flutter gen-l10n`.

## Struktura

`lib/core`, `lib/domain` (cisty Dart), `lib/data` (DB, siet, nativ),
`lib/features` (obrazovky). Taby: Today, Library, Practice, Journey
(Library a Practice su zatial placeholdery pre F-01).

Deep linky: `prosoche://today`, `prosoche://feed`, `prosoche://library`,
`prosoche://practice`, `prosoche://journey`, `prosoche://settings/notifications`,
`prosoche://gate?app=<package>` (len pri `FEATURE_GATE`).
