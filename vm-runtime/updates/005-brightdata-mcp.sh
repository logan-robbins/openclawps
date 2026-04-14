#!/usr/bin/env bash
# 005-brightdata-mcp.sh -- add Bright Data MCP server to openclaw.json
CONFIG="/mnt/claw-data/openclaw/openclaw.json"
ENV_FILE="/mnt/claw-data/openclaw/.env"

[[ -f "$CONFIG" ]] || { echo "[update-005] No config file, skipping"; exit 0; }

# Read the API token from .env
API_TOKEN=$(grep -E '^BRIGHTDATA_API_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | xargs) || true

if [[ -z "$API_TOKEN" ]]; then
    echo "[update-005] No BRIGHTDATA_API_TOKEN in .env, skipping MCP setup"
    exit 0
fi

# Add mcpServers.brightdata to openclaw.json
tmp=$(mktemp)
jq --arg token "$API_TOKEN" '
  .mcpServers.brightdata = {
    "command": "npx",
    "args": ["@brightdata/mcp"],
    "env": {
      "API_TOKEN": $token
    }
  }
' "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
chmod 600 "$CONFIG"
chown azureuser:azureuser "$CONFIG"

echo "[update-005] Added Bright Data MCP server to config"
