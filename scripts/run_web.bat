@echo off
rem Regenerates the content bundle, then runs the app on http://localhost:8686,
rem in Microsoft Edge when it is installed (Edge has Arabic voices built in;
rem Chrome on Windows has none, so Arabic questions would stay silent), else
rem in Chrome. Progress persists in the browser's storage for that origin.
rem Extra arguments go to `flutter run` (e.g. -d chrome to force Chrome).
setlocal
call "%~dp0regenerate_content_bundle.bat" || exit /b 1
pushd "%~dp0..\app"
call flutter pub get || (popd & exit /b 1)
set "DEVICE=-d chrome"
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "DEVICE=-d edge"
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "DEVICE=-d edge"
echo %* | findstr /C:"-d " >nul && set "DEVICE="
set "PORT_FLAG=--web-port 8686"
echo %* | findstr /C:"--web-port" >nul && set "PORT_FLAG="
call flutter run %DEVICE% --no-web-resources-cdn %PORT_FLAG% %*
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
