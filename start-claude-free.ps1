# Launches an ISOLATED Claude Code session that talks to the local FreeLLMAPI gateway.
# Does not touch ~/.claude or any other Claude Code session. Env vars exist only inside this process.

$root = $PSScriptRoot
$keyFile = Join-Path $root ".unified-key.dpapi"

# Key handling: reuse a saved key if present; otherwise ask once and offer to save it.
# The saved copy is encrypted with Windows DPAPI: only YOUR Windows user on THIS machine can decrypt it.
$clean = $null
if (Test-Path $keyFile) {
  try {
    $sec = ([IO.File]::ReadAllText($keyFile)).Trim() | ConvertTo-SecureString
    $clean = [System.Net.NetworkCredential]::new('', $sec).Password
    Write-Host "Using saved key (delete $keyFile to change it)." -ForegroundColor DarkGray
  } catch { Write-Host "Saved key unreadable; asking again." -ForegroundColor Yellow; Remove-Item $keyFile -Force -ErrorAction SilentlyContinue }
}
if (-not $clean) {
  $raw = Read-Host "Paste your FreeLLMAPI unified key (from http://127.0.0.1:3001 > Keys, starts with freellmapi-)"
  $clean = ($raw -replace '[^A-Za-z0-9._-]', '')   # drop spaces, newlines, quotes, control characters
  if ($clean -notmatch '^freellmapi-[A-Za-z0-9]{20,}$') {
    Write-Host "ABORT: that doesn't look like a FreeLLMAPI key (got $($clean.Length) valid characters after cleaning)." -ForegroundColor Red
    return
  }
  $save = Read-Host "Save it (encrypted, this Windows user only) so you don't have to paste it again? [Y/n]"
  if ($save -notmatch '^[nN]') { ConvertTo-SecureString $clean -AsPlainText -Force | ConvertFrom-SecureString | Set-Content $keyFile -Encoding ascii; Write-Host "Saved." -ForegroundColor Green }
}
$env:ANTHROPIC_AUTH_TOKEN = $clean

$env:ANTHROPIC_BASE_URL = "http://127.0.0.1:3001"      # server root, NOT /v1
$env:CLAUDE_CODE_AUTO_MODE_SERVER = "0"                # per FreeLLMAPI docs
# Gateway's Claude-named slots (auto-routed to free models); Claude Code recognises these names.
$env:ANTHROPIC_MODEL = "claude-sonnet-4-5"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-5"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-5"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5"
$env:CLAUDE_CODE_SUBAGENT_MODEL = "claude-sonnet-4-5"

# Pre-flight: refuse to start unless the gateway is up AND accepts the key (prevents silently using Anthropic).
try {
  $null = Invoke-RestMethod "http://127.0.0.1:3001/v1/models" -Headers @{ Authorization = "Bearer $($env:ANTHROPIC_AUTH_TOKEN)" } -TimeoutSec 10
} catch {
  if ($_.Exception.Message -match '401|Unauthorized' -and (Test-Path $keyFile)) {
    Remove-Item $keyFile -Force
    Write-Host "Saved key was rejected (it was probably reset). Deleted it - re-run and paste the new key." -ForegroundColor Yellow
  }
  Write-Host "ABORT: FreeLLMAPI gateway not reachable or key rejected: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "Not starting Claude Code, so nothing can fall back to Anthropic." -ForegroundColor Red
  return
}
Write-Host "BACKEND = FreeLLMAPI @ $($env:ANTHROPIC_BASE_URL)  |  models: $($env:ANTHROPIC_MODEL)" -ForegroundColor Green
Write-Host "Verify any time: node `"$root\who-answered.cjs`"" -ForegroundColor Green
$Host.UI.RawUI.WindowTitle = "Claude Code -> FreeLLMAPI (NOT Anthropic)"

# Separate config dir: own settings, history, MCP list, login. Fully isolated from your normal Claude Code.
$env:CLAUDE_CONFIG_DIR = Join-Path $root "claude-config"
New-Item -ItemType Directory -Force $env:CLAUDE_CONFIG_DIR | Out-Null

# Separate working folder so no project .claude/ hooks from other folders load.
$work = Join-Path $root "workspace"
New-Item -ItemType Directory -Force $work | Out-Null
Set-Location $work

claude
