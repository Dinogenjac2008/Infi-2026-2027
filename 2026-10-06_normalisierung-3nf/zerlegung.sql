-- zerlegung.sql — HÜ 2026-10-06: 3NF-Zerlegung der zwei gewählten
-- Quiz-Tabellen + Bestellungs-Fix. Reines SQLite, kein ORM, kein Node.
-- Laufen lassen mit:  sqlite3 zerlegung.db < zerlegung.sql
-- (oder via deno + node:sqlite, siehe unten im Kommentar)

-- === Aufgabe 1: bestellung_denorm bis 3NF ==========================
-- Kette: BestellNr -> PLZ -> Ort  (Ort hängt an Nicht-Schlüssel PLZ)
-- Tatsache "PLZ -> Ort" zuerst anlegen, damit der FK gültig ist:

DROP TABLE IF EXISTS plz;
CREATE TABLE plz(
  plz TEXT PRIMARY KEY,
  ort TEXT NOT NULL
);
INSERT INTO plz(plz, ort) VALUES ('1020', 'Wien'), ('4020', 'Linz');

DROP TABLE IF EXISTS bestellung;
CREATE TABLE bestellung(
  bestell_nr INTEGER PRIMARY KEY,
  kunde      TEXT NOT NULL,
  plz        TEXT NOT NULL REFERENCES plz(plz)
);
INSERT INTO bestellung(bestell_nr, kunde, plz) VALUES
  (101, 'Auer',  '1020'),
  (102, 'Beck',  '1020'),
  (103, 'Cevik', '4020');

-- === Aufgabe 2a: Quiz 2 Schueler ====================================
-- Kette: MatrNr -> Klasse -> Klassensprecher

DROP TABLE IF EXISTS klasse;
CREATE TABLE klasse(
  klasse          TEXT PRIMARY KEY,
  klassensprecher TEXT NOT NULL
);
INSERT INTO klasse(klasse, klassensprecher) VALUES
  ('3AHWII', 'Beck'),
  ('3BHWII', 'Demir'),
  ('3CHWII', 'Erner');

DROP TABLE IF EXISTS schueler;
CREATE TABLE schueler(
  matr_nr INTEGER PRIMARY KEY,
  name    TEXT NOT NULL,
  klasse  TEXT NOT NULL REFERENCES klasse(klasse)
);
INSERT INTO schueler(matr_nr, name, klasse) VALUES
  (1, 'Auer',  '3AHWII'),
  (2, 'Beck',  '3AHWII'),
  (3, 'Cevik', '3BHWII');

-- === Aufgabe 2b: Quiz 5 Konto (SWP-Crossover) ======================
-- Kette: IBAN -> BLZ -> Bankname

DROP TABLE IF EXISTS bank;
CREATE TABLE bank(
  blz      TEXT PRIMARY KEY,
  bankname TEXT NOT NULL
);
INSERT INTO bank(blz, bankname) VALUES
  ('1000', 'Erste Bank'),
  ('1200', 'Bank Austria'),
  ('1400', 'Raiffeisen');

DROP TABLE IF EXISTS konto;
CREATE TABLE konto(
  iban    TEXT PRIMARY KEY,
  inhaber TEXT NOT NULL,
  blz     TEXT NOT NULL REFERENCES bank(blz)
);
INSERT INTO konto(iban, inhaber, blz) VALUES
  ('AT01', 'Auer',  '1000'),
  ('AT02', 'Beck',  '1000'),
  ('AT03', 'Cevik', '1200');

-- === Stichproben =====================================================
SELECT 'ort steht 1x' AS pruefung, COUNT(*) AS n FROM plz WHERE plz = '1020';
SELECT 'sprecher steht 1x' AS pruefung, COUNT(*) AS n
  FROM klasse WHERE klasse = '3AHWII';
SELECT 'bankname steht 1x' AS pruefung, COUNT(*) AS n
  FROM bank WHERE blz = '1000';

-- Variante ohne sqlite3-CLI (Deno + node:sqlite):
--   deno eval --allow-read 'import { DatabaseSync } from "node:sqlite"; const db = new DatabaseSync(":memory:"); db.exec(Deno.readTextFileSync("zerlegung.sql")); console.log(db.prepare("SELECT COUNT(*) AS n FROM bestellung").get());'