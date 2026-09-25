@echo off
rem Regenerates the content bundle, then builds the release web app into
rem app\build\web. --no-web-resources-cdn serves CanvasKit from the app itself,
rem so the site fetches nothing from Google's CDN or any backend.
setlocal
call "%~dp0regenerate_content_bundle.bat" || exit /b 1
for %%F in (sqlite3.wasm drift_worker.js) do (
  if not exist "%~dp0..\app\web\%%F" (
    echo error: app\web\%%F is missing; run scripts/update_web_sqlite_assets.sh 1>&2
    exit /b 1
  )
)
pushd "%~dp0..\app"
call flutter pub get || (popd & exit /b 1)
call flutter build web --release --no-web-resources-cdn %*
set "RESULT=%ERRORLEVEL%"
popd
if not "%RESULT%"=="0" (
  echo error: flutter build web failed. 1>&2
  exit /b %RESULT%
)
echo Built: app\build\web ^(serve it with any static file server^)
endlocal
