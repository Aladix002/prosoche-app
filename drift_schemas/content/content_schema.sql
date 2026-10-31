-- content.db - KONTRAKT medzi pipeline prosoche-content a appkou (drift).
-- schema_version: 3
--
-- Zmeny:
--  3 (C-06): hadith_text BEZ stlpcov explanation a hints - presunute bez zmeny do volitelneho balika
--            dist/hadith_extra.db (schema/hadith_extra_schema.sql, tabulka hadith_explanation).
--            Nove meta kluce hadith_extra_sha256, hadith_extra_size, hadith_extra_schema_version.
--  2 (C-04): nova tabulka country (iso2, name EN, source_id) z GeoNames countryInfo;
--            city.country_code REFERENCES country(iso2); meta kluc dev_content.
--
-- Zaklad: TECHNICKY_PLAN kap. 5.1 + docs/02 cast D (D2-D5, D9, D11) + docs/09.
-- Zmena tohto suboru = zmena schema_version + drift schema v appke (07 ADR-03).
--
-- Pravidla:
--  * Texty zdrojov (Tanzil, QuranEnc, HadeethEnc) su ulozene BAJTOVO zhodne so zdrojom.
--    Ziadna Unicode normalizacia, ziadne orezanie. Appka text nemeni, len zobrazuje.
--  * Kazdy riadok obsahu ma source_id -> source.id (licencia, atribucia, verzia).
--  * Stabilne ID: ayah.id = surah*1000 + ayah (1:1 = 1001, 114:6 = 114006).
--    hadith.id = ID z HadeethEnc. Kuratovane ID su retazce z curated/ a nikdy sa nemenia.
--  * Jazyky: ISO 639-1 kody ('ar', 'en', 'id', 'ur', 'tr', ...). Aktivne jazyky su v meta 'langs'.
--  * Booleany su INTEGER 0/1. Datumy ISO 8601 TEXT. JSON polia su TEXT s platnym JSON.
--  * Rozsirenia oproti planu 5.1 su oznacene [EXT].

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------------ meta
-- Kluce: schema_version, content_version, created_at, langs (JSON pole), words_enabled ('0'/'1'),
--        uthmani_sha256 (hash celeho Uthmani textu bez basmal), bismillah_simple,
--        surah_hash_algo, hadith_grade_map_status,
--        dev_content ('1' = build obsahuje kuratovany obsah, ktory neprejde --release:
--        origin example/placeholder, chybajuci review; appka ho v produkcii nesmie prijat),
--        hadith_extra_sha256, hadith_extra_size (sha256 a velkost rozbalenej hadith_extra.db z toho
--        isteho buildu; appka nimi overi stiahnuty balik aj bez manifestu), hadith_extra_schema_version.
CREATE TABLE meta (
  key   TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

-- ------------------------------------------------------------------ source (02 D11, 09)
CREATE TABLE source (
  id                TEXT PRIMARY KEY NOT NULL,
  kind              TEXT NOT NULL CHECK (kind IN (
                      'quran_text', 'quran_text_search', 'quran_metadata',        -- quran_metadata [EXT]
                      'translation', 'word', 'hadith', 'dua', 'name', 'reflection',
                      'audio', 'font', 'city', 'curated')),                       -- curated [EXT]
  lang              TEXT NULL,
  name              TEXT NOT NULL,
  version           TEXT NOT NULL,
  license           TEXT NOT NULL,
  license_url       TEXT NULL,                                                     -- [EXT]
  license_text      TEXT NOT NULL,          -- pre Tanzil presny copyright blok zo suboru
  attribution       TEXT NOT NULL,          -- text na obrazovku Zdroje a licencie
  url               TEXT NOT NULL,          -- klikatelny link (Tanzil: povinny)
  commercial_status TEXT NOT NULL CHECK (commercial_status IN ('allowed', 'pending_confirmation')), -- [EXT]
  sha256            TEXT NULL               -- sha256 surovej stiahnutej kopie
);

-- ------------------------------------------------------------------ Koran
CREATE TABLE surah (
  id               INTEGER PRIMARY KEY NOT NULL CHECK (id BETWEEN 1 AND 114),
  name_ar          TEXT NOT NULL,
  name_translit    TEXT NOT NULL,
  revelation_place TEXT NOT NULL CHECK (revelation_place IN ('meccan', 'medinan')),
  revelation_order INTEGER NOT NULL,                                              -- [EXT]
  ayah_count       INTEGER NOT NULL,
  bismillah_pre    INTEGER NOT NULL CHECK (bismillah_pre IN (0, 1)),  -- 02 D4; 0 pre suru 1 a 9
  bismillah_uthmani TEXT NULL,   -- [EXT] presna basmala zo zdroja (atribut Tanzil XML); 95 a 97 maju inu vokalizaciu
  source_id        TEXT NOT NULL REFERENCES source(id)
);

CREATE TABLE surah_text (                                                         -- 02 D4
  surah_id     INTEGER NOT NULL REFERENCES surah(id),
  lang         TEXT NOT NULL,
  name_meaning TEXT NOT NULL,
  source_id    TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (surah_id, lang)
);

-- text_uthmani: Tanzil Uthmani 1.1, BEZ basmaly (Tanzil XML ju dava ako samostatny atribut; je v
-- surah.bismillah_uthmani a zobrazuje sa pred versom 1 ked bismillah_pre = 1; pri sure 1 je basmala vers 1:1).
-- text_simple: Tanzil Simple-clean (len pre vyhladavanie, neodvodzuje sa).
CREATE TABLE ayah (
  id               INTEGER PRIMARY KEY NOT NULL,          -- surah*1000 + number
  surah_id         INTEGER NOT NULL REFERENCES surah(id),
  number           INTEGER NOT NULL,
  text_uthmani     TEXT NOT NULL,
  text_simple      TEXT NOT NULL,
  juz              INTEGER NOT NULL CHECK (juz BETWEEN 1 AND 30),
  hizb_quarter     INTEGER NOT NULL CHECK (hizb_quarter BETWEEN 1 AND 240),
  page             INTEGER NOT NULL CHECK (page BETWEEN 1 AND 604),   -- Madina mushaf (Tanzil metadata)
  sajda            TEXT NULL CHECK (sajda IN ('recommended', 'obligatory')), -- 02 D3, Tanzil metadata
  source_id        TEXT NOT NULL REFERENCES source(id),   -- text_uthmani
  simple_source_id TEXT NOT NULL REFERENCES source(id),   -- text_simple [EXT]
  CHECK (id = surah_id * 1000 + number),
  UNIQUE (surah_id, number)
);

-- PK id je kvoli stabilnemu rowid pre FTS5 (external content). Logicky kluc je UNIQUE nizsie.
-- text a footnotes su bajtovo zo zdroja QuranEnc (footnotes sa nemazu, 09).
CREATE TABLE translation (
  id        INTEGER PRIMARY KEY NOT NULL,                                         -- [EXT]
  ayah_id   INTEGER NOT NULL REFERENCES ayah(id),
  lang      TEXT NOT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),
  text      TEXT NOT NULL,
  footnotes TEXT NULL,
  UNIQUE (ayah_id, lang, source_id)
);

