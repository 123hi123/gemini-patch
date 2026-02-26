@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "TARGET_ATTEMPTS=10000"
set "EXIT_CODE=0"

echo [gemini-patch] Detecting global npm root...
for /f "usebackq delims=" %%i in (`npm root -g 2^>nul`) do set "NPM_ROOT=%%i"

if not defined NPM_ROOT (
  echo [gemini-patch] ERROR: Cannot detect global npm root. Install Node.js and npm first.
  set "EXIT_CODE=1"
  goto :finish
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
  echo [gemini-patch] ERROR: retry.js not found. Please install @google/gemini-cli first.
  set "EXIT_CODE=1"
  goto :finish
)

copy /y "%RETRY_JS%" "%RETRY_JS%.bak" >nul
powershell -NoProfile -Command "$p='%RETRY_JS%'; $c=[System.IO.File]::ReadAllText($p); if ($c -notmatch 'DEFAULT_MAX_ATTEMPTS\s*=\s*%TARGET_ATTEMPTS%;') { $c=[regex]::Replace($c,'(DEFAULT_MAX_ATTEMPTS\s*=\s*)\d+;','${1}%TARGET_ATTEMPTS%;') }; $enc=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($p,$c,$enc)"
if errorlevel 1 (
  echo [gemini-patch] ERROR: Failed to update %RETRY_JS%.
  set "EXIT_CODE=1"
  goto :finish
)

if exist "%RETRY_DTS%" (
  copy /y "%RETRY_DTS%" "%RETRY_DTS%.bak" >nul
  powershell -NoProfile -Command "$p='%RETRY_DTS%'; $c=[System.IO.File]::ReadAllText($p); if ($c -notmatch 'DEFAULT_MAX_ATTEMPTS\s*=\s*%TARGET_ATTEMPTS%;') { $c=[regex]::Replace($c,'(DEFAULT_MAX_ATTEMPTS\s*=\s*)\d+;','${1}%TARGET_ATTEMPTS%;') }; $enc=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($p,$c,$enc)"
  if errorlevel 1 (
    echo [gemini-patch] ERROR: Failed to update %RETRY_DTS%.
    set "EXIT_CODE=1"
    goto :finish
  )
) else (
  echo [gemini-patch] Info: retry.d.ts not found. Skipped.
)

echo [gemini-patch] npm root -g: %NPM_ROOT%
echo [gemini-patch] Updated: %RETRY_JS%
if exist "%RETRY_DTS%" echo [gemini-patch] Updated: %RETRY_DTS%

echo [gemini-patch] Verification:
powershell -NoProfile -Command "$m=Select-String -Path '%RETRY_JS%' -Pattern 'DEFAULT_MAX_ATTEMPTS\s*=\s*%TARGET_ATTEMPTS%;'; if ($m) { $m | ForEach-Object { $_.Line } } else { exit 1 }"
if errorlevel 1 (
  echo [gemini-patch] ERROR: Verification failed for %RETRY_JS%.
  set "EXIT_CODE=1"
  goto :finish
)

if exist "%RETRY_DTS%" (
  powershell -NoProfile -Command "$m=Select-String -Path '%RETRY_DTS%' -Pattern 'DEFAULT_MAX_ATTEMPTS\s*=\s*%TARGET_ATTEMPTS%;'; if ($m) { $m | ForEach-Object { $_.Line } } else { exit 1 }"
  if errorlevel 1 (
    echo [gemini-patch] ERROR: Verification failed for %RETRY_DTS%.
    set "EXIT_CODE=1"
    goto :finish
  )
)

echo [gemini-patch] Done. DEFAULT_MAX_ATTEMPTS is set to %TARGET_ATTEMPTS%.

:finish
echo.
if "%EXIT_CODE%"=="0" (
  echo [gemini-patch] Result: SUCCESS
) else (
  echo [gemini-patch] Result: FAILED ^(exit code: %EXIT_CODE%^)
)
echo [gemini-patch] Press any key to close this window...
pause >nul
exit /b %EXIT_CODE%
