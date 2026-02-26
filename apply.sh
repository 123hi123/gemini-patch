#!/usr/bin/env bash
set -euo pipefail

TARGET_ATTEMPTS="10000"
TARGET_PATTERN='DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*[0-9]+;'
TARGET_LINE="DEFAULT_MAX_ATTEMPTS = ${TARGET_ATTEMPTS};"

log() {
  printf '[gemini-patch] %s\n' "$*"
}

fail() {
  printf '[gemini-patch] ERROR: %s\n' "$*" >&2
  exit 1
}

if ! command -v npm >/dev/null 2>&1; then
  fail "Cannot find npm. Install Node.js and npm first."
fi

NPM_ROOT="$(npm root -g 2>/dev/null || true)"
[ -n "$NPM_ROOT" ] || fail "Cannot detect global npm root (npm root -g)."

RETRY_JS="$NPM_ROOT/@google/gemini-cli/node_modules/@google/gemini-cli-core/dist/src/utils/retry.js"
RETRY_DTS="$NPM_ROOT/@google/gemini-cli/node_modules/@google/gemini-cli-core/dist/src/utils/retry.d.ts"

if [ ! -f "$RETRY_JS" ]; then
  FOUND_JS="$(find "$NPM_ROOT" -type f -path "*/@google/gemini-cli-core/dist/src/utils/retry.js" 2>/dev/null | head -n 1 || true)"
  [ -n "$FOUND_JS" ] && RETRY_JS="$FOUND_JS"
fi

if [ ! -f "$RETRY_DTS" ]; then
  FOUND_DTS="$(find "$NPM_ROOT" -type f -path "*/@google/gemini-cli-core/dist/src/utils/retry.d.ts" 2>/dev/null | head -n 1 || true)"
  [ -n "$FOUND_DTS" ] && RETRY_DTS="$FOUND_DTS"
fi

[ -f "$RETRY_JS" ] || fail "retry.js not found. Please install @google/gemini-cli first."

STAMP="$(date +%Y%m%d%H%M%S)"

patch_file() {
  local file="$1"
  local tmp

  cp "$file" "$file.bak.$STAMP"
  tmp="$(mktemp)"

  # Replace only the numeric assignment to avoid group-reference ambiguity.
  sed -E "s/${TARGET_PATTERN}/${TARGET_LINE}/g" "$file" >"$tmp" || {
    rm -f "$tmp"
    fail "Failed to patch: $file"
  }

  mv "$tmp" "$file"

  if ! grep -Eq "DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*${TARGET_ATTEMPTS};" "$file"; then
    fail "Verification failed for: $file"
  fi
}

patch_file "$RETRY_JS"
if [ -f "$RETRY_DTS" ]; then
  patch_file "$RETRY_DTS"
else
  log "Info: retry.d.ts not found. Skipped."
fi

log "npm root -g: $NPM_ROOT"
log "Updated: $RETRY_JS"
[ -f "$RETRY_DTS" ] && log "Updated: $RETRY_DTS"

log "Verification:"
if command -v rg >/dev/null 2>&1; then
  rg -n "DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*${TARGET_ATTEMPTS};" "$RETRY_JS" || true
  [ -f "$RETRY_DTS" ] && rg -n "DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*${TARGET_ATTEMPTS};" "$RETRY_DTS" || true
else
  grep -nE "DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*${TARGET_ATTEMPTS};" "$RETRY_JS" || true
  [ -f "$RETRY_DTS" ] && grep -nE "DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*${TARGET_ATTEMPTS};" "$RETRY_DTS" || true
fi

log "Done. DEFAULT_MAX_ATTEMPTS is set to $TARGET_ATTEMPTS."
