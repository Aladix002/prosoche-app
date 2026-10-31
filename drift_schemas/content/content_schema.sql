-- content.db - KONTRAKT medzi pipeline prosoche-content a appkou Prosoche.
-- schema_version: 1   (PRAGMA user_version = 1, meta.schema_version = '1')
--
-- Popis pre appku: docs/CONTENT_CONTRACT.md. Zmena tohto suboru = zmena schema_version
-- + zmena drift schemy v appke.
--
-- Pravidla:
--  * Texty diel su z volnych (public domain) prekladov, viz docs/LICENSES.md.
--    Text sekcie sa nemeni okrem zdokumentovanej normalizacie (docs/CONTENT_CONTRACT.md, kap. 4).
--  * Odstavce v section.text su oddelene presne "\n\n". Ziadne ine \n v texte nie su.
--  * card.text typu quote a passage je VZDY presny podretazec section.text sekcie card.section_key.
--  * Stabilne kluce: author.id, work.id, section.key, card.id sa medzi verziami nemenia
--    (zalozky, pozicia citania, historia kariet v appke sa na ne viazu).
--    section.id (INTEGER) je len rowid pre FTS5 a poradie; NEPOUZIVAT ako trvaly kluc v appke.
--  * Booleany su INTEGER 0/1. JSON polia su TEXT s platnym JSON.

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------------ meta
-- Kluce: schema_version, content_version, created_at, langs (JSON pole, v1 '["en"]'),
--        dev_content ('1' = obsahuje karty so status 'draft'; produkcna appka taky obsah neprijme),
--        normalization ('ws1'), section_hash_algo ('sha256-utf8'),
--        sections_sha256 (sha256 zo zretazenych "key\tsha256\n" vsetkych sekcii v poradi section.id),
--        section_count, card_count.
CREATE TABLE meta (
  key   TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

-- ------------------------------------------------------------------ source
-- Jeden zaznam na stiahnuty zdroj textu + jeden pre vlastne (kuratovane) texty.
CREATE TABLE source (
  id               TEXT PRIMARY KEY NOT NULL,
  kind             TEXT NOT NULL CHECK (kind IN ('text', 'curated')),
  name             TEXT NOT NULL,          -- nazov vydania (napr. "The Thoughts of the Emperor Marcus Aurelius Antoninus")
  translator       TEXT NULL,
  translator_died  INTEGER NULL,           -- rok umrtia prekladatela (EU: +70 rokov)
  edition_year     INTEGER NULL,           -- rok vydania prekladu
  version          TEXT NOT NULL,          -- verzia zdroja (napr. sha256 prefix surovej kopie)
  license          TEXT NOT NULL,          -- 'public-domain' | 'proprietary-own' (vlastne texty)
  license_note     TEXT NOT NULL,          -- kratke odovodnenie pre obrazovku Zdroje a licencie
  attribution      TEXT NOT NULL,          -- text na obrazovku Zdroje a licencie
  url              TEXT NULL,              -- volitelny odkaz (NULL pri Project Gutenberg, viz kontrakt kap. 5)
  sha256           TEXT NULL               -- sha256 surovej stiahnutej kopie
);

-- ------------------------------------------------------------------ author
CREATE TABLE author (
  id          TEXT PRIMARY KEY NOT NULL,   -- 'marcus-aurelius', 'epictetus', 'seneca'
  name        TEXT NOT NULL,               -- 'Marcus Aurelius'
  full_name   TEXT NOT NULL,
  lifespan    TEXT NOT NULL,               -- 'AD 121-180' (zobrazovany text)
  ord         INTEGER NOT NULL
);

-- ------------------------------------------------------------------ work (dielo)
CREATE TABLE work (
  id             TEXT PRIMARY KEY NOT NULL,   -- 'meditations', 'enchiridion', 'discourses', 'on-anger', ...
  author_id      TEXT NOT NULL REFERENCES author(id),
  source_id      TEXT NOT NULL REFERENCES source(id),
  title          TEXT NOT NULL,               -- 'Meditations'
  original_title TEXT NOT NULL,               -- 'Ta eis heauton', 'De Ira'
  translator     TEXT NOT NULL,
  short_ref      TEXT NOT NULL,               -- prefix referencie na karte: 'Meditations', 'On Anger'
  book_count     INTEGER NOT NULL,            -- 0 = dielo nema knihy (Enchiridion, vacsina Seneku)
  section_count  INTEGER NOT NULL,
  ord            INTEGER NOT NULL             -- poradie v Library
);

-- ------------------------------------------------------------------ book (kniha)
-- Len pre diela s book_count > 0.
CREATE TABLE book (
  work_id        TEXT NOT NULL REFERENCES work(id),
  number         INTEGER NOT NULL CHECK (number >= 1),
  title          TEXT NOT NULL,               -- 'Book 2'
  section_count  INTEGER NOT NULL,
  PRIMARY KEY (work_id, number)
);

-- ------------------------------------------------------------------ section (sekcia)
-- Meditations: jedna "myslienka" (2.1). Enchiridion: kapitola (1). Discourses: kapitola (1.1).
-- Seneca: kapitola dialogu (On Anger 3.36, On the Shortness of Life 1).
CREATE TABLE section (
  id          INTEGER PRIMARY KEY NOT NULL,   -- rowid pre FTS5, poradie v ramci celej db
  key         TEXT NOT NULL UNIQUE,           -- stabilny kluc '<work>.<book>.<n>' alebo '<work>.<n>'
  work_id     TEXT NOT NULL REFERENCES work(id),
  book        INTEGER NULL,                   -- NULL ak dielo nema knihy
  number      INTEGER NOT NULL CHECK (number >= 1),
  ref         TEXT NOT NULL,                  -- '2.1' / '1' (bez nazvu diela)
  title       TEXT NULL,                      -- nadpis kapitoly, ak ho zdroj ma (Discourses)
  text        TEXT NOT NULL,                  -- odstavce oddelene "\n\n"
  char_count  INTEGER NOT NULL,
  sha256      TEXT NOT NULL,                  -- sha256(utf8(text))
  FOREIGN KEY (work_id, book) REFERENCES book(work_id, number)
);
CREATE INDEX section_work ON section(work_id, book, number);

-- Fulltext pre Library (external content; appka ho len cita).
CREATE VIRTUAL TABLE section_fts USING fts5(
  title, text,
  content='section', content_rowid='id',
  tokenize='porter unicode61 remove_diacritics 2'
);

-- ------------------------------------------------------------------ card (karta)
CREATE TABLE card (
  id           TEXT PRIMARY KEY NOT NULL,       -- '<type>:<slug>', napr. 'quote:meditations.2.1.a'
  type         TEXT NOT NULL CHECK (type IN ('quote', 'passage', 'practice', 'prompt', 'concept', 'author')),
  author_id    TEXT NULL REFERENCES author(id), -- quote/passage/author: povinne
  work_id      TEXT NULL REFERENCES work(id),   -- quote/passage: povinne
  section_key  TEXT NULL REFERENCES section(key), -- quote/passage: zdroj textu; inak volitelna suvisiaca sekcia
  ref          TEXT NULL,                       -- zobrazovana referencia: 'Meditations 2.1'
  title        TEXT NULL,                       -- practice/concept/author: nadpis; quote/passage/prompt: NULL
  subtitle     TEXT NULL,                       -- concept: povodny termin ('prohairesis'); practice: kratky popis
  text         TEXT NOT NULL,
  tags         TEXT NOT NULL DEFAULT '[]',      -- JSON pole tem z curated/taxonomy.yaml
  status       TEXT NOT NULL CHECK (status IN ('draft', 'approved')),
  source_id    TEXT NOT NULL REFERENCES source(id),
  ord          INTEGER NOT NULL                 -- stabilne poradie v ramci typu
);
CREATE INDEX card_type ON card(type, ord);
CREATE INDEX card_section ON card(section_key);
