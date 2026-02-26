#!/usr/bin/env bash
set -euo pipefail

TARGET_ATTEMPTS="10000"

log() {
  printf '[gemini-patch] %s\n' "$*"
}

fail() {
  printf '[gemini-patch] ERROR: %s\n' "$*" >&2
  exit 1
}

if ! command -v npm >/dev/null 2>&1; then
  fail "找不到 npm，請先安裝 Node.js / npm。"
fi

NPM_ROOT="$(npm root -g 2>/dev/null || true)"
[ -n "$NPM_ROOT" ] || fail "無法取得 npm 全域路徑（npm root -g）。"

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

[ -f "$RETRY_JS" ] || fail "找不到 retry.js，請確認已安裝 @google/gemini-cli。"

STAMP="$(date +%Y%m%d%H%M%S)"
cp "$RETRY_JS" "$RETRY_JS.bak.$STAMP"

# 將 DEFAULT_MAX_ATTEMPTS 改為指定值
sed -E -i "s/(DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*)[0-9]+;/\\1${TARGET_ATTEMPTS};/" "$RETRY_JS"

if [ -f "$RETRY_DTS" ]; then
  cp "$RETRY_DTS" "$RETRY_DTS.bak.$STAMP"
  sed -E -i "s/(DEFAULT_MAX_ATTEMPTS[[:space:]]*=[[:space:]]*)[0-9]+;/\\1${TARGET_ATTEMPTS};/" "$RETRY_DTS"
fi

log "npm root -g: $NPM_ROOT"
log "已更新: $RETRY_JS"
[ -f "$RETRY_DTS" ] && log "已更新: $RETRY_DTS"

log "驗證結果:"
rg -n "DEFAULT_MAX_ATTEMPTS" "$RETRY_JS" || true
[ -f "$RETRY_DTS" ] && rg -n "DEFAULT_MAX_ATTEMPTS" "$RETRY_DTS" || true

log "完成，模型重試預設次數已設為 $TARGET_ATTEMPTS。"
