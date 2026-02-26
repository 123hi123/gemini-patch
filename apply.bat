@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "TARGET_ATTEMPTS=10000"

echo [gemini-patch] 偵測 npm 全域路徑...
for /f "usebackq delims=" %%i in (`npm root -g 2^>nul`) do set "NPM_ROOT=%%i"

if not defined NPM_ROOT (
  echo [gemini-patch] ERROR: 無法取得 npm 全域路徑，請先安裝 Node.js / npm。
  exit /b 1
)

set "RETRY_JS=%NPM_ROOT%\@google\gemini-cli\node_modules\@google\gemini-cli-core\dist\src\utils\retry.js"
set "RETRY_DTS=%NPM_ROOT%\@google\gemini-cli\node_modules\@google\gemini-cli-core\dist\src\utils\retry.d.ts"

if not exist "%RETRY_JS%" (
  for /f "delims=" %%f in ('dir /b /s "%NPM_ROOT%\retry.js" 2^>nul ^| findstr /i /r "@google\\gemini-cli-core\\dist\\src\\utils\\retry.js$"') do (
    set "RETRY_JS=%%f"
    goto :found_js
  )
)
:found_js

if not exist "%RETRY_DTS%" (
  for /f "delims=" %%f in ('dir /b /s "%NPM_ROOT%\retry.d.ts" 2^>nul ^| findstr /i /r "@google\\gemini-cli-core\\dist\\src\\utils\\retry.d.ts$"') do (
    set "RETRY_DTS=%%f"
    goto :found_dts
  )
)
:found_dts

if not exist "%RETRY_JS%" (
  echo [gemini-patch] ERROR: 找不到 retry.js，請確認已安裝 @google/gemini-cli。
  exit /b 1
)

copy /y "%RETRY_JS%" "%RETRY_JS%.bak" >nul
powershell -NoProfile -Command "(Get-Content -Raw '%RETRY_JS%') -replace '(DEFAULT_MAX_ATTEMPTS\s*=\s*)\d+;','$1%TARGET_ATTEMPTS%;' | Set-Content -NoNewline '%RETRY_JS%'"

if exist "%RETRY_DTS%" (
  copy /y "%RETRY_DTS%" "%RETRY_DTS%.bak" >nul
  powershell -NoProfile -Command "(Get-Content -Raw '%RETRY_DTS%') -replace '(DEFAULT_MAX_ATTEMPTS\s*=\s*)\d+;','$1%TARGET_ATTEMPTS%;' | Set-Content -NoNewline '%RETRY_DTS%'"
)

echo [gemini-patch] npm root -g: %NPM_ROOT%
echo [gemini-patch] 已更新: %RETRY_JS%
if exist "%RETRY_DTS%" echo [gemini-patch] 已更新: %RETRY_DTS%

echo [gemini-patch] 驗證結果:
powershell -NoProfile -Command "Select-String -Path '%RETRY_JS%' -Pattern 'DEFAULT_MAX_ATTEMPTS' | ForEach-Object { $_.Line }"
if exist "%RETRY_DTS%" powershell -NoProfile -Command "Select-String -Path '%RETRY_DTS%' -Pattern 'DEFAULT_MAX_ATTEMPTS' | ForEach-Object { $_.Line }"

echo [gemini-patch] 完成，模型重試預設次數已設為 %TARGET_ATTEMPTS%。
exit /b 0
