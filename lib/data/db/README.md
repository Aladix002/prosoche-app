Drift databazy (D-01).

- `content_db.dart` + `content_tables.dart`: content.db, iba citanie. Zrkadlo
  kontraktu `drift_schemas/content/content_schema.sql` (S-01: prechodny
  kontrakt, finalny dodava prosoche-content cez F-01); porovnanie
  s prosoche-content v `test/data/db/content_schema_test.dart` je vypnute.
- `content_integrity.dart`: kontrola po otvoreni (schema, dev_content,
  aspon jeden citat).
- `user_db.dart` + `user_tables.dart`: user.db, WAL + busy_timeout.
- `daos/`: dotazy pre obrazovky. `migrations/`: kroky migracii user.db.
- Zmena schemy user.db: postup v `migrations/user_migrations.dart`.
- Testovaci content.db: `test/data/db/fixtures/content_fixture.dart`.
- Zmena kontraktu: skopirovat `prosoche-content/schema/*.sql` do
  `drift_schemas/content/`, upravit tabulky a
  `dart run drift_dev schema dump lib/data/db/<db>.dart drift_schemas/<db>/`.
