#!/usr/bin/env bash
#
# Download free / public-domain sample GeoPDFs into samples/ for testing
# import + render in the iOS / Android app. PDFs are not committed to the
# repo (they're large and not under our copyright) — this script fetches
# them on demand.
#
# Usage:  ./scripts/fetch_samples.sh
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/samples"
mkdir -p "$DEST"

# USGS US Topo — public domain (US government work). The S3 bucket below is
# the canonical USGS "StagedProducts" host; URLs are stable per edition date.
#
# Picked quad: San Francisco North — it covers the Golden Gate, the city,
# and matches the iPhone simulator's default GPS coords (37.78°N, 122.42°W).
USGS_SF_NORTH_URL="https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/USTopo/PDF/CA/CA_San_Francisco_North_20211230_TM_geo.pdf"
USGS_SF_NORTH_FILE="$DEST/USGS_SF_North.pdf"

if [[ -f "$USGS_SF_NORTH_FILE" ]]; then
  echo "✓ $USGS_SF_NORTH_FILE already exists ($(du -h "$USGS_SF_NORTH_FILE" | cut -f1))"
else
  echo "↓ Downloading USGS San Francisco North 1:24,000 topo …"
  curl -L --fail -o "$USGS_SF_NORTH_FILE" "$USGS_SF_NORTH_URL"
  echo "✓ Saved to $USGS_SF_NORTH_FILE ($(du -h "$USGS_SF_NORTH_FILE" | cut -f1))"
fi

echo
echo "To push into the running iPhone simulator:"
echo "  APP_CONTAINER=\$(xcrun simctl get_app_container 'iPhone 17 Pro' com.tacticalmaps.app data)"
echo "  cp samples/USGS_SF_North.pdf \"\$APP_CONTAINER/Documents/\""
echo
echo "Then in the app:  ☰ → Import PDF Map → On My iPhone → TacticalMaps → USGS_SF_North.pdf"
