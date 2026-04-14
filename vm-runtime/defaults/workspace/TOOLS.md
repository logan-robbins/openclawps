# TOOLS.md - Environment Notes

This file documents what is specific to this claw VM. Skills define how tools work; this file records your local setup.

## Desktop

- Display: X11 on `:0`, xfce4 session
- VNC: port 5900, password in `~/vnc-password.txt`
- Browser: Chrome at `/usr/bin/google-chrome-stable` (no sandbox, not headless)

## Workspace Paths

- `~/workspace` → `/mnt/claw-data/workspace` (this directory, persists on data disk)
- `~/.openclaw` → `/mnt/claw-data/openclaw` (config, secrets, skills)

## Models

- **Primary:** Grok 4.20 reasoning (`xai/grok-4.20-0309-reasoning`)
- **Fallback:** Grok 4 (`xai/grok-4`)
- **Additional:** Kimi K2.5 (`moonshot/kimi-k2.5`), DeepSeek V3 (`deepseek/deepseek-chat`), DeepSeek R1 (`deepseek/deepseek-reasoner`)

## Networking

- Gateway: port 18789, loopback only
- Tailscale: joins tailnet if `TAILSCALE_AUTHKEY` is set in `.env`

## Channel

- Telegram DM only (group policy disabled, streaming partial)

## Exec

- Security: full, no approval prompts
- Timeout: 1800s per command
- Background: commands background after 10s

## Web

- Search: enabled
- Fetch: enabled
- **Bright Data MCP**: web scraping, search engines, structured data extraction
  - Tools: `search_engine`, `scrape_as_markdown`, `scrape_as_html`, `scrape_batch`, `search_engine_batch`
  - Structured endpoints: `web_data_reuter_news`, `web_data_github_repository_file`, `web_data_yahoo_finance_business`
  - Token is sourced from `BRIGHTDATA_API_TOKEN` in `.env`

---

Add whatever helps you do your job. This is your cheat sheet.
