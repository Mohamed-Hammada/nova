@echo off
rem =========================================================================
rem Nova - Web App Launcher
rem Starts Nova Web app on port 8686 (or a custom port if specified).
rem Usage:
rem   start_web.bat
rem   start_web.bat --web-port 3000
rem   start_web.bat -d edge
rem   start_web.bat -d web-server --web-port 5000
rem =========================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "TARGET_PORT=8686"

rem Check if custom --web-port was passed
set "PREV="
for %%A in (%*) do (
    if "!PREV!"=="--web-port" set "TARGET_PORT=%%A"
    set "PREV=%%A"
)

echo ===================================================
echo   Nova Web App Launcher
echo ===================================================
echo.
echo Starting Nova on: http://localhost:!TARGET_PORT!
echo.

rem If port is already in use by a previous instance, free it
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /C:":!TARGET_PORT! "') do (
    if not "%%P"=="0" (
        echo Port !TARGET_PORT! is in use by PID %%P. Freeing port...
        taskkill /F /PID %%P >nul 2>&1
    )
)

call scripts\run_web.bat %*

if errorlevel 1 (
    echo.
    echo Nova Web stopped with error code %ERRORLEVEL%.
    pause
)
endlocal