-- ------------------------------------------------------------------ slova a lemy
-- PRAZDNE: bez licencne cisteho pribalitelneho zdroja (09 2.4). Funkcia za flagom words_enabled.
CREATE TABLE lemma (
  id        INTEGER PRIMARY KEY NOT NULL,
  text_ar   TEXT NOT NULL,
  translit  TEXT NULL,
  root      TEXT NULL,
  frequency INTEGER NULL,
  rank      INTEGER NULL,
  source_id TEXT NOT NULL REFERENCES source(id)                                   -- [EXT]
);

CREATE TABLE lemma_meaning (
  lemma_id  INTEGER NOT NULL REFERENCES lemma(id),
  lang      TEXT NOT NULL,
  meaning   TEXT NOT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (lemma_id, lang)
);

CREATE TABLE word (
  id         INTEGER PRIMARY KEY NOT NULL,
  ayah_id    INTEGER NOT NULL REFERENCES ayah(id),
  position   INTEGER NOT NULL,
  text_ar    TEXT NOT NULL,
  translit   TEXT NULL,
  lemma_id   INTEGER NULL REFERENCES lemma(id),
  char_start INTEGER NULL,
  char_end   INTEGER NULL,
  source_id  TEXT NOT NULL REFERENCES source(id),
  UNIQUE (ayah_id, position)
);

CREATE TABLE word_meaning (
  word_id   INTEGER NOT NULL REFERENCES word(id),
  lang      TEXT NOT NULL,
  meaning   TEXT NOT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (word_id, lang)
);

