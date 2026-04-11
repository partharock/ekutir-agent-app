#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/parthaghosh/development/flutter/bin/flutter}"
MAPPLS_WEB_STATIC_KEY="${MAPPLS_WEB_STATIC_KEY:-}"
MAPPLS_WEB_SDK_VERSION="${MAPPLS_WEB_SDK_VERSION:-3.0}"

cd "$ROOT_DIR"

"$FLUTTER_BIN" build web --no-wasm-dry-run "$@"

cat > "$ROOT_DIR/build/web/mappls-config.js" <<EOF
window.__MAPPLS_WEB_STATIC_KEY__ = "${MAPPLS_WEB_STATIC_KEY}";
window.__MAPPLS_WEB_SDK_VERSION__ = "${MAPPLS_WEB_SDK_VERSION}";
EOF

echo "Prepared build/web with Mappls web config."
if [[ -z "$MAPPLS_WEB_STATIC_KEY" ]]; then
  echo "MAPPLS_WEB_STATIC_KEY is empty. Map features will stay disabled in the web build."
fi
