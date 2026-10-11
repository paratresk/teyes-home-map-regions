# Teyes Home Map – Offline-Regionen

Offline-Karten- und Fahrdaten für die Teyes-Home-Map-App, je deutschem
Bundesland:

- `<region>.map.pmtiles` – Vektorkarte (OpenMapTiles-Schema), passend zu den
  OpenFreeMap-Stilen der App
- `<region>.roads.pmtiles` – Straßen mit Tempolimit-Tags, Ampeln und Blitzer
  (Zoomstufe 14, siehe `tool/roads.yml`)

Der Workflow [Offline regions](.github/workflows/regions.yml) baut alle
Regionen am 3. jedes Monats mit [Planetiler](https://github.com/onthegomap/planetiler)
aus den [Geofabrik](https://download.geofabrik.de/)-Auszügen und
veröffentlicht sie als Release `regions-<Datum>`. Das Release `catalog`
enthält `catalog.json`, aus dem die App Liste, Größen, Versionen und
Download-Adressen liest. Von Hand starten: *Actions → Offline regions →
Run workflow* (optional nur einzelne Regionen).

Lokal bauen (Windows, JDK 21 und `planetiler.jar` in `tool/.cache`):

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_regions.ps1 -Regions berlin
```

## Lizenz der Daten

Kartendaten © [OpenStreetMap-Mitwirkende](https://www.openstreetmap.org/copyright),
verfügbar unter der [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
Kachelschema [OpenMapTiles](https://openmaptiles.org/).
