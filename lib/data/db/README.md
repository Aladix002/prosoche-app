Drift databazy.

- `content_db.dart` + `content_tables.dart`: content.db v1, iba citanie. Zrkadlo
  kontraktu `drift_schemas/content/content_schema.sql` (kopia
  `prosoche-content/schema/content_schema.sql`); zhodu s prosoche-content
  strazi `test/data/db/content_schema_test.dart`. FTS5 `section_fts` cez
  `LibraryDao.search`.
- `content_integrity.dart`: kontrola po otvoreni (schema_version,
  dev_content, sekcie a karty, sha256 sekcii, sections_sha256).
- `user_db.dart` + `user_tables.dart`: user.db v2 (F-01: journal_entry,
  practice_log, reading_position, section_bookmark), WAL + busy_timeout.
- `daos/`: dotazy pre obrazovky. `migrations/`: kroky migracii user.db.
- Zmena schemy user.db: postup v `migrations/user_migrations.dart`.
- Testovaci content.db: `test/data/db/fixtures/content_fixture.dart`.
- Zmena kontraktu: skopirovat `prosoche-content/schema/*.sql` do
  `drift_schemas/content/`, upravit tabulky a
  `dart run drift_dev schema dump lib/data/db/<db>.dart drift_schemas/<db>/`.
