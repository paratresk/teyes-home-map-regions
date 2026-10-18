#!/usr/bin/env bash
# Uploads the files built into dist/regions to the release $TAG, replaces
# catalog.json in the "catalog" release and deletes region releases the
# catalog no longer refers to. Used by both jobs of workflows/regions.yml.
set -euo pipefail
shopt -s nullglob

files=(dist/regions/*.pmtiles dist/regions/*.pmtiles.[0-9][0-9][0-9])
if [ ${#files[@]} -eq 0 ]; then
  echo "Nothing built" >&2
  exit 1
fi

gh release view "$TAG" > /dev/null 2>&1 || \
  gh release create "$TAG" \
    --title "Offline-Regionen $VERSION" \
    --notes "Karten- und Fahrdaten aus OpenStreetMap (© OpenStreetMap-Mitwirkende, ODbL), Stand $VERSION." \
    --latest=false
gh release upload "$TAG" "${files[@]}" --clobber

gh release view catalog > /dev/null 2>&1 || \
  gh release create catalog --title "Katalog der Offline-Regionen" \
    --notes "catalog.json für die App. Wird bei jedem Bau ersetzt." \
    --latest=false
gh release upload catalog dist/regions/catalog.json --clobber

used=$(grep -o 'releases/download/regions-[0-9-]*' dist/regions/catalog.json \
  | sed 's#releases/download/##' | sort -u)
for tag in $(gh release list --limit 100 --json tagName \
    --jq '.[].tagName | select(startswith("regions-"))'); do
  if ! grep -qx "$tag" <<< "$used"; then
    echo "Deleting $tag"
    gh release delete "$tag" --yes --cleanup-tag
  fi
done
