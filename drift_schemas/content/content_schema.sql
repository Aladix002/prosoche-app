-- content.db - PRECHODNY kontrakt appky Prosoche (S-01).
-- schema_version: 1
--
-- Minimalna schema, aby feed, denna sada a questy bezali nad kartami
-- `quote`. Finalny kontrakt pripravuje C-01 v prosoche-content
-- (docs/CONTENT_CONTRACT.md, schema/content_schema.sql); F-01 ho sem skopiruje
-- a upravi content_tables.dart, ContentCatalog a CardContentRepository.
--
-- Pravidla:
--  * Texty zdrojov su ulozene bajtovo zhodne so zdrojom (PD preklad).
--  * Kazdy riadok obsahu ma source_id -> source.id (licencia, atribucia, verzia).
--  * Stabilne ID su retazce [a-z0-9_]{1,64}; card_id = '<typ>:<id>'.
--  * Booleany su INTEGER 0/1. Datumy ISO 8601 TEXT. JSON polia su TEXT s platnym JSON.

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------------ meta
-- Kluce: schema_version, content_version, created_at, langs (JSON pole),
--        dev_content ('1' = build obsahuje testovaci/placeholder obsah;
--        appka ho v produkcii nesmie prijat).
CREATE TABLE meta (
  key   TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

-- ------------------------------------------------------------------ source
CREATE TABLE source (
  id                TEXT PRIMARY KEY NOT NULL,
  kind              TEXT NOT NULL CHECK (kind IN ('text', 'translation', 'font', 'curated')),
  lang              TEXT NULL,
  name              TEXT NOT NULL,
  version           TEXT NOT NULL,
  license           TEXT NOT NULL,
  license_url       TEXT NULL,
  license_text      TEXT NOT NULL,
  attribution       TEXT NOT NULL,          -- text na obrazovku Zdroje a licencie
  url               TEXT NOT NULL,
  commercial_status TEXT NOT NULL CHECK (commercial_status IN ('allowed', 'pending_confirmation')),
  sha256            TEXT NULL               -- sha256 surovej stiahnutej kopie
);

-- ------------------------------------------------------------------ citaty
CREATE TABLE quote (
  id          TEXT PRIMARY KEY NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('draft', 'in_review', 'approved', 'retired')),
  origin      TEXT NOT NULL CHECK (origin IN ('source', 'human', 'example', 'placeholder')),
  text        TEXT NOT NULL,
  author      TEXT NOT NULL,                     -- napr. 'Marcus Aurelius'
  work        TEXT NOT NULL,                     -- napr. 'Meditations'
  ref         TEXT NULL,                         -- napr. '2.1'
  tags        TEXT NOT NULL,                     -- JSON pole
  time_of_day TEXT NOT NULL DEFAULT 'any' CHECK (time_of_day IN ('morning', 'day', 'evening', 'night', 'any')),
  weight      REAL NOT NULL DEFAULT 1.0,
  source_id   TEXT NOT NULL REFERENCES source(id)
);

-- ------------------------------------------------------------------ questy
CREATE TABLE quest_template (
  id            TEXT PRIMARY KEY NOT NULL,
  version       INTEGER NOT NULL DEFAULT 1,
  status        TEXT NOT NULL CHECK (status IN ('draft', 'in_review', 'approved', 'retired')),
  origin        TEXT NOT NULL CHECK (origin IN ('human', 'example', 'placeholder')),
  slot          TEXT NOT NULL CHECK (slot IN ('read', 'learn', 'act')),
  rule_json     TEXT NOT NULL,                     -- {"count": {...}} (QuestRule)
  tags          TEXT NOT NULL,
  facets_json   TEXT NULL,
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
  source_id TEXT NOT NULL REFERENCES source(id),
  PRIMARY KEY (quest_id, lang)
);

PRAGMA user_version = 1;
