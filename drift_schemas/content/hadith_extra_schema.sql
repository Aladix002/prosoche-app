-- hadith_extra.db - KONTRAKT medzi pipeline prosoche-content a appkou (volitelny obsahovy balik, C-06/D-05).
-- schema_version: 1
--
-- Zmeny:
--  1 (C-06): prva verzia. Vysvetlivky (explanation) a poznamky (hints) HadeethEnc presunute
--            z content.db (hadith_text, schema_version 3) do samostatneho balika.
--
-- Pravidla:
--  * Obsah sa NEMENI, len distribuuje oddelene (docs/09: HadeethEnc podmienka 1, ziadna zmena ani
--    mazanie). explanation je bajtovo zhodne so zdrojom; hints je JSON pole zo zdroja (ako predtym
--    v content.db, validate porovnava s raw/ po json.loads).
--  * Stabilne ID: hadith_id = hadith.id v content.db (ID z HadeethEnc), lang ako hadith_text.lang.
--    Kazdy riadok ma zodpovedajuci riadok hadith_text(hadith_id, lang) v content.db s rovnakym source_id
--    (cez dve DB nie je FK; kontroluje validate.py, appka pri otvoreni balika).
--  * Balik patri k presne jednej content.db: meta.content_version == content.db meta.content_version
--    a sha256/size balika su v content.db meta (hadith_extra_sha256, hadith_extra_size) aj v manifeste.
--  * Riadok existuje len ak zdroj ma explanation alebo hints (inak oboje NULL v union).
--  * source: kopia riadkov HadeethEnc zo content.db (licencia, atribucia, verzia; podmienky 2-4
--    "keep the translation version information inside the document").

PRAGMA foreign_keys = ON;

-- Kluce: pack_id ('hadith_extra'), schema_version, content_version, base_schema_version
--        (schema_version content.db, ku ktorej balik patri), created_at, langs (JSON pole), row_count.
CREATE TABLE meta (
  key   TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

-- Rovnake stlpce a hodnoty ako source v content.db (len zdroje pouzite v baliku).
CREATE TABLE source (
  id                TEXT PRIMARY KEY NOT NULL,
  kind              TEXT NOT NULL CHECK (kind = 'hadith'),
  lang              TEXT NULL,
  name              TEXT NOT NULL,
  version           TEXT NOT NULL,
  license           TEXT NOT NULL,
  license_url       TEXT NULL,
  license_text      TEXT NOT NULL,
  attribution       TEXT NOT NULL,
  url               TEXT NOT NULL,
  commercial_status TEXT NOT NULL CHECK (commercial_status IN ('allowed', 'pending_confirmation')),
  sha256            TEXT NULL
);

CREATE TABLE hadith_explanation (
  hadith_id   INTEGER NOT NULL,                    -- = content.db hadith.id
  lang        TEXT NOT NULL,                       -- = content.db hadith_text.lang
  explanation TEXT NULL,                           -- HadeethEnc explanation, bajtovo zo zdroja
  hints       TEXT NULL,                           -- HadeethEnc hints, JSON pole
  source_id   TEXT NOT NULL REFERENCES source(id), -- = content.db hadith_text.source_id
  PRIMARY KEY (hadith_id, lang),
  CHECK (explanation IS NOT NULL OR hints IS NOT NULL)
);

PRAGMA user_version = 1;
