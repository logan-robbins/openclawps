#!/usr/bin/env bash
# 03-nodejs-openclaw.sh -- install Node.js 24 and OpenClaw
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Purge system nodejs if pulled in as a dependency
apt-get remove --purge -y nodejs libnode-dev 2>/dev/null || true

# Install Node.js 24 from nodesource
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y nodejs

# Install OpenClaw
npm install -g openclaw@latest

# Node compile cache (openclaw doctor recommendation)
mkdir -p /var/tmp/openclaw-compile-cache
