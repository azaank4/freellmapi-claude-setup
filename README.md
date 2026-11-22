# FreeLLMAPI + Claude Code (isolated setup)

Runs the full Claude Code program (tools, MCP servers, subagents) against a local
[FreeLLMAPI](https://github.com/tashfeenahmed/freellmapi) gateway, so the model behind it is a free
open model, not Anthropic's. It is **isolated**: it uses its own config folder and never touches your
normal `~/.claude` login, settings or other sessions.

> This repo contains **no secrets**. Provider keys, the gateway's unified key and the encryption key
> are created on each machine and are git-ignored.

## Requirements (Windows)
- Git, Node.js 20-24, and Claude Code installed
- PowerShell 5.1+ (the saved-key feature uses Windows DPAPI, so this setup is Windows-only)

## Install on a new machine
```powershell
git clone <this-repo-url> D:\freellmapi-claude-setup
cd D:\freellmapi-claude-setup
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```
`setup.ps1` clones FreeLLMAPI, installs and builds it, creates the isolated Claude Code config from
`templates/`, and installs a `freellmapi` command.

Then:
1. Run `freellmapi` (starts the gateway in its own window, then the Claude Code session).
2. Open <http://127.0.0.1:3001>, create the local account and add free provider keys
   (Google AI Studio, Groq, Cerebras, OpenRouter, ...). Copy the **unified key** from the Keys page.
3. Paste the unified key at the launcher prompt. It can save it encrypted for your Windows user only.
4. In the session, run `/mcp` and sign in to Notion once.

## Daily use
| Command | What it does |
|---|---|
| `freellmapi` | Starts the gateway if needed, then the free Claude Code session |
| `node who-answered.cjs` (or `who-answered.cmd`) | Shows which real model answered each request |

Plain `claude` still means your normal Anthropic setup. Use `freellmapi` for the free one.

## Verify it is NOT using Anthropic
Claude Code's banner and `/model` show Anthropic-style names (Sonnet 4.5, ...). Those are just labels the
gateway maps to free models, and a model's own answer to "who are you" is unreliable. The proof is the
gateway's request log: run `who-answered.cjs` after chatting. It lists the real provider/model for each
`claude-cli` request.

## Permissions
`templates/claude-settings.json` pre-approves all tools of the `playwright`, `firecrawl` and `notion` MCP
servers, file reads, edits in the working folder, and a short list of read-only commands. Everything else
still asks. Free models are weaker and process untrusted web/Notion content, so a blanket
"approve everything" mode is intentionally not the default.

## Moving your existing data
Not included (it contains secrets). To keep your provider keys and history, copy
`freellmapi\server\data\` (the database **and** `.encryption-key`, together) from the old machine to the
same place on the new one over a private channel. Otherwise the new gateway generates a fresh unified key
and you re-add provider keys in the dashboard.

## Notes
- The gateway listens on `127.0.0.1:3001` only (not reachable from other devices).
- FreeLLMAPI's free tiers have no frontier models and variable latency; prompts go to third-party free
  providers, so don't use this for confidential or client data.
- Upstream project and licence: <https://github.com/tashfeenahmed/freellmapi> (MIT).
