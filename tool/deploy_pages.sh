#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="${CLOUDFLARE_PAGES_PROJECT_NAME:-ekutir-agent-app}"
BRANCH_NAME="${CLOUDFLARE_PAGES_BRANCH:-production}"

"$ROOT_DIR/tool/build_web_for_pages.sh"

cd "$ROOT_DIR"
npx wrangler pages deploy build/web \
  --project-name "$PROJECT_NAME" \
  --branch "$BRANCH_NAME"
