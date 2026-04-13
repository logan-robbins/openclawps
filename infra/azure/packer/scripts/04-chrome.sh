#!/usr/bin/env bash
# 04-chrome.sh -- install Google Chrome from .deb
# Snap Chromium breaks OpenClaw's CDP integration due to AppArmor confinement.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
apt-get install -y /tmp/chrome.deb
rm /tmp/chrome.deb
