# Starts the FreeLLMAPI gateway (localhost only). Leave this window open while you use the free Claude Code session.
# Safe to run if it's already running.

$root = $PSScriptRoot

if (Get-NetTCPConnection -State Listen -LocalPort 3001 -ErrorAction SilentlyContinue) {
  Write-Host "Gateway already running on http://127.0.0.1:3001 - nothing to do." -ForegroundColor Green
  return
}

$env:HOST = "127.0.0.1"             # this machine only
$env:PORT = "3001"
$env:STREAM_KEEPALIVE_MS = "15000"  # keeps Claude Code from timing out on slow free models

Write-Host "Starting FreeLLMAPI gateway on http://127.0.0.1:3001 (Ctrl+C to stop)..." -ForegroundColor Cyan
Set-Location "$root\freellmapi\server"
node dist/index.js
