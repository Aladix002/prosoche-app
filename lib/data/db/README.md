Drift databazy (D-01).

- `content_db.dart` + `content_tables.dart`: content.db, iba citanie. Zrkadlo
  kontraktu `drift_schemas/content/content_schema.sql` (kopia zo
  sakina-content); zhodu strazi `test/data/db/content_schema_test.dart`.
- `content_integrity.dart`: kontrola po otvoreni (schema, dev_content, 6236
  versov, sha256 Uthmani).
- `hadith_extra_db.dart` + `hadith_extra_tables.dart`: volitelny balik
  hadith_extra.db (vysvetlivky HadeethEnc, C-06), iba citanie. Kontrakt
  `drift_schemas/content/hadith_extra_schema.sql`, zhodu strazi
  `test/data/db/hadith_extra_schema_test.dart`.
- `hadith_extra_repository.dart`: `HadithExtraRepository`, `null` kym balik
  nie je stiahnuty (D-05) alebo nesedi k content.db.
- `user_db.dart` + `user_tables.dart`: user.db, WAL + busy_timeout.
- `daos/`: dotazy pre obrazovky. `migrations/`: kroky migracii user.db.
- Zmena schemy user.db: postup v `migrations/user_migrations.dart`.
- Testovaci content.db: `test/data/db/fixtures/content_fixture.dart`,
  hadith_extra.db: `test/data/db/fixtures/hadith_extra_fixture.dart`.
- Zmena kontraktu: skopirovat `sakina-content/schema/*.sql` do
  `drift_schemas/content/`, upravit tabulky a
  `dart run drift_dev schema dump lib/data/db/<db>.dart drift_schemas/<db>/`.
