@echo off
rem Builds the web app, serves it locally, and runs the headless-Chrome smoke
rem test (tools\web_smoke\web_smoke.mjs): play a full session, then check the
rem progress survives a reload and a browser restart, with no request leaving
rem the app's own origin. Needs Node.js 22+ and Google Chrome (or CHROME_PATH).
setlocal
where node >nul 2>nul
if errorlevel 1 (
  echo error: Node.js 22+ is required for the web smoke test. 1>&2
  exit /b 1
)
call "%~dp0build_web.bat" || exit /b 1
if "%NOVA_SMOKE_PORT%"=="" set "NOVA_SMOKE_PORT=8787"
pushd "%~dp0.."
start "nova-web-smoke-server" /min "tools\validate\.venv\Scripts\python.exe" -m http.server %NOVA_SMOKE_PORT% --bind 127.0.0.1 --directory app\build\web
rem Give the server a moment to bind (ping works without a console, unlike timeout).
ping -n 3 127.0.0.1 >nul
node tools\web_smoke\web_smoke.mjs --port %NOVA_SMOKE_PORT%
set "RESULT=%ERRORLEVEL%"
taskkill /FI "WINDOWTITLE eq nova-web-smoke-server*" /T /F >nul 2>nul
popd
exit /b %RESULT%