-- ------------------------------------------------------------------ hadisy (HadeethEnc)
-- V builde su len hadisy s prekladom vo vsetkych aktivnych jazykoch a so stupnom sahih/hasan
-- (mapovanie grade_ar -> grade v sources/hadith_grades.yaml, potvrdi reviewer).
CREATE TABLE hadith (
  id             INTEGER PRIMARY KEY NOT NULL,     -- ID z HadeethEnc
  collection     TEXT NOT NULL,                    -- zdrojove pole attribution_ar (napr. "رواه مسلم")
  number         TEXT NULL,                        -- HadeethEnc cislo v zbierke neposkytuje
  text_ar        TEXT NOT NULL,                    -- hadeeth_ar
  intro_ar       TEXT NULL,                        -- hadeeth_intro_ar [EXT]
  narrator_ar    TEXT NULL,                        -- HadeethEnc strukturovane neposkytuje
  grade          TEXT NOT NULL CHECK (grade IN ('sahih', 'hasan')),
  grade_ar       TEXT NOT NULL,                    -- povodny stupen zo zdroja [EXT]
  tags           TEXT NULL,                        -- JSON pole tagov z curated/selections/hadith.yaml; NULL = nie je vo vybere
  categories     TEXT NOT NULL,                    -- JSON pole ID kategorii HadeethEnc [EXT]
  source_id      TEXT NOT NULL REFERENCES source(id)
);

CREATE TABLE hadith_text (
  hadith_id   INTEGER NOT NULL REFERENCES hadith(id),
  lang        TEXT NOT NULL,
  title       TEXT NOT NULL,                       -- [EXT]
  text        TEXT NOT NULL,                       -- hadeeth
  intro       TEXT NULL,                           -- hadeeth_intro [EXT]
  narrator    TEXT NULL,
  attribution TEXT NOT NULL,                       -- zbierka, ako ju uvadza zdroj v danom jazyku [EXT]
  grade_label TEXT NOT NULL,                       -- stupen, ako ho uvadza zdroj v danom jazyku [EXT]
  -- explanation a hints zo zdroja su v baliku hadith_extra.db (v3, C-06), nemazu sa
  source_id   TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (hadith_id, lang)
);

-- ------------------------------------------------------------------ dua, 99 mien (kuratovane, zatial prazdne)
CREATE TABLE dua (
  id           TEXT PRIMARY KEY NOT NULL,
  category     TEXT NOT NULL,
  title        TEXT NULL,
  text_ar      TEXT NOT NULL,
  translit     TEXT NULL,
  repeat_count INTEGER NOT NULL DEFAULT 1,
  time_of_day  TEXT NOT NULL DEFAULT 'any' CHECK (time_of_day IN ('morning', 'evening', 'any')),
  source_ref   TEXT NOT NULL,                      -- napr. quran:2:201, hadeethenc:1234
  source_id    TEXT NOT NULL REFERENCES source(id),
  reviewed_by  TEXT NULL,
  reviewed_at  TEXT NULL
);

CREATE TABLE dua_text (
  dua_id    TEXT NOT NULL REFERENCES dua(id),
  lang      TEXT NOT NULL,
  text      TEXT NOT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (dua_id, lang)
);

CREATE TABLE name_of_allah (
  id          INTEGER PRIMARY KEY NOT NULL CHECK (id BETWEEN 1 AND 99),
  text_ar     TEXT NOT NULL,
  translit    TEXT NULL,
  ref_ayah_id INTEGER NULL REFERENCES ayah(id),
  source_id   TEXT NOT NULL REFERENCES source(id)
);

CREATE TABLE name_text (
  name_id    INTEGER NOT NULL REFERENCES name_of_allah(id),
  lang       TEXT NOT NULL,
  meaning    TEXT NOT NULL,
  short_note TEXT NULL,
  source_id  TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (name_id, lang)
);

-- ------------------------------------------------------------------ kuratovany obsah (curated/)
-- origin: human | example | placeholder. Release build odmietne example/placeholder a chybajuci reviewed_by.
CREATE TABLE reflection (
  id          TEXT PRIMARY KEY NOT NULL,
  version     INTEGER NOT NULL DEFAULT 1,
  status      TEXT NOT NULL CHECK (status IN ('draft', 'in_review', 'approved', 'retired')),
  origin      TEXT NOT NULL CHECK (origin IN ('human', 'example', 'placeholder')),
  tags        TEXT NOT NULL,                       -- JSON pole
  facets_json TEXT NULL,
  anchor_json TEXT NULL,                           -- ajat/hadis, ktory karta zobrazi z datasetu
  season      TEXT NULL,                           -- JSON pole id eventov
  reviewed_by TEXT NULL,
  reviewed_at TEXT NULL
);

CREATE TABLE reflection_text (
  reflection_id TEXT NOT NULL REFERENCES reflection(id),
  lang          TEXT NOT NULL,
  text          TEXT NOT NULL,
  question      TEXT NULL,                         -- [EXT] 03 4.3
  source_id     TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (reflection_id, lang)
);

