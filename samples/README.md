# samples/

This directory contains **no PDFs in the public repo** (they're large and not
under our copyright). The `.gitignore` excludes `*.pdf` to keep the repo lean.

## Download a free test PDF

```bash
./scripts/fetch_samples.sh
```

That script downloads the **USGS San Francisco North 1:24,000 US Topo**
quadrangle (38 MB, public domain US Government work) into
`samples/USGS_SF_North.pdf`. The same PDF is the basemap in screenshot §2 of
the README.

File: `CA_San_Francisco_North_20211230_TM_geo.pdf` (2021-12-30 edition).

## Push the PDF into the iOS simulator for testing

```bash
APP_CONTAINER=$(xcrun simctl get_app_container 'iPhone 17 Pro' com.tacticalmaps.app data)
cp samples/USGS_SF_North.pdf "$APP_CONTAINER/Documents/"
```

Then in the running app: **☰ → Import PDF Map** → **On My iPhone →
TacticalMaps → USGS_SF_North.pdf**.

## Why not commit the PDF directly?

- **Size**: USGS US Topo PDFs are 30–50 MB each. Bloats the repo.
- **Discoverability**: anyone cloning the repo can pull fresh USGS sheets for
  their own area of interest — the canonical S3 host is documented in
  `scripts/fetch_samples.sh`.
- **Updates**: USGS re-publishes quads on a ~5-year cadence; the script can
  be bumped to a newer edition without a binary diff in git history.

## Where to find other free GeoPDFs

| Region | Source | Format | Notes |
|---|---|---|---|
| United States | USGS US Topo (1:24k) | OGC GeoPDF + Adobe Geospatial /VP | <https://www.usgs.gov/programs/national-geospatial-program/us-topo-maps-america> |
| Canada | Natural Resources Canada (NRCan) topo | GeoPDF | <https://maps.canada.ca/> |
| France | IGN SCAN 25 | GeoPDF | Some free, most subscription |
| United Kingdom | Ordnance Survey OS Maps | Mostly raster PDF, partial geo | Requires OS subscription for full geo |
| Australia | Geoscience Australia 1:250k / 1:100k | GeoPDF | Public-sector data, free |
| New Zealand | Land Information NZ NZTopo50 | GeoPDF | Creative Commons — free |
