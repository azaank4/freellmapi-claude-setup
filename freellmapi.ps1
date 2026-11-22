# One command: make sure the gateway is running, then open the free Claude Code session.
# Usage:  freellmapi

$root = $PSScriptRoot
$gw = Join-Path $root "start-gateway.ps1"
$launcher = Join-Path $root "start-claude-free.ps1"

if (-not (Get-NetTCPConnection -State Listen -LocalPort 3001 -ErrorAction SilentlyContinue)) {
  Write-Host "Gateway not running - starting it in a separate window (keep that window open)..." -ForegroundColor Cyan
  Start-Process powershell -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-File",$gw -WindowStyle Normal
  $ok = $false
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    if (Get-NetTCPConnection -State Listen -LocalPort 3001 -ErrorAction SilentlyContinue) { $ok = $true; break }
  }
  if (-not $ok) { Write-Host "Gateway did not come up within 30s. Check the gateway window for errors." -ForegroundColor Red; return }
  Start-Sleep -Seconds 2
} else {
  Write-Host "Gateway already running." -ForegroundColor DarkGray
}

& $launcher @args
