<#
.SYNOPSIS
    Packs src/ into a loadable .scs mod archive.

.DESCRIPTION
    A .scs mod is a plain ZIP. This script packs src/ into dist/<name>.scs and
    can install it into the game's mod folder.

    It also guards the two failure modes that produce no usable error in game:

      1. A UTF-8 BOM in front of the leading SiiNunit token. Most Windows
         editors add one silently and the parser then rejects the file.
      2. A unit-name token longer than 12 characters, or outside [a-z0-9_].
         The game rejects the entire file and the part simply never appears,
         which is indistinguishable from the mod not loading at all.

    Keep this file pure ASCII. Windows PowerShell 5.1 reads .ps1 as ANSI unless
    the file has a BOM, so a stray non-ASCII character breaks the parser.

.EXAMPLE
    .\build.ps1                 # pack only
    .\build.ps1 -Install        # pack, then copy into the game mod folder
    .\build.ps1 -Uninstall      # remove it from the game mod folder
    .\build.ps1 -Workshop       # lay out the folder the SCS Workshop Uploader wants
#>
[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Workshop
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ModName   = 'drag_5000_r2016'

$Root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $Root 'src'
$DistDir   = Join-Path $Root 'dist'
$ScsPath   = Join-Path $DistDir "$ModName.scs"
$GameMods  = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Euro Truck Simulator 2\mod'
$Installed = Join-Path $GameMods "$ModName.scs"

# --- uninstall ------------------------------------------------------------
if ($Uninstall) {
    if (Test-Path $Installed) { Remove-Item $Installed -Force; Write-Host "removed  $Installed" -ForegroundColor Yellow }
    else { Write-Host "not installed: $Installed" -ForegroundColor DarkGray }
    return
}

# --- validate -------------------------------------------------------------
if (-not (Test-Path $SourceDir)) { throw "Source folder not found: $SourceDir" }
if (-not (Test-Path (Join-Path $SourceDir 'manifest.sii'))) { throw "manifest.sii missing at the root of src/" }

$files = Get-ChildItem $SourceDir -Recurse -File |
         Where-Object { $_.Name -notmatch '^(\.gitignore|Thumbs\.db|desktop\.ini)$' }
if (-not $files) { throw "No files to pack in $SourceDir" }

# Unit names are dot-separated tokens; each is capped at 12 characters and
# limited to [a-z0-9_].
$MaxToken   = 12
$nameErrors = @()

foreach ($f in ($files | Where-Object { $_.Extension -eq '.sii' })) {
    $rel = $f.FullName.Substring($SourceDir.Length + 1)
    $n   = 0
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
        $n++
        # Unit declarations are "<class> : <name>"; attributes are "key: value"
        # with no space before the colon. That spacing is the discriminator.
        if ($line -match '^\s*[a-z0-9_]+\s+:\s+(\S+)\s*$') {
            $unit = $matches[1]
            foreach ($tok in $unit.Split('.')) {
                if ($tok -eq '') { continue }   # leading dot, e.g. ".package_name"
                if ($tok.Length -gt $MaxToken) {
                    $nameErrors += "  $rel line ${n}: token '$tok' is $($tok.Length) chars (max $MaxToken) in '$unit'"
                }
                elseif ($tok -cnotmatch '^[a-z0-9_]+$') {
                    $nameErrors += "  $rel line ${n}: token '$tok' has characters outside [a-z0-9_] in '$unit'"
                }
            }
        }
    }
}

if ($nameErrors) {
    Write-Host "Invalid SII unit names - the game would reject these files:" -ForegroundColor Red
    $nameErrors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    throw "Aborting: fix the unit names above."
}

