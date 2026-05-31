## Tippecanoe settings

Settings used for converting Copenhagen dataset to PMTiles.

```bash
tippecanoe \
--output=trees.pmtiles \
--layer=trees \
--minimum-zoom=12 \
--maximum-zoom=19 \
--base-zoom=12 \
--drop-densest-as-needed \
--buffer=8 \
--no-tile-stats \
--force \
trees_resolved.geojson
```