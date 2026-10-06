# HÜ 2026-10-06 — Dritte Normalform (3NF) · 3AHWII X

Hausübung zur UE „Dritte Normalform (3NF), Fehlersuche" vom 06.10.2026.
Abgabe bis **13.10.2026**. Detailstoff: `lesson-3nf.html` (§1–§8).

## 1. `bestellung_denorm` schriftlich bis 3NF zerlegen

Ausgangstabelle (aus `seed-3nf.sql`):

```
Bestellung(BestellNr PK, Kunde, PLZ, Ort)
   101 | Auer  | 1020 | Wien
   102 | Beck  | 1020 | Wien
   103 | Cevik | 4020 | Linz
```

### Schritt 0 — Abhängigkeitspfeile bestimmen

```
BestellNr → Kunde          (Kunde hängt direkt am Schlüssel)
BestellNr → PLZ            (PLZ hängt direkt am Schlüssel)
BestellNr → PLZ → Ort      (Ort hängt NICHT direkt, sondern über PLZ)
```

`Ort` hängt an einem **Nicht-Schlüssel** (`PLZ`) → 3NF verletzt.

### Schritt 1 — 1NF: erfüllt

Alle Attribute sind **atomar** (eine PLZ, ein Ort, ein Kunde pro Zelle), es gibt
keine Listen in einer Spalte. **Kein Handlungsbedarf.**

### Schritt 2 — 2NF: erfüllt

Der Schlüssel ist **einfach** (`BestellNr`). Partielle Abhängigkeiten (an einem
*Teil* eines zusammengesetzten Schlüssels) sind damit gar nicht möglich. Jedes
Nicht-Schlüssel-Attribut hängt am *ganzen* Schlüssel. **Kein Handlungsbedarf.**

### Schritt 3 — 3NF: verletzt → zerlegen

Eselsbrücke (Codd): *„vom ganzen Schlüssel, nichts als der Schlüssel."*
`Ort` hängt an einem anderen Nicht-Schlüssel (`PLZ`) — mehr als der Schlüssel.

Reparatur (immer gleich): **Tabelle spalten, Fremdschlüssel setzen.** Die
Tatsache `PLZ → Ort` kommt in eine eigene Tabelle `PLZ`, `Bestellung`
verweist per Fremdschlüssel.

```
Bestellung(BestellNr PK, Kunde, PLZ FK → PLZ.PLZ)     PLZ(PLZ PK, Ort)
   101 | Auer  | 1020                                   1020 | Wien
   102 | Beck  | 1020                                   4020 | Linz
   103 | Cevik | 4020
```

Jede Tatsache steht jetzt **genau einmal** („1020 = Wien" nur noch in `PLZ`).
Änderungs-/Einfüge-/Lösch-Anomalie sind weg:

- **Ändern:** PLZ 1020 bekommt neuen Ortsnamen → 1 Zeile in `PLZ`.
- **Einfügen:** neue PLZ ohne Bestellung → eigene `PLZ`-Zeile, kein Dummy nötig.
- **Löschen:** letzte 4020-Bestellung löschen → `PLZ`-Wissen „4020 = Linz" bleibt erhalten.

## 2. Zwei Quiz-Tabellen zerlegen (CREATEs + je 3 Zeilen)

Gewählt: **Quiz 2 (Schueler)** und **Quiz 5 (Konto, SWP-Crossover).**
Das ausführbare Skript liegt unter [`zerlegung.sql`](zerlegung.sql).

### Quiz 2 — Schueler

```
Schueler(MatrNr PK, Name, Klasse, Klassensprecher)
    1 | Auer  | 3AHWII | Beck
    2 | Beck  | 3AHWII | Beck
    3 | Cevik | 3BHWII | Demir
```

Pfeile:

```
MatrNr → Name
MatrNr → Klasse
MatrNr → Klasse → Klassensprecher     ← transitiv (Klassensprecher hängt an Klasse)
```

`Klassensprecher` ist eine Tatsache über die **Klasse**, nicht über den
Schüler → 3NF-Fix: `Klasse(Klasse, Klassensprecher)` auslagern.

```sql
CREATE TABLE klasse(
  klasse          TEXT PRIMARY KEY,
  klassensprecher TEXT NOT NULL
);
INSERT INTO klasse(klasse, klassensprecher) VALUES
  ('3AHWII', 'Beck'),
  ('3BHWII', 'Demir'),
  ('3CHWII', 'Erner');

CREATE TABLE schueler(
  matr_nr INTEGER PRIMARY KEY,
  name    TEXT NOT NULL,
  klasse  TEXT NOT NULL REFERENCES klasse(klasse)
);
INSERT INTO schueler(matr_nr, name, klasse) VALUES
  (1, 'Auer',  '3AHWII'),
  (2, 'Beck',  '3AHWII'),
  (3, 'Cevik', '3BHWII');
```

### Quiz 5 — Konto (SWP-Domäne)

```
Konto(IBAN PK, Inhaber, BLZ, Bankname)
   AT01 | Auer  | 1000 | Erste Bank
   AT02 | Beck  | 1000 | Erste Bank

IBAN → Inhaber
IBAN → BLZ
IBAN → BLZ → Bankname     ← transitiv (Bankname hängt an BLZ)
```

`Bankname` hängt am Bankcode `BLZ`, nicht an der IBAN → 3NF-Fix:
`Bank(BLZ, Bankname)` auslagern (dieselbe Struktur wie `PLZ → Ort`).

```sql
CREATE TABLE bank(
  blz      TEXT PRIMARY KEY,
  bankname TEXT NOT NULL
);
INSERT INTO bank(blz, bankname) VALUES
  ('1000', 'Erste Bank'),
  ('1200', 'Bank Austria'),
  ('1400', 'Raiffeisen');

CREATE TABLE konto(
  iban    TEXT PRIMARY KEY,
  inhaber TEXT NOT NULL,
  blz     TEXT NOT NULL REFERENCES bank(blz)
);
INSERT INTO konto(iban, inhaber, blz) VALUES
  ('AT01', 'Auer',  '1000'),
  ('AT02', 'Beck',  '1000'),
  ('AT03', 'Cevik', '1200');
```

## 3. Demo laufen lassen (Nachweis)

`deno task demo` (nur Deno, kein Node, kein `npm:`). Ausgabe der zwei
Konsolenzeilen:

```
PLZ 1020 hat 2 verschiedene Orte -> Anomalie!
PLZ-Tabelle hat 1 Zeile fuer 1020 -> genau einmal.
```

Verifikation zusätzlich: `deno task test` → 2 Tests grün, `deno task demo` nutzt
`node:sqlite` auf einer In-Memory-DB.