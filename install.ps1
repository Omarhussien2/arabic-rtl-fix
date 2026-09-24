# arabic-rtl-fix installer (Windows PowerShell)
# Copies the skill to the cross-tool skills library: ~/.agents/skills/
$ErrorActionPreference = "Stop"

$src = Split-Path -Parent $MyInvocation.MyCommand.Path
$destRoot = Join-Path $HOME ".agents\skills"
$dest = Join-Path $destRoot "arabic-rtl-fix"

New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
if (Test-Path $dest) {
  Write-Host "Updating existing skill at $dest" -ForegroundColor Yellow
  Remove-Item -Recurse -Force $dest
}
Copy-Item -Recurse $src $dest
Write-Host "Installed: $dest" -ForegroundColor Green
Write-Host "Restart your AI agent (ZCode / Claude Code / Cursor) and say:" -ForegroundColor Cyan
Write-Host '  "العربي معكوس في تطبيق X، صلّحه"'
