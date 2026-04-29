#!/usr/bin/env bash
set -euo pipefail

commit_message="${1:-Feature: Google Auth, Med Scheduling, SOS Voice & Auto-Build}"

git add .
git commit -m "$commit_message"
git push origin main
