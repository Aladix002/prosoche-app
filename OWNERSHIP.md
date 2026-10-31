# Ownership

Kto smie menit co pocas paralelnej prace. Prefix = buduca uloha.

| Adresar / subor | Uloha | Poznamka |
|---|---|---|
| `lib/domain/*` (feed, quests, srs, streak, calendar, blocker) | D- | cisty Dart, bez `flutter`/`drift` (strazi `test/architecture_test.dart`) |
| `lib/domain/prayer` | PR- | casy modlitieb, adhan_dart |
| `lib/data/notifications` | PR- | planovanie notifikacii |
| `lib/data/db` | DB- | drift, migracie, testy migracii v `test/data/migrations` |
| `lib/data/content`, `lib/data/audio` | DB- | ak nie je urcene inak |
| `lib/data/blocker` | AND- | obal nad Pigeon API |
| `pigeons/` | AND- | definicie Pigeon |
| `android/app/src/main/kotlin/**/blocker`, `**/boot` | AND- | nativny blocker |
| `lib/ui/` (tokeny, temy, komponenty `Sk*`, galeria) | U-01 | design system |
| `lib/ui/i18n/`, `packages/sakina_lints/`, `test/helpers/golden/` | U-02 | RTL, fonty jazykov, golden harness |
| `lib/features/*/widgets/` | UI- | komponenty obrazoviek |
| `lib/features/<feature>/` (okrem `widgets/`) | feature uloha | obrazovky, notifiery |
| `test/<cesta>` | rovnaka uloha ako `lib/<cesta>` | test zrkadli lib |

## Spolocne subory (meni ich len integracia)

`pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `lib/bootstrap.dart`, `lib/app.dart`,
`lib/core/router/*`, `lib/l10n/app_*.arb` (generuje `tool/merge_arb.dart`), `tool/`,
`lib/core/result.dart`, `lib/core/failures.dart`,
`lib/core/logging/*`, `analysis_options.yaml`, `android/app/build.gradle.kts`,
`android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `.github/`.

Ostatni agenti tieto subory nemenia. Potrebne zmeny (novy balicek, routa, ARB kluc,
nova `AppFailure`, povolenie v manifeste) zapisu do handoff reportu a integracia ich prida.

Kazda uloha ma vlastny `lib/l10n/parts/<ID>_en.arb` a vlastny
`lib/features/<f>/<f>_routes.dart`. Kontrakty `lib/domain/common`,
`lib/domain/settings` a `lib/core/flags` meni len samostatna uloha.
Zavazna tabulka vlastnictva je v `../PLAN_VYVOJA.md` kap. 2.

## Pravidla

- Generovane subory (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/generated/`) sa commituju; po zmene spusti `dart run build_runner build -d`.
- Cas len cez `appClockProvider`, nikdy `DateTime.now()`.
- Logovanie len cez `AppLogger` (allowlist klucov, docs/06 C.7), ziadny `print`.
- Ocakavane chyby ako `Result`/`AppFailure`, bugy ako exception.
