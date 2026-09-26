@echo off
rem Regenerates the content bundle, then runs the app in Chrome on
rem http://localhost:8686. Progress persists in the browser's storage for that
rem origin. Extra arguments go to `flutter run` (e.g. -d edge).
setlocal
call "%~dp0regenerate_content_bundle.bat" || exit /b 1
pushd "%~dp0..\app"
call flutter pub get || (popd & exit /b 1)
set "DEVICE=-d chrome"
echo %* | findstr /C:"-d " >nul && set "DEVICE="
set "PORT_FLAG=--web-port 8686"
echo %* | findstr /C:"--web-port" >nul && set "PORT_FLAG="
call flutter run %DEVICE% --no-web-resources-cdn %PORT_FLAG% %*
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