CREATE TABLE quest_template (
  id            TEXT PRIMARY KEY NOT NULL,
  version       INTEGER NOT NULL DEFAULT 1,
  status        TEXT NOT NULL CHECK (status IN ('draft', 'in_review', 'approved', 'retired')),
  origin        TEXT NOT NULL CHECK (origin IN ('human', 'example', 'placeholder')),
  slot          TEXT NOT NULL CHECK (slot IN ('read', 'learn', 'act')),
  rule_json     TEXT NOT NULL,                     -- {"when", "completion", "params"} (03 4.2)
  tags          TEXT NOT NULL,
  facets_json   TEXT NULL,
  evidence_json TEXT NULL,
  weight        REAL NOT NULL DEFAULT 1.0,
  cooldown_days INTEGER NOT NULL DEFAULT 21,
  reviewed_by   TEXT NULL,
  reviewed_at   TEXT NULL
);

CREATE TABLE quest_text (
  quest_id  TEXT NOT NULL REFERENCES quest_template(id),
  lang      TEXT NOT NULL,
  title     TEXT NOT NULL,
  body      TEXT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),   -- 02 D5
  PRIMARY KEY (quest_id, lang)
);

CREATE TABLE islamic_event (
  id                   TEXT PRIMARY KEY NOT NULL,
  version              INTEGER NOT NULL DEFAULT 1,
  status               TEXT NOT NULL CHECK (status IN ('draft', 'in_review', 'approved', 'retired')),
  origin               TEXT NOT NULL CHECK (origin IN ('human', 'example', 'placeholder')),
  category             TEXT NOT NULL CHECK (category IN ('core', 'optional', 'info')),
  priority             INTEGER NOT NULL,
  rule_json            TEXT NOT NULL,              -- {"when", "phase", "merge", "effects"} gramatika 03 4.4
  quest_overrides_json TEXT NULL,                  -- effects.quests
  card_overrides_json  TEXT NULL,                  -- effects.cards
  tests_json           TEXT NULL,                  -- [EXT] znamy datum -> ocakavany stav
  reviewed_by          TEXT NULL,
  reviewed_at          TEXT NULL
);

CREATE TABLE islamic_event_text (                                                 -- 02 D2
  event_id  TEXT NOT NULL REFERENCES islamic_event(id),
  lang      TEXT NOT NULL,
  title     TEXT NOT NULL,
  body      TEXT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (event_id, lang)
);

CREATE TABLE intro_card (                                                         -- [EXT] curated/intro
  id          TEXT PRIMARY KEY NOT NULL,
  version     INTEGER NOT NULL DEFAULT 1,
  status      TEXT NOT NULL CHECK (status IN ('draft', 'in_review', 'approved', 'retired')),
  origin      TEXT NOT NULL CHECK (origin IN ('human', 'example', 'placeholder')),
  event_id    TEXT NULL REFERENCES islamic_event(id),
  reviewed_by TEXT NULL,
  reviewed_at TEXT NULL
);

CREATE TABLE intro_card_text (                                                    -- [EXT]
  intro_id  TEXT NOT NULL REFERENCES intro_card(id),
  lang      TEXT NOT NULL,
  title     TEXT NOT NULL,
  body      TEXT NULL,
  source_id TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (intro_id, lang)
);

-- ------------------------------------------------------------------ mesta a krajiny (02 D9)
-- GeoNames (CC BY 4.0, sources/geonames.yaml): cities15000 a countryInfo, len vyber stlpcov,
-- hodnoty bez zmeny. Atribucia je v source (geonames, geonames-countries).
CREATE TABLE country (                                                            -- [EXT] v2
  iso2      TEXT PRIMARY KEY NOT NULL,             -- ISO 3166-1 alpha-2 (GeoNames; XK = Kosovo)
  name      TEXT NOT NULL,                         -- anglicky nazov podla GeoNames
  source_id TEXT NOT NULL REFERENCES source(id)
);

CREATE TABLE city (
  id           INTEGER PRIMARY KEY NOT NULL,       -- geonameid
  name         TEXT NOT NULL,
  ascii_name   TEXT NOT NULL,
  country_code TEXT NOT NULL REFERENCES country(iso2),
  lat          REAL NOT NULL,
  lng          REAL NOT NULL,
  tz           TEXT NOT NULL,
  population   INTEGER NULL,
  source_id    TEXT NOT NULL REFERENCES source(id)
);

-- ------------------------------------------------------------------ FTS5 (external content)
-- Plni build (INSERT ... VALUES('rebuild')). Hladanie: SELECT rowid FROM ayah_fts WHERE ayah_fts MATCH ?
-- rowid = ayah.id resp. translation.id.
CREATE VIRTUAL TABLE ayah_fts USING fts5(
  text_simple, content='ayah', content_rowid='id'
);
CREATE VIRTUAL TABLE translation_fts USING fts5(
  text, content='translation', content_rowid='id', tokenize='unicode61 remove_diacritics 2'
);

PRAGMA user_version = 3;
