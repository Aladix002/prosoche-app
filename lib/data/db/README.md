Drift databazy.

- `content_db.dart` + `content_tables.dart`: content.db v1, iba citanie. Zrkadlo
  kontraktu `drift_schemas/content/content_schema.sql` (kopia
  `prosoche-content/schema/content_schema.sql`); zhodu s prosoche-content
  strazi `test/data/db/content_schema_test.dart`. FTS5 `section_fts` cez
  `LibraryDao.search`.
- `content_integrity.dart`: kontrola po otvoreni (schema_version,
  dev_content, sekcie a karty, sha256 sekcii, sections_sha256).
- `user_db.dart` + `user_tables.dart`: user.db v4 (F-01: practice_log,
  reading_position, section_bookmark; G-01: `gate_session.intent`,
  `blocked_app.practice_first`), WAL + busy_timeout. Zalohuje sa
  (Android Auto Backup, len sifrovane).
- `journal_db.dart` + `journal_tables.dart`: journal.db v1 (C-02), lokalny
  dennik `journal_entry`. Samostatny subor, Android zaloha ho nikdy nezahrna
  (`android/app/src/main/res/xml*/`, `tool/check_manifest.sh --rules`).
  Migracia user.db v2 -> v3 presunie stary dennik sem a tabulku v user.db
  zmaze.
- `daos/`: dotazy pre obrazovky. `migrations/`: kroky migracii user.db.
- Zmena schemy user.db: postup v `migrations/user_migrations.dart`;
  journal.db: `drift_schemas/journal_db/`.
- Testovaci content.db: `test/data/db/fixtures/content_fixture.dart`.
- Zmena kontraktu: skopirovat `prosoche-content/schema/*.sql` do
  `drift_schemas/content/`, upravit tabulky a
  `dart run drift_dev schema dump lib/data/db/<db>.dart drift_schemas/<db>/`.
