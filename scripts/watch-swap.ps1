# RTL_PATCH_V1 watcher — waits until the target app fully quits,
# then renames app.asar -> app.asar.pre-rtl-patch so the patched app/ folder loads.
param(
  [Parameter(Mandatory = $true)][string]$ResourcesDir,
  [string]$ProcessName = "",
  [string]$LogPath = "$env:TEMP\rtl-watch-swap.log",
  [int]$TimeoutHours = 24
)

$deadline = (Get-Date).AddHours($TimeoutHours)
function Log($msg) {
  try {
    $logDir = Split-Path -Parent $LogPath
    if ($logDir -and -not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" -ErrorAction SilentlyContinue
  } catch {}
}

Log "watcher started (ResourcesDir=$ResourcesDir ProcessName=$ProcessName)"
while ((Get-Date) -lt $deadline) {
  $running = $false
  if ($ProcessName) { $running = [bool](Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) }
  if (-not $running) {
    if ((Test-Path "$ResourcesDir\app.asar") -and (Test-Path "$ResourcesDir\app\package.json")) {
      if (Test-Path "$ResourcesDir\app.asar.pre-rtl-patch") {
        Log "SKIP: backup already exists"
      } else {
        try {
          Rename-Item -Path "$ResourcesDir\app.asar" -NewName "app.asar.pre-rtl-patch" -ErrorAction Stop
          Log "SUCCESS: app.asar renamed - RTL patch is now active"
        } catch {
          Log "FAILED to rename: $($_.Exception.Message)"
        }
      }
    } else {
      Log "nothing to do (app.asar or patched app folder missing)"
    }
    break
  }
  Start-Sleep -Seconds 3
}
Log "watcher exited"