# --- workshop layout ------------------------------------------------------
# The SCS Workshop Uploader does not accept a .scs. It wants a folder holding
# versions.sii plus one subfolder of LOOSE mod files per game-version target,
# and packages them itself:
#
#   dist/workshop/
#     versions.sii
#     universal/          <- folder name must match package_name below
#       manifest.sii
#       def/...
#
# One "universal" package with no compatible_versions[] serves every game
# version; the inner manifest.sii still declares its own 1.60.* compatibility.
if ($Workshop) {
    $wsRoot = Join-Path $DistDir 'workshop'
    $wsPkg  = Join-Path $wsRoot 'universal'

    if (Test-Path $wsRoot) { Remove-Item $wsRoot -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $wsPkg | Out-Null

    Copy-Item (Join-Path $SourceDir '*') $wsPkg -Recurse -Force

    if (-not (Test-Path (Join-Path $wsPkg 'mod_icon.jpg'))) {
        throw "src\mod_icon.jpg is missing. The Workshop validator fails with " +
              "'No icon specified'. Generate one with make-icon.ps1."
    }

    # The Workshop validator rejects two fields the standalone .scs needs:
    #   compatible_versions[]  ERROR 00010 - versions.sii owns versioning here
    #   display_name           WARN  00002 - the Steam item supplies the name
    #
    # Each is preceded by a "#!standalone" line in src/manifest.sii. Drop that
    # marker and the line after it, so one src/manifest.sii serves both targets
    # without this script needing to know the field names.
    $wsManifest = Join-Path $wsPkg 'manifest.sii'
    $src   = [System.IO.File]::ReadAllLines($wsManifest)
    $kept  = New-Object System.Collections.Generic.List[string]
    $drop  = 0
    $wasBlank = $false

    foreach ($line in $src) {
        if ($line -match '^\s*#!standalone\s*$') { $drop = 1; continue }
        if ($drop -gt 0) { $drop--; continue }

        # Collapse the blank runs the removals leave behind.
        $isBlank = ($line.Trim() -eq '')
        if ($isBlank -and $wasBlank) { continue }
        $wasBlank = $isBlank

        $kept.Add($line)
    }

    # Also drop the explanatory comment block about the markers.
    $filtered = $kept | Where-Object { $_ -notmatch '^\s*#.*(#!standalone|Workshop validator rejects|takes the name from the Steam|versions\.sii\. They are still)' }

    [System.IO.File]::WriteAllLines($wsManifest, $filtered, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  stripped #!standalone fields from workshop manifest" -ForegroundColor DarkGray

    $versions = @(
        'SiiNunit'
        '{'
        'package_version_info : .universal'
        '{'
        "`tpackage_name: `"universal`""
        '}'
        '}'
    )
    # UTF-8 without BOM: the SII parser rejects a BOM ahead of SiiNunit.
    [System.IO.File]::WriteAllLines(
        (Join-Path $wsRoot 'versions.sii'),
        $versions,
        (New-Object System.Text.UTF8Encoding($false)))

    Write-Host "workshop layout ready" -ForegroundColor Green
    Get-ChildItem $wsRoot -Recurse | ForEach-Object {
        $suffix = if ($_.PSIsContainer) { '\' } else { '' }
        "  " + $_.FullName.Substring($wsRoot.Length + 1) + $suffix
    }
    Write-Host ""
    Write-Host "Point the uploader's Folder field at:" -ForegroundColor Cyan
    Write-Host "  $wsRoot" -ForegroundColor Cyan
    Write-Host "A 640x360 JPG preview image (max 1 MB) is still required." -ForegroundColor Cyan
    return
}

# --- pack -----------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
if (Test-Path $ScsPath) { Remove-Item $ScsPath -Force }

$TextExt = '.sii', '.sui', '.txt', '.mat', '.tobj', '.soundref', '.cfg', '.guids'
$Bom     = 0xEF, 0xBB, 0xBF

$zip = [System.IO.Compression.ZipFile]::Open($ScsPath, 'Create')
try {
    foreach ($f in $files) {
        # Entry names must be relative and forward-slashed; the game is
        # case-sensitive about resource paths, so keep them lower-case.
        $rel   = $f.FullName.Substring($SourceDir.Length + 1).Replace('\', '/')
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $note  = ''

        if ($TextExt -contains $f.Extension.ToLower() -and
            $bytes.Length -ge 3 -and $bytes[0] -eq $Bom[0] -and $bytes[1] -eq $Bom[1] -and $bytes[2] -eq $Bom[2]) {
            $bytes = $bytes[3..($bytes.Length - 1)]
            $note  = '  (BOM stripped)'
        }

        $entry  = $zip.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::NoCompression)
        $stream = $entry.Open()
        try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }

        Write-Host "  + $rel$note" -ForegroundColor DarkGray
    }
}
finally { $zip.Dispose() }

$sizeKB = [math]::Round((Get-Item $ScsPath).Length / 1KB, 1)
Write-Host "packed   $ScsPath  ($($files.Count) files, $sizeKB KB)" -ForegroundColor Green

# --- install --------------------------------------------------------------
if (-not $Install) { return }
if (-not (Test-Path $GameMods)) { throw "Game mod folder not found: $GameMods" }

# The game mounts each .scs at startup and holds the handle for the whole
# session, so the copy fails while it is running.
if (Get-Process eurotrucks2 -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "Cannot install: ETS2 is running and has $ModName.scs open." -ForegroundColor Red
    Write-Host "Quit to desktop, then run this again." -ForegroundColor Red
    throw "ETS2 is running."
}

Copy-Item $ScsPath $Installed -Force
Write-Host "installed $Installed" -ForegroundColor Green
Write-Host "Enable it in Mod Manager, then fit the parts at a dealer or garage." -ForegroundColor Cyan

