# Teyes Home Map – Offline-Regionen

Offline-Karten- und Fahrdaten für die Teyes-Home-Map-App, je deutschem
Bundesland und für ganz Deutschland:

- `<region>.map.pmtiles` – Vektorkarte (OpenMapTiles-Schema), passend zu den
  OpenFreeMap-Stilen der App
- `<region>.roads.pmtiles` – Straßen mit Tempolimit- und Zufahrts-Tags,
  Baustellen, Ampeln, Blitzer,
  Tankstellen, Ladesäulen und Parkplätze (Zoomstufe 14, siehe
  `tool/roads.yml`)

Die Deutschland-Karte ist größer als die 2 GB, die GitHub pro Datei erlaubt.
Sie wird deshalb in Teilen veröffentlicht (`germany.map.pmtiles.001`, `.002`,
…). Die App lädt die Teile nacheinander in eine Datei. Wer die Datei von Hand
braucht, hängt die Teile aneinander:

```powershell
cmd /c copy /b germany.map.pmtiles.001+germany.map.pmtiles.002 germany.map.pmtiles
```

Der Workflow [Offline regions](.github/workflows/regions.yml) baut alle
Regionen am 3. jedes Monats mit [Planetiler](https://github.com/onthegomap/planetiler)
aus den [Geofabrik](https://download.geofabrik.de/)-Auszügen und
veröffentlicht sie als Release `regions-<Datum>`. Zuerst baut ein Job die 16
Bundesländer, danach ein zweiter Job auf einem eigenen Runner ganz
Deutschland. Das Release `catalog` enthält `catalog.json`, aus dem die App
Liste, Größen, Versionen und Download-Adressen liest. Von Hand starten:
*Actions → Offline regions → Run workflow*. Optional lassen sich dort nur
einzelne Regionen bauen, `germany` steht für ganz Deutschland.

Lokal bauen (Windows, JDK 21 und `planetiler.jar` in `tool/.cache`):

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_regions.ps1 -Regions berlin
```

Mit `-SplitBytes 1900000000` werden Dateien über dieser Größe in Teile
aufgeteilt, wie im Workflow.

## Lizenz der Daten

Kartendaten © [OpenStreetMap-Mitwirkende](https://www.openstreetmap.org/copyright),
verfügbar unter der [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
Kachelschema [OpenMapTiles](https://openmaptiles.org/).
