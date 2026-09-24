# RTL_PATCH_V1 rollback — restores the original app.asar and disables the patched folder.
# Run with the target app fully closed.
param(
  [Parameter(Mandatory = $true)][string]$ResourcesDir
)

$asar = "$ResourcesDir\app.asar"
$backup = "$ResourcesDir\app.asar.pre-rtl-patch"
$app = "$ResourcesDir\app"

if (-not (Test-Path $backup)) {
  Write-Host "No backup found ($backup) - nothing to roll back."
  exit 0
}
if (Test-Path $asar) {
  Write-Host "Conflict: app.asar already exists. Delete it manually first (it is a fresh post-update copy)."
  exit 1
}
Rename-Item $backup "app.asar"
if (Test-Path $app) { Rename-Item $app "app.patched-unused" }
Write-Host "Restored original app. Patched folder kept as app.patched-unused (safe to delete)."
