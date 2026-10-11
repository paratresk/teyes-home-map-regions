<#
.SYNOPSIS
  Builds offline region packages for Teyes Home Map.

.DESCRIPTION
  For every Geofabrik area id this writes two files to the output folder:
    <id>.map.pmtiles    vector map tiles (OpenMapTiles schema, as used by the
                        OpenFreeMap styles of the app)
    <id>.roads.pmtiles  zoom 14 road tiles with speed limit tags, traffic
                        signals and speed cameras (tool/roads.yml)
  and updates catalog.json, which the app reads to offer downloads.

  A portable JDK 21 and planetiler.jar are expected in tool/.cache (see
  README). OSM extracts and Planetiler's auxiliary sources (water polygons,
  Natural Earth, ~1.5 GB) are downloaded into tool/.cache/data on first use
  and reused afterwards.

.EXAMPLE
  powershell -File tool/build_regions.ps1 -Regions berlin,brandenburg

.EXAMPLE
  # As run by .github/workflows/regions.yml, with absolute download URLs:
  pwsh tool/build_regions.ps1 -Regions berlin -DownloadBaseUrl https://github.com/me/repo/releases/download/regions-2026-11-01
#>
param(
  [string[]] $Regions = @('berlin'),
  [string] $OutDir = (Join-Path $PSScriptRoot '../dist/regions'),
  [string] $Memory = '6g',
  [switch] $SkipMap,
  [switch] $SkipRoads,
  # When set, catalog.json lists each file as "<DownloadBaseUrl>/<file>".
  [string] $DownloadBaseUrl,
  [string] $Version = (Get-Date -Format 'yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'

$names = @{
  'baden-wuerttemberg'     = 'Baden-Württemberg'
  'bayern'                 = 'Bayern'
  'berlin'                 = 'Berlin'
  'brandenburg'            = 'Brandenburg (mit Berlin)'
  'bremen'                 = 'Bremen'
  'hamburg'                = 'Hamburg'
  'hessen'                 = 'Hessen'
  'mecklenburg-vorpommern' = 'Mecklenburg-Vorpommern'
  'niedersachsen'          = 'Niedersachsen'
  'nordrhein-westfalen'    = 'Nordrhein-Westfalen'
  'rheinland-pfalz'        = 'Rheinland-Pfalz'
  'saarland'               = 'Saarland'
  'sachsen'                = 'Sachsen'
  'sachsen-anhalt'         = 'Sachsen-Anhalt'
  'schleswig-holstein'     = 'Schleswig-Holstein'
  'thueringen'             = 'Thüringen'
  'germany'                = 'Deutschland (komplett)'
}

$cache = Join-Path $PSScriptRoot '.cache'
# Portable JDK on Windows (see README), otherwise Java from JAVA_HOME or PATH.
$java = Join-Path $cache 'jdk/bin/java.exe'
if (-not (Test-Path $java)) {
  $java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/java' } else { 'java' }
}
$jar = Join-Path $cache 'planetiler.jar'
$schema = Join-Path $PSScriptRoot 'roads.yml'
if (-not (Test-Path $jar)) { throw "Missing $jar - see README (Offline regions)." }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

function Invoke-Planetiler([string[]] $arguments) {
  Push-Location $cache
  try {
    & $java "-Xmx$Memory" -jar $jar @arguments
    if ($LASTEXITCODE -ne 0) { throw "Planetiler failed with exit code $LASTEXITCODE" }
  } finally {
    Pop-Location
  }
}

# Reads the bounds (min lon, min lat, max lon, max lat) from a PMTiles v3 header.
function Get-PmtilesBounds([string] $path) {
  $stream = [System.IO.File]::OpenRead($path)
  try {
    $header = New-Object byte[] 127
    [void]$stream.Read($header, 0, 127)
  } finally {
    $stream.Dispose()
  }
  $values = foreach ($offset in 102, 106, 110, 114) {
    [Math]::Round([BitConverter]::ToInt32($header, $offset) / 1e7, 5)
  }
  return , $values
}

function Get-FileEntry([string] $path) {
  $item = Get-Item $path
  $entry = [ordered]@{
    name   = $item.Name
    size   = $item.Length
    sha256 = (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  if ($DownloadBaseUrl) { $entry.url = "$($DownloadBaseUrl.TrimEnd('/'))/$($item.Name)" }
  $entry
}

$catalogPath = Join-Path $OutDir 'catalog.json'
$catalog = [ordered]@{ format = 1; regions = @() }
if (Test-Path $catalogPath) {
  $existing = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $catalog.regions = @($existing.regions)
}

foreach ($region in $Regions) {
  $name = $names[$region]
  if (-not $name) { $name = $region }
  $mapFile = Join-Path $OutDir "$region.map.pmtiles"
  $roadsFile = Join-Path $OutDir "$region.roads.pmtiles"

  if (-not $SkipMap) {
    Write-Host "== $name : map tiles"
    Invoke-Planetiler @("--area=$region", '--download', "--output=$mapFile", '--force')
  }
  if (-not $SkipRoads) {
    Write-Host "== $name : road data"
    Invoke-Planetiler @(
      'generate-custom', "--schema=$schema", "--area=$region",
      '--minzoom=14', '--maxzoom=14', "--output=$roadsFile", '--force'
    )
  }

  $entry = [ordered]@{
    id      = $region
    name    = $name
    version = $Version
    bounds  = Get-PmtilesBounds $mapFile
    files   = @((Get-FileEntry $mapFile), (Get-FileEntry $roadsFile))
  }
  $catalog.regions = @($catalog.regions | Where-Object { $_.id -ne $region }) + $entry
}

$catalog.regions = @($catalog.regions | Sort-Object { $_.name })
$json = $catalog | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($catalogPath, $json, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Done. Upload the contents of $OutDir to your download server, or copy the"
Write-Host ".pmtiles files to the device (see README)."
