# Aufgabe 2026-10-13 — Drizzle ORM (KM5-05)

Leseauftrag: das Drizzle-Projekt (`Beispielprojekte/km5-05-drizzle-orm/`)
gründlich durcharbeiten und erweitern. Projekt liegt kopiert unter
[`km5-05-drizzle-orm/`](km5-05-drizzle-orm/); `demo.ts` ist um drei Queries
ergänzt.

## 1. Vorhersage: erzeugtes SQL (vor dem Ausführen notiert)

### a) `db.select().from(artist).where(eq(artist.gruendungsjahr, 1999))`

```sql
select "id", "name", "gruendungsjahr" from "artist" where "artist"."gruendungsjahr" = ?
```

- **Spaltenliste:** `"id", "name", "gruendungsjahr"` — `select()` ohne Argument
  listet **alle** Schema-Spalten in Schema-Reihenfolge auf (kein `*`).
- **WHERE:** `"artist"."gruendungsjahr" = ?` — der Vergleichswert ist **nicht**
  im Text.
- **Parameter:** `[ 1999 ]`

### b) `db.select({ n: count() }).from(album).where(eq(album.artistId, 1))`

```sql
select count(*) from "album" where "album"."artist_id" = ?
```

- **Spaltenliste:** `count(*)` — `count()` ohne Spaltenargument zählt Zeilen
  (Aggregat), wie in der Lesson (Quiz 10).
- **WHERE:** `"album"."artist_id" = ?` — TS-Feld `artistId`, DB-Spalte
  `artist_id`.
- **Parameter:** `[ 1 ]`

> Beide Werte (`1999`, `1`) landen in `toSQL().params`, nie im SQL-Text —
> Parametrisierung by default.

## 2. Drei zusätzliche Queries in `demo.ts`

Ergänzt nach dem `count/groupBy`-Block (vor `update`/`delete`, damit `Echo Room`
noch existiert):

| # | Frage                          | Drizzle                                                        | Erzeugtes SQL                                                                                                                 |
| - | ------------------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| 1 | Ältestes Album                 | `orderBy(asc(album.jahr)).limit(1)`                            | `select "id", "titel", "jahr", "artist_id" from "album" order by "album"."jahr" asc limit ?`                                  |
| 2 | Tracks mit Titel-Anfang „Echo“ | `where(and(eq(track.albumId, …), like(track.titel, "Echo%")))` | `select "id", "titel", "dauer_sek", "album_id" from "track" where (("track"."album_id" = ?) and ("track"."titel" like ?))`    |
| 3 | Tracks pro Album               | `count()` + `innerJoin` + `groupBy(album.id)`                  | `select "album"."titel", count(*) from "track" inner join "album" on "track"."album_id" = "album"."id" group by "album"."id"` |

Ergebnisse der Demo:

- Ältestes Album: **Night Ferry (2012)**
- Echo-Tracks: `[ { id: 2, titel: "Echo Room", dauerSek: 187, albumId: 1 } ]`
- Tracks pro Album: `[ { titel: "Silent Lines", tracks: 2 } ]`

## 3. SQL-Vergleich (Interleaving): „Tracks pro Album“

Reines SQL (KM5-Kern):

```sql
SELECT album.titel, COUNT(*)
FROM track
INNER JOIN album ON track.album_id = album.id
GROUP BY album.id;
```

Von Drizzle erzeugt (identische Bausteine, nur mit Anführungszeichen):

```sql
select "album"."titel", count(*) from "track"
  inner join "album" on "track"."album_id" = "album"."id"
  group by "album"."id"
```

Zuordnung der Bausteine:

| SQL-Baustein            | Drizzle                                         | Stelle                |
| ----------------------- | ----------------------------------------------- | --------------------- |
| `INNER JOIN album ON …` | `innerJoin(album, eq(track.albumId, album.id))` | Join + `on`-Bedingung |
| `COUNT(*)`              | `count()` in der Spaltenliste                   | Aggregat              |
| `GROUP BY album.id`     | `.groupBy(album.id)`                            | Gruppierung           |

Drizzle „tippt“ also genau dasselbe SQL, das ich von Hand schreibe — Gruppierung
erfolgt über den Primärschlüssel `album.id` (SQLite erlaubt dann `album.titel`
in der Auswahl).

## 4. Nachweis

`deno task demo` (9 Konsolenzeilen der neuen/alten Queries) und `deno task test`
(9/9 grün) laufen im Projektordner durch. Der `demo.ts`-Diff ist im Ordner
`km5-05-drizzle-orm/` enthalten.
