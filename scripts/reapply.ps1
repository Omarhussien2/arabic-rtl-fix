# RTL_PATCH_V1 re-apply — run AFTER an app update wiped the patch (fresh app.asar is back).
# Requires the target app to be fully closed.
param(
  [Parameter(Mandatory = $true)][string]$ResourcesDir
)

$SkillDir = Split-Path -Parent $PSScriptRoot   # skill root (scripts/..)
$Injector = "$SkillDir\scripts\inject-rtl.mjs"

if (-not (Test-Path $Injector)) { Write-Host "Missing injector: $Injector" -ForegroundColor Red; exit 1 }
if (Get-Command node -ErrorAction SilentlyContinue) { } else { Write-Host "node not found in PATH" -ForegroundColor Red; exit 1 }

if (-not (Test-Path "$ResourcesDir\app.asar")) {
  Write-Host "No $ResourcesDir\app.asar - patch may already be active. Nothing to do."
  exit 0
}

Set-Location $ResourcesDir
if (Test-Path "$ResourcesDir\app") { Remove-Item -Recurse -Force "$ResourcesDir\app" }
if (Test-Path "$ResourcesDir\app.asar.pre-rtl-patch") { Remove-Item -Force "$ResourcesDir\app.asar.pre-rtl-patch" }

npx --yes @electron/asar extract app.asar app
if ($LASTEXITCODE -ne 0) { Write-Host "asar extract failed" -ForegroundColor Red; exit 1 }
if (Test-Path "$ResourcesDir\app.asar.unpacked") {
  Copy-Item -Recurse -Force "$ResourcesDir\app.asar.unpacked\*" "$ResourcesDir\app\"
}

$htmlFiles = Get-ChildItem -Path "$ResourcesDir\app" -Recurse -Filter "*.html" |
  Where-Object { $_.FullName -notmatch "node_modules" } |
  ForEach-Object { $_.FullName }
if (-not $htmlFiles) { Write-Host "No HTML files found under app/" -ForegroundColor Red; exit 1 }

& node $Injector @htmlFiles
if ($LASTEXITCODE -ne 0) { Write-Host "inject failed" -ForegroundColor Red; exit 1 }

Rename-Item "$ResourcesDir\app.asar" "app.asar.pre-rtl-patch"
Write-Host "RTL patch re-applied. Start the app normally." -ForegroundColor Green
