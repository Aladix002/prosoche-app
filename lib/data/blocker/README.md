Obal nad Pigeon API nativneho blockeru (B-01).

- `blocker_gateway.dart`: rozhranie BlockerGateway a typy (Result, docs/06 C.5).
- `pigeon_blocker_gateway.dart`: implementacia nad Pigeon, mapovanie chyb.
- `fake_blocker_gateway.dart`: pamatova verzia pre testy a galeriu.
- `blocker_api.pigeon.dart`: generovane z `pigeons/blocker_api.dart`, needitovat.
- `blocked_apps_repository.dart`: `blocked_app` v user.db (zdroj pravdy),
  kazda zmena posle zoznam do nativu (`setTargets`), lokalna statistika.
- `fake_blocked_apps_repository.dart`: pamatova verzia pre widget testy.
