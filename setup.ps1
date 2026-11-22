# One-time setup on a new Windows machine. Run from this folder:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
#
# It: checks prerequisites, clones FreeLLMAPI, installs + builds it, creates the isolated Claude Code
# config (settings + MCP servers) from templates, and installs the `freellmapi` command.
# No secrets are stored in this repo; anything secret is typed in by you and stays on this machine.

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
function Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }

Step "Checking prerequisites"
foreach ($c in "git","node","npm","claude") {
  if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "'$c' not found. Install it first (git, Node.js 20-24, Claude Code) and re-run." }
}
$nodeMajor = [int]((node --version).TrimStart('v').Split('.')[0])
if ($nodeMajor -lt 20 -or $nodeMajor -gt 24) { Write-Host "Warning: Node $(node --version) is outside FreeLLMAPI's supported range (20-24). It may still work." -ForegroundColor Yellow }

Step "Cloning FreeLLMAPI (upstream project)"
$repo = Join-Path $root "freellmapi"
if (-not (Test-Path $repo)) { git clone --depth 1 https://github.com/tashfeenahmed/freellmapi.git $repo } else { Write-Host "Already cloned." }

Step "Installing dependencies and building (takes a few minutes)"
Push-Location $repo
npm install --no-audit --no-fund
npm run build -w server
npm run build -w client
Pop-Location

Step "Creating isolated Claude Code config"
$cfg = Join-Path $root "claude-config"
New-Item -ItemType Directory -Force $cfg | Out-Null
if (-not (Test-Path "$cfg\settings.json")) { Copy-Item "$root\templates\claude-settings.json" "$cfg\settings.json" }

$mcp = [ordered]@{
  playwright = [ordered]@{ type = "stdio"; command = "cmd"; args = @("/c","npx","-y","@playwright/mcp@latest"); env = @{} }
  notion     = [ordered]@{ type = "http"; url = "https://mcp.notion.com/mcp" }
}
$fc = Read-Host "Firecrawl API key (optional - press Enter to skip; stored only in the local claude-config, never in git)"
if ($fc.Trim()) {
  $mcp["firecrawl"] = [ordered]@{ type = "stdio"; command = "cmd"; args = @("/c","npx","-y","firecrawl-mcp"); env = @{ FIRECRAWL_API_KEY = $fc.Trim() } }
}
$claudeJson = "$cfg\.claude.json"
$obj = if (Test-Path $claudeJson) { Get-Content $claudeJson -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
$obj | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]$mcp) -Force
$obj | ConvertTo-Json -Depth 20 | Set-Content $claudeJson -Encoding utf8

Step "Installing the 'freellmapi' command"
$bin = Join-Path $HOME ".local\bin"
New-Item -ItemType Directory -Force $bin | Out-Null
"@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"$root\freellmapi.ps1`" %*" | Set-Content (Join-Path $bin "freellmapi.cmd") -Encoding ascii
if (-not (($env:Path -split ';') -contains $bin)) {
  Write-Host "NOTE: $bin is not on your PATH. Add it (Settings > System > About > Advanced system settings > Environment Variables), or run freellmapi.ps1 directly." -ForegroundColor Yellow
}

Write-Host "`nDone. Next steps:" -ForegroundColor Green
Write-Host "  1. Run:  freellmapi            (starts the gateway, then the free Claude Code session)"
Write-Host "  2. Open http://127.0.0.1:3001, create the local account, add provider keys (Keys page)"
Write-Host "  3. Copy the 'unified key' from the Keys page and paste it when the launcher asks"
Write-Host "  4. In the session run /mcp and sign in to Notion (one time)"
